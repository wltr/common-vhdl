--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Alternate between the outputs of the two interleaved filters.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_filter_output is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- 1st MAC result
    data1_i    : in signed(23 downto 0);
    data1_en_i : in std_ulogic;

    -- 2nd MAC result
    data2_i    : in signed(23 downto 0);
    data2_en_i : in std_ulogic;

    -- Filter output
    data_o    : out std_ulogic_vector(23 downto 0);
    data_en_o : out std_ulogic);
end entity ads1281_filter_output;

architecture rtl of ads1281_filter_output is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal data    : signed(23 downto 0);
  signal data_en : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= std_ulogic_vector(data);
  data_en_o <= data_en;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      data    <= to_signed(0, data'length);
      data_en <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        if data1_en_i = '1' then
          data <= data1_i;
        elsif data2_en_i = '1' then
          data <= data2_i;
        end if;

        data_en <= data1_en_i xor data2_en_i;
      end if;
    end if;
  end process regs;

end architecture rtl;
