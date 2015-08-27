--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Send data to MAX5541 DAC.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lfsr_pkg.all;

entity max5541_interface is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    data_i    : in  std_ulogic_vector(15 downto 0);
    data_en_i : in  std_ulogic;
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;

    -- MAX5541 signals
    cs_o   : out std_ulogic;
    sclk_o : out std_ulogic;
    din_o  : out std_ulogic);
end entity max5541_interface;

architecture rtl of max5541_interface is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(data_i'length);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter maximum value
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, data_i'length - 1);

  -- FSM states
  type state_t is (IDLE, CLK_HIGH, CLK_LOW);

  -- FSM registers
  type reg_t is record
    state : state_t;
    lfsr  : std_ulogic_vector(len_c - 1 downto 0);
    count : std_ulogic;
    data  : std_ulogic_vector(15 downto 0);
    clk   : std_ulogic;
    done  : std_ulogic;
  end record reg_t;

  -- FSM initial state
  constant init_c : reg_t := (
    state => IDLE,
    lfsr  => seed_c,
    count => '0',
    data  => (others => '0'),
    clk   => '0',
    done  => '0');

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;
  signal busy     : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= busy;
  done_o <= reg.done;
  cs_o   <= not busy;
  sclk_o <= reg.clk;
  din_o  <= reg.data(reg.data'high);

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
  comb : process(reg, data_i, data_en_i) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    busy          <= '1';
    next_reg.done <= init_c.done;

    case reg.state is
      when IDLE =>
        busy <= '0';

        if data_en_i = '1' then
          next_reg.data <= data_i;
          next_reg.state <= CLK_HIGH;
        end if;

      when CLK_HIGH =>
        if reg.count = '1' then
          next_reg.clk <= '1';
          next_reg.count <= '0';
          next_reg.state <= CLK_LOW;
        else
          next_reg.count <= '1';
        end if;

      when CLK_LOW =>
        if reg.count = '1' then
          if reg.lfsr = max_c then
            next_reg      <= init_c;
            next_reg.done <= '1';
          else
            next_reg.clk <= '0';
            next_reg.count <= '0';
            next_reg.state <= CLK_HIGH;
            next_reg.data <= reg.data(reg.data'high - 1 downto reg.data'low) & '0';
            next_reg.lfsr <= lfsr_shift(reg.lfsr);
          end if;
        else
          next_reg.count <= '1';
        end if;
    end case;
  end process comb;

end architecture rtl;
