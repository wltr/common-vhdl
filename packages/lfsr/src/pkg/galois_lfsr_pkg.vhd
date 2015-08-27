-------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2015 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Galois Linear Feedback Shift Register (LFSR) package.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

package lfsr_pkg is

  -- Maximum LFSR length supported by package
  constant lfsr_max_length_c : natural range 2 to natural'high := 32;

  -- LFSR data type to be used with package functions
  type lfsr_t is array (natural range <>) of std_ulogic;

  -- Get LFSR bit length for a given period, period = 2^n - 1
  function lfsr_length(period : positive)
  return natural;

  -- Get LFSR maximum period polynomial for a given bit length
  function lfsr_polynomial(length : natural range 2 to lfsr_max_length_c)
  return std_ulogic_vector;

  -- Get LFSR seed value for a given bit length
  function lfsr_seed(length : natural range 2 to lfsr_max_length_c)
  return lfsr_t;

  -- Compute the LFSR value after a given number of shifts using the maximum period polynomial
  function lfsr_shift(lfsr : lfsr_t; num_shifts : natural := 1)
  return lfsr_t;

  -- Compute the LFSR value with the provided polynomial after the given number of shifts
  function lfsr_shift(lfsr : lfsr_t; polynomial : std_ulogic_vector;
    num_shifts : natural := 1)
  return lfsr_t;

  -- Compute the LFSR value after a given number of shifts using the "+" operator and maximum period polynomial
  function "+"(lfsr : lfsr_t; num_shifts : natural)
  return lfsr_t;

end package lfsr_pkg;

package body lfsr_pkg is

  function lfsr_length(period : positive)
  return natural is
  begin
    if period < 3 then
      return 2;
    else
      return natural(ceil(log2(real(period + 1))));
    end if;
  end function lfsr_length;

  function lfsr_polynomial(length : natural range 2 to lfsr_max_length_c)
  return std_ulogic_vector is
    variable polynomial : std_ulogic_vector(length - 1 downto 0);
  begin
    case length is
      when 2  => polynomial := "11";                               -- x^2 + x + 1
      when 3  => polynomial := "110";                              -- x^3 + x^2 + 1
      when 4  => polynomial := "1100";                             -- x^4 + x^3 + 1
      when 5  => polynomial := "10100";                            -- x^5 + x^3 + 1
      when 6  => polynomial := "110000";                           -- x^6 + x^5 + 1
      when 7  => polynomial := "1100000";                          -- x^7 + x^6 + 1
      when 8  => polynomial := "10111000";                         -- x^8 + x^6 + x^5 + x^4 + 1
      when 9  => polynomial := "100010000";                        -- x^9 + x^5 + 1
      when 10 => polynomial := "1001000000";                       -- x^10 + x^7 + 1
      when 11 => polynomial := "10100000000";                      -- x^11 + x^9 + 1
      when 12 => polynomial := "111000001000";                     -- x^12 + x^11 + x^10 + x^4 + 1
      when 13 => polynomial := "1110010000000";                    -- x^13 + x^12 + x^11 + x^8 + 1
      when 14 => polynomial := "11100000000010";                   -- x^14 + x^13 + x^12 + x^2 + 1
      when 15 => polynomial := "110000000000000";                  -- x^15 + x^14 + 1
      when 16 => polynomial := "1011010000000000";                 -- x^16 + x^14 + x^13 + x^11 + 1
      when 17 => polynomial := "10010000000000000";                -- x^17 + x^14 + 1
      when 18 => polynomial := "100000010000000000";               -- x^18 + x^11 + 1
      when 19 => polynomial := "1110010000000000000";              -- x^19 + x^18 + x^17 + x^14 + 1
      when 20 => polynomial := "10010000000000000000";             -- x^20 + x^17 + 1
      when 21 => polynomial := "101000000000000000000";            -- x^21 + x^19 + 1
      when 22 => polynomial := "1100000000000000000000";           -- x^22 + x^21 + 1
      when 23 => polynomial := "10000100000000000000000";          -- x^23 + x^18 + 1
      when 24 => polynomial := "110110000000000000000000";         -- x^24 + x^23 + x^21 + x^20 + 1
      when 25 => polynomial := "1001000000000000000000000";        -- x^25 + x^22 + 1
      when 26 => polynomial := "11100010000000000000000000";       -- x^26 + x^25 + x^24 + x^20 + 1
      when 27 => polynomial := "111001000000000000000000000";      -- x^27 + x^26 + x^25 + x^22 + 1
      when 28 => polynomial := "1001000000000000000000000000";     -- x^28 + x^25 + 1
      when 29 => polynomial := "10100000000000000000000000000";    -- x^29 + x^27 + 1
      when 30 => polynomial := "110010100000000000000000000000";   -- x^30 + x^29 + x^26 + x^24 + 1
      when 31 => polynomial := "1001000000000000000000000000000";  -- x^31 + x^28 + 1
      when 32 => polynomial := "10100011000000000000000000000000"; -- x^32 + x^30 + x^26 + x^25 + 1
    end case;
    return polynomial;
  end function lfsr_polynomial;

  function lfsr_seed(length : natural range 2 to lfsr_max_length_c)
  return lfsr_t is
  begin
    return (length - 1 downto 0 => '1');
  end function lfsr_seed;

  function lfsr_shift(lfsr : lfsr_t; num_shifts : natural := 1)
  return lfsr_t is
  begin
    assert lfsr'length >= 2
    report "LFSR vector is too short."
    severity error;

    assert lfsr'length <= lfsr_max_length_c
    report "LFSR vector is too long."
    severity error;

    return lfsr_shift(lfsr, lfsr_polynomial(lfsr'length), num_shifts);
  end function lfsr_shift;

  function lfsr_shift(lfsr : lfsr_t; polynomial : std_ulogic_vector;
    num_shifts : natural := 1)
  return lfsr_t is
    variable tmp : lfsr_t(lfsr'range) := lfsr;
    variable res : lfsr_t(lfsr'range) := (others => '0');
  begin
    assert lfsr'left > lfsr'right
    report "Package requires an LFSR with DOWNTO range and minimum length of 2."
    severity error;

    assert polynomial'left > polynomial'right
    report "Package requires a polynomial with DOWNTO range and minimum length of 2."
    severity error;

    assert lfsr'left = polynomial'left and lfsr'right = polynomial'right
    report "Ranges of LFSR and polynomial have to be equal."
    severity error;

    assert polynomial(polynomial'high) = '1'
    report "Highest bit of polynomial has to be 1 as it represents its order."
    severity error;

    for i in 1 to num_shifts loop
      res(res'high) := tmp(tmp'low);
      for j in res'high - 1 downto res'low loop
        if polynomial(j) = '1' then
          res(j) := tmp(j + 1) xor tmp(tmp'low);
        else
          res(j) := tmp(j + 1);
        end if;
      end loop;
      tmp := res;
    end loop;

    return res;
  end function lfsr_shift;

  function "+"(lfsr : lfsr_t; num_shifts : natural)
  return lfsr_t is
  begin
    return lfsr_shift(lfsr, num_shifts);
  end function "+";

end package body lfsr_pkg;
