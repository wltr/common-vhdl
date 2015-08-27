--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Decode the ADS1281 bit streams M0 and M1 according to the equation from
-- the data sheet.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_filter_decoder is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Buffered ADC bit streams
    adc_m0_i : in std_ulogic_vector(2 downto 0);
    adc_m1_i : in std_ulogic_vector(2 downto 0);

    -- Decoded data
    data_o : out signed(6 downto 0));
end entity ads1281_filter_decoder;

architecture rtl of ads1281_filter_decoder is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  constant addr_len_c : natural := adc_m0_i'length + adc_m1_i'length;

  type lut_t is array (0 to 2**addr_len_c - 1) of integer range -49 to 49;

  -- Look-up table with pre-calculated values using the following equation:
  -- Y[n] = 3*M0[n-2] - 6*M0[n-3] + 4*M0[n-4] + 9*(M1[n] - 2*M1[n-1] + M1[n-2])
  constant lut : lut_t := (
    1, -17, 37, 19, -17, -35, 19, 1, -7, -25, 29, 11, -25,
    -43, 11, -7, 13, -5, 49, 31, -5, -23, 31, 13, 5, -13,
    41, 23, -13, -31, 23, 5, -5, -23, 31, 13, -23, -41, 13,
    -5, -13, -31, 23, 5, -31, -49, 5, -13, 7, -11, 43, 25,
    -11, -29, 25, 7, -1, -19, 35, 17, -19, -37, 17, -1);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal data : signed(6 downto 0);

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal addr : unsigned(addr_len_c - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o <= data;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Combine samples and previous sample values to an address
  addr <= adc_m0_i(2) & adc_m0_i(1) & adc_m0_i(0) & adc_m1_i(2) & adc_m1_i(1) & adc_m1_i(0);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      data <= to_signed(0, data'length);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Map combined address to pre-calculated output value
        data <= to_signed(lut(to_integer(addr)), data'length);
      end if;
    end if;
  end process regs;

end architecture rtl;
