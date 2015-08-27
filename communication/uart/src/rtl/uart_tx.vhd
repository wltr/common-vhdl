--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Send asynchronous serial data.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.lfsr_pkg.all;

entity uart_tx is
  generic (
    -- Data bit width
    data_width_g : positive := 8;

    -- Parity bit: 0 = None, 1 = Odd, 2 = Even
    parity_g : natural range 0 to 2 := 0;

    -- Number of stop bits
    stop_bits_g : positive range 1 to 2 := 1;

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

    -- Transmission line
    tx_o : out std_ulogic);
end entity uart_tx;

architecture rtl of uart_tx is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Transmission bit length
  constant tx_len_c : natural := 1 + data_width_g + stop_bits_g + natural(ceil(real(parity_g / 2)));

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(tx_len_c);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count : std_ulogic_vector(len_c - 1 downto 0);
  signal data  : std_ulogic_vector(tx_len_c - 1 downto 0);
  signal busy  : std_ulogic;
  signal done  : std_ulogic;
  signal tx    : std_ulogic;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal parity_init : std_ulogic;
  signal parity_bit  : std_ulogic;
  signal parity      : std_ulogic_vector(data_i'range);
  signal bit_strobe  : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= busy;
  done_o <= done;
  tx_o   <= tx;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Set parity bit's initial value
  parity_init <= '1' when parity_g = 1 else '0';

  -- Compute parity bit
  parity(0) <= data_i(0) xor parity_init;
  parity_gen : for i in 1 to parity'high generate
    parity(i) <= data_i(i) xor parity(i - 1);
  end generate parity_gen;
  parity_bit <= parity(parity'high);

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Generate bit strobe
  lfsr_strobe_gen_inst : entity work.lfsr_strobe_generator
    generic map (
      period_g       => num_ticks_g,
      preset_value_g => 0)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => busy,
      pre_i       => done,
      strobe_o    => bit_strobe);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Transmit
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count <= seed_c;
      data  <= (others => '1');
      busy  <= '0';
      done  <= '0';
      tx    <= '1';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      --Defaults
      done <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if busy = '0' and data_en_i = '1' then
          if parity_g = 0 then
            data(data_i'high + 1 downto 0) <= data_i & '0';
          else
            data(data_i'high + 2 downto 0) <= parity_bit & data_i & '0';
          end if;

          busy <= '1';
        elsif busy = '1' and bit_strobe = '1' then
          data <= '1' & data(data'high downto data'low + 1);
          tx   <= data(data'low);

          if count = lfsr_shift(seed_c, tx_len_c - 1) then
            reset;
            done <= '1';
          else
            count <= lfsr_shift(count);
          end if;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
