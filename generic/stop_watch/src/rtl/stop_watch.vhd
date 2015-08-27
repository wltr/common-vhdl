--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Count time in between strobes.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity stop_watch is
  generic (
    -- Counter bit width
    bit_width_g : positive := 8);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Sample and reset counter value
    sample_i : in std_ulogic;

    -- Count
    value_o : out std_ulogic_vector(bit_width_g - 1 downto 0));
end entity stop_watch;

architecture rtl of stop_watch is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count : unsigned(bit_width_g - 1 downto 0) := (others => '0');
  signal value : unsigned(bit_width_g - 1 downto 0) := (others => '0');

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  value_o <= std_ulogic_vector(value);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Count
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count <= to_unsigned(0, count'length);
      value <= to_unsigned(0, value'length);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      elsif sample_i = '1' then
        count <= to_unsigned(0, count'length);
        value <= count;
      elsif en_i = '1' then
        count <= count + 1;
      end if;
    end if;
  end process regs;

end architecture rtl;
