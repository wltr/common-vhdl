--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Filter glitches with an N-stage shift register.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity glitch_filter is
  generic (
    -- Initial value of input signal
    init_value_g : std_ulogic := '0';

    -- Number of delay stages
    num_delay_g : positive := 1);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Input signal
    sig_i : in  std_ulogic;

    -- Filtered output signal
    sig_o : out std_ulogic);
end entity glitch_filter;

architecture rtl of glitch_filter is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal dlyd_sig : std_ulogic_vector(num_delay_g - 1 downto 0) := (others => init_value_g);
  signal sig      : std_ulogic := init_value_g;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_sig : std_ulogic_vector(num_delay_g - 1 downto 0);
  signal state    : std_ulogic_vector(num_delay_g - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  sig_o <= sig;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Delay only for one clock cycle
  single_delay_gen : if num_delay_g = 1 generate
    next_sig(0) <= sig_i;
  end generate single_delay_gen;

  -- Delay for multiple clock cycles
  multiple_delays_gen : if num_delay_g > 1 generate
    next_sig <= dlyd_sig(dlyd_sig'high - 1 downto dlyd_sig'low) & sig_i;
  end generate multiple_delays_gen;

  -- Compute state
  state(0) <= dlyd_sig(0) xnor sig_i;
  state_gen : for i in 1 to num_delay_g - 1 generate
    state(i) <= dlyd_sig(i) xnor state(i - 1);
  end generate state_gen;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Filter signal
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      dlyd_sig <= (others => init_value_g);
      sig      <= init_value_g;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        if en_i = '1' then
          dlyd_sig <= next_sig;
        end if;

        if state(state'high) = '1' then
          sig <= dlyd_sig(dlyd_sig'high);
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
