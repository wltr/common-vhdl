--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate a strobe when a counter reaches a certain value.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lfsr_pkg.all;

entity lfsr_strobe_generator is
  generic (
    -- Number of clock cycles in between strobes
    period_g : positive := 8;

    -- Counter preset value
    preset_value_g : natural := 4);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Preset
    pre_i : in std_ulogic;

    -- Strobe signal
    strobe_o : out std_ulogic);
end entity lfsr_strobe_generator;

architecture rtl of lfsr_strobe_generator is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(period_g);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter strobe value
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, period_g - 1);

  -- LFSR counter preset value
  constant preset_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, preset_value_g);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count  : std_ulogic_vector(len_c - 1 downto 0) := seed_c;
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
      count  <= seed_c;
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
        count <= preset_c;
      elsif en_i = '1' then
        if count = max_c then
          -- Reset counter
          count <= seed_c;
          -- Generate strobe signal
          strobe <= '1';
        else
          -- Increment counter
          count <= lfsr_shift(count);
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
