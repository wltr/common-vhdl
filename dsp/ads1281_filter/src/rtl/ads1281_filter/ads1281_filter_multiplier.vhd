--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Perform (right-)shift and add multiplication.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_pkg.all;

entity ads1281_filter_multiplier is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Decoded data
    data_i : in signed(6 downto 0);

    -- Coefficient
    coeff_i    : in unsigned(23 downto 0);
    coeff_en_i : in std_ulogic;

    -- Multiplier result
    res_o    : out signed(30 downto 0);
    res_en_o : out std_ulogic);
end entity ads1281_filter_multiplier;

architecture rtl of ads1281_filter_multiplier is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(coeff_i'length);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter value after 23 shifts
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, coeff_i'length - 1);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal lfsr : std_ulogic_vector(len_c - 1 downto 0);
  signal res  : unsigned(30 downto 0);
  signal data : signed(data_i'range);
  signal busy : std_ulogic;
  signal en   : std_ulogic;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal a     : std_ulogic_vector(6 downto 0);
  signal b     : std_ulogic_vector(6 downto 0);
  signal sum   : unsigned(7 downto 0);
  signal shift : unsigned(30 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  res_o    <= signed(res);
  res_en_o <= en;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- 1st adder input is data input when register's low bit is 1, otherwise 0
  a <= std_ulogic_vector(data) when res(res'low) = '1' else (others => '0');

  -- 2nd adder input is always the register's top section
  b <= std_ulogic_vector(res(res'high downto res'high - data'length + 1));

  -- Adder with sign extension
  sum <= unsigned(a(a'high) & a) + unsigned(b(b'high) & b);

  -- Shift register and replace top section with adder output
  shift <= sum & res(res'high - sum'length + 1 downto res'low + 1);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      lfsr <= seed_c;
      res  <= (others => '0');
      data <= (others => '0');
      busy <= '0';
      en   <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      en <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if coeff_en_i = '1' then
          -- Store data
          data <= data_i;
          -- Store multiplier in shift register
          res <= (res'high downto coeff_i'length => '0') & coeff_i;
          -- Start calculation
          busy <= '1';
          lfsr <= seed_c;
        end if;

        if lfsr = max_c then
          en   <= '1';
          busy <= '0';
        end if;

        if busy = '1' then
          -- Shift LFSR and result
          lfsr <= lfsr_shift(lfsr);
          res  <= shift;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
