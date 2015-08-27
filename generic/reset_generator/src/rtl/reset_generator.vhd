--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Activate reset asynchronously and deactivate it synchronously.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity reset_generator is
  generic (
    -- Number of delay stages
    num_delay_g : positive := 4;

    -- Reset active state
    active_g : std_ulogic := '0');
  port (
    -- Clock
    clk_i : in std_ulogic;

    -- Asynchronous reset input
    rst_asy_i : in std_ulogic;

    -- Reset output
    rst_o : out std_ulogic);
end entity reset_generator;

architecture rtl of reset_generator is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal rst : std_ulogic_vector(num_delay_g - 1 downto 0) := (others => active_g);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  rst_o <= rst(rst'high);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_i) is
  begin -- process regs
    if rst_asy_i = active_g then
      rst <= (others => active_g);
    elsif rising_edge(clk_i) then
      rst <= rst(rst'high - 1 downto rst'low) & (not active_g);
    end if;
  end process regs;

end architecture rtl;
