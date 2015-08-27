--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate predefined values for filter input bit streams.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_pattern_generator is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Load selected pattern
    sel_i  : in std_ulogic_vector(2 downto 0);
    load_i : in std_ulogic;

    -- Generated bit stream
    gen_o : out std_ulogic);
end entity ads1281_pattern_generator;

architecture rtl of ads1281_pattern_generator is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  type lut_t is array (0 to 2**sel_i'length - 1) of std_ulogic_vector(7 downto 0);

  -- Predefined patterns
  constant lut : lut_t := (
    "00000000",     --   0.0 %
    "00010001",     --  25.0 %
    "00100101",     --  37.5 %
    "01010101",     --  50.0 %
    "01011011",     --  62.5 %
    "01110111",     --  75.0 %
    "01111111",     --  87.5 %
    "11111111");    -- 100.0 %

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal gen : std_ulogic_vector(7 downto 0);

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal strb : std_ulogic;

begin   -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  gen_o <= gen(gen'high);

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  lfsr_strobe_generator_inst : entity work.lfsr_strobe_generator
    generic map (
      period_g       => 40,
      preset_value_g => 0)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => en_i,
      pre_i       => '0',
      strobe_o    => strb);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      gen <= (others => '0');
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      elsif load_i = '1' then
        -- Select predefined pattern
        gen <= lut(to_integer(unsigned(sel_i)));
      elsif strb = '1' then
        gen <= gen(gen'high - 1 downto gen'low) & gen(gen'high);
      end if;
    end if;
  end process regs;

end architecture rtl;
