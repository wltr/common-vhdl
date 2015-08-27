--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate reset according to Microsemi application note AC380.
-- The reset is activated asynchronously and deactivated synchronously.
-- The asynchronous reset input is supposed to be connected to a weak
-- external pull-up resistor.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- Component library
-- TODO: Has to be adjusted to the used device
library proasic3;
use proasic3.all;

entity microsemi_reset_generator is
  generic (
    -- Number of delay stages
    num_delay_g : positive := 4;

    -- Reset active state
    active_g : std_ulogic := '0');
  port (
    -- Clock
    clk_i : in std_ulogic;

    -- Asynchronous reset input
    rst_asy_io : inout std_logic;

    -- Reset output
    rst_o : out std_ulogic);
end entity microsemi_reset_generator;

architecture rtl of microsemi_reset_generator is

  ------------------------------------------------------------------------------
  -- Components
  ------------------------------------------------------------------------------

  -- Bi-directional buffer
  component BIBUF_LVCMOS33
    port (
      PAD : inout std_logic;
      D   : in  std_logic;
      E   : in  std_logic;
      Y   : out   std_logic);
  end component;

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal rst : std_ulogic_vector(num_delay_g - 1 downto 0);

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal rst_asy : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  rst_o <= rst(rst'high);

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Bi-directional buffer with enabled output forced to '0'
  BIBUF_LVCMOS33_inst : BIBUF_LVCMOS33
    port map (
      PAD => rst_asy_io,
      D   => '0',
      E   => '1',
      Y   => rst_asy);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy) is
  begin -- process regs
    if rst_asy = '1' then
      rst <= (others => active_g);
    elsif rising_edge(clk_i) then
      rst <= rst(rst'high - 1 downto rst'low) & (not active_g);
    end if;
  end process regs;

end architecture rtl;
