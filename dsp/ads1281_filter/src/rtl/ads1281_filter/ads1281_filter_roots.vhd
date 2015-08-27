--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Assign root values to according index numbers.
-- Root values were calculated using the fir4.awk script.
-- z0 = 1000, z1 = 736, z2 = 128, z3 = 129
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_pkg.all;

entity ads1281_filter_roots is
  generic (
    -- LFSR seed value from coefficient generator
    seed_g : std_ulogic_vector(10 downto 0));
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- LFSR index value
    lfsr_i : in std_ulogic_vector(10 downto 0);

    -- Root value
    root_o : out signed(1 downto 0));
end entity ads1281_filter_roots;

architecture rtl of ads1281_filter_roots is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal root : signed(1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  root_o <= root;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      root <= to_signed(0, root'length);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Map LFSR input to the according root value
        case lfsr_i is
          when lfsr_shift(seed_g, 128) |
             lfsr_shift(seed_g, 129) |
             lfsr_shift(seed_g, 736) |
             lfsr_shift(seed_g, 993) |
             lfsr_shift(seed_g, 1000)|
             lfsr_shift(seed_g, 1257)|
             lfsr_shift(seed_g, 1864)|
             lfsr_shift(seed_g, 1865) =>

            root <= to_signed(-1, root'length);

          when lfsr_shift(seed_g, 0)   |
             lfsr_shift(seed_g, 257) |
             lfsr_shift(seed_g, 864) |
             lfsr_shift(seed_g, 865) |
             lfsr_shift(seed_g, 1128)|
             lfsr_shift(seed_g, 1129)|
             lfsr_shift(seed_g, 1736)|
             lfsr_shift(seed_g, 1993) =>

            root <= to_signed(1, root'length);

          when others =>
            root <= to_signed(0, root'length);
        end case ;
      end if;
    end if;
  end process regs;

end architecture rtl;
