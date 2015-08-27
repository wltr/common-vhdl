--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate a strobe when a counter reaches a certain value.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity strobe_generator is
  generic (
    -- Initial value of counter
    init_value_g : natural := 0;

    -- Counter bit width
    bit_width_g : positive := 8);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Number of clock cycles in between strobes
    period_i : in std_ulogic_vector(bit_width_g - 1 downto 0);

    -- Preset inputs
    pre_i       : in std_ulogic;
    pre_value_i : in std_ulogic_vector(bit_width_g - 1 downto 0);

    -- Strobe signal
    strobe_o : out std_ulogic);
end entity strobe_generator;

architecture rtl of strobe_generator is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count  : unsigned(bit_width_g - 1 downto 0) := (others => '0');
  signal strobe : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  strobe_o <= strobe;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Generate strobe
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count  <= to_unsigned(init_value_g, count'length);
      strobe <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      strobe <= '0';

      if rst_syn_i = '1' then
        reset;
      elsif pre_i = '1' then
        -- Preset counter to specified value
        count <= unsigned(pre_value_i);
      elsif en_i = '1' then
        if count < unsigned(period_i) - 1 then
          -- Increment counter
          count <= count + 1;
        else
          -- Reset counter
          count <= to_unsigned(init_value_g, count'length);
          -- Generate strobe signal
          strobe <= '1';
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
