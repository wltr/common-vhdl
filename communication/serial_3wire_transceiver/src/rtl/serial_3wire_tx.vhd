--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Send synchronous serial data over 3 wires.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lfsr_pkg.all;

entity serial_3wire_tx is
  generic (
    -- Data bit width
    data_width_g : positive := 32;

    -- Number of clock cycles per bit
    num_ticks_g  : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    data_i    : in  std_ulogic_vector(data_width_g - 1 downto 0);
    data_en_i : in  std_ulogic;
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;

    -- Transmission lines
    tx_frame_o  : out std_ulogic;
    tx_bit_en_o : out std_ulogic;
    tx_o        : out std_ulogic);
end entity serial_3wire_tx;

architecture rtl of serial_3wire_tx is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Using odd parity detects empty frames as errors
  constant parity_init_c : std_ulogic := '1';

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(data_width_g + 1);

  -- LFSR counter initial values
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- FSM states
  type state_t is (IDLE, EN_HIGH, EN_LOW);

  -- FSM registers
  type reg_t is record
    state  : state_t;
    count  : std_ulogic_vector(len_c - 1 downto 0);
    data   : std_ulogic_vector(data_width_g - 1 downto 0);
    parity : std_ulogic;
    frame  : std_ulogic;
    bit_en : std_ulogic;
    done   : std_ulogic;
  end record reg_t;

  -- FSM initial state
  constant init_c : reg_t := (
    state  => IDLE,
    count  => seed_c,
    data   => (others => '0'),
    parity => parity_init_c,
    frame  => '0',
    bit_en => '0',
    done   => '0');

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t := init_c;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_reg   : reg_t;
  signal strobe_en  : std_ulogic;
  signal bit_strobe : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o      <= reg.frame;
  done_o      <= reg.done;
  tx_frame_o  <= reg.frame;
  tx_bit_en_o <= reg.bit_en;
  tx_o        <= reg.data(reg.data'low);

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  lfsr_strobe_gen_inst : entity work.lfsr_strobe_generator
    generic map (
      period_g       => num_ticks_g / 2,
      preset_value_g => 0)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => strobe_en,
      pre_i       => '0',
      strobe_o    => bit_strobe);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- FSM registering
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      reg <= init_c;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        reg <= next_reg;
      end if;
    end if;
  end process regs;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  -- FSM combinatorics
  comb : process (reg, data_i, data_en_i, bit_strobe) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    strobe_en     <= '1';
    next_reg.done <= init_c.done;

    case reg.state is
      when IDLE =>
        strobe_en <= '0';
        -- Wait for data
        if data_en_i = '1' then
          -- Start transmission
          next_reg.data  <= data_i;
          next_reg.frame <= '1';
          next_reg.state <= EN_LOW;
        end if;

      when EN_LOW =>
        -- Bit enable is low
        if bit_strobe = '1' then
          -- Set bit enable high after a specific number of clock cycles
          next_reg.bit_en <= '1';
          next_reg.state  <= EN_HIGH;
        end if;

      when EN_HIGH =>
        -- Bit enable is high
        if bit_strobe = '1' then
          if reg.count = lfsr_shift(seed_c, data_width_g) then
            -- Reset if all bits were sent
            next_reg      <= init_c;
            next_reg.done <= '1';
          else
            if reg.count = lfsr_shift(seed_c, data_width_g - 1) then
              -- Attach parity bit at the end of every transmission
              next_reg.data(next_reg.data'low) <= reg.parity xor reg.data(reg.data'low);
            else
              -- Calculate parity bit
              next_reg.parity <= reg.parity xor reg.data(reg.data'low);
              -- Transmit next data bit
              next_reg.data   <= '0' & reg.data(reg.data'high downto reg.data'low + 1);
            end if;
            next_reg.count <= lfsr_shift(reg.count);

            -- Set bit enable low after a specific number of clock cycles
            next_reg.bit_en <= '0';
            next_reg.state  <= EN_LOW;
          end if;
        end if;
    end case;
  end process comb;

end architecture rtl;
