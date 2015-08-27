--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Calculate average of 10 ADS1281 filter outputs.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ads1281_average_calculator is
  port (
    clk_i      : in  std_ulogic;
    rst_n_i    : in  std_ulogic;
    stb_50hz_i : in  std_ulogic;
    data_i     : in  signed(23 downto 0);
    en_i       : in  std_ulogic;
    avg_o      : out signed(23 downto 0);
    en_o       : out std_ulogic);
end entity ads1281_average_calculator;

architecture rtl of ads1281_average_calculator is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR's initial value
  constant seed_c : std_ulogic_vector(3 downto 0) := "0001";

  -- LFSR's value after 9 shifts
  constant data_c : std_ulogic_vector(3 downto 0) := "1011";

  -- LFSR's value after 2 shifts
  constant padding_c : std_ulogic_vector(3 downto 0) := "0100";

  type state_t is (ADD, ADD_MIN, ADD_MAX, DONE);

  type reg_t is record
    state : state_t;
    lfsr  : std_ulogic_vector(3 downto 0);
    sum   : signed(27 downto 0);
    min   : signed(23 downto 0);
    max   : signed(23 downto 0);
  end record reg_t;

  constant init_c : reg_t := (
    state => ADD,
    lfsr  => seed_c,
    sum   => (others => '0'),
    min   => (others => '0'),
    max   => (others => '0'));

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;
  signal lfsr_in  : std_ulogic;
  signal add_in   : signed(23 downto 0);
  signal sum      : signed(27 downto 0);
  signal avg      : signed(23 downto 0);

begin   -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  avg_o <= avg when reg.state = DONE else (others => '0');
  en_o <= '1' when reg.state = DONE else '0';

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- LFSR feedback polynomial: x^4 + x^3 + 1 (period: 15)
  lfsr_in <= reg.lfsr(reg.lfsr'high) xor reg.lfsr(reg.lfsr'high - 1);

  -- Shifting sum to the right by 4 bits, this equals a division by 16
  avg <= reg.sum(reg.sum'high downto reg.sum'length - avg'length);

  -- Adder
  sum <= reg.sum + add_in;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  process (clk_i, rst_n_i) is
  begin   -- process
    if rst_n_i = '0' then
      reg <= init_c;
    elsif rising_edge(clk_i) then
      reg <= next_reg;
    end if;
  end process;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  process(reg, lfsr_in, sum, stb_50hz_i, data_i, en_i) is
  begin   -- process
    -- Defaults
    next_reg <= reg;
    add_in <= (others => '0');

    if stb_50hz_i = '1' then
      -- Reset
      next_reg <= init_c;
    else
      case reg.state is
        when ADD =>
          if en_i = '1' then
            -- Add new data to the sum
            add_in <= data_i;
            next_reg.sum <= sum;

            if reg.lfsr = seed_c then
              -- First data is stored as minimum and maximum
              next_reg.min <= data_i;
              next_reg.max <= data_i;
            else
              if data_i < reg.min then
                -- If new data is smaller than current minimum, it is stored as new minimum
                next_reg.min <= data_i;
              end if;

              if data_i > reg.max then
                -- If new data is greater than current maximum, it is stored as new maximum
                next_reg.max <= data_i;
              end if;
            end if;

            if reg.lfsr = data_c then
              -- Continue with adding the minimum value to the sum
              next_reg.state <= ADD_MIN;
              next_reg.lfsr <= seed_c;
            else
              next_reg.lfsr <= reg.lfsr(reg.lfsr'high - 1 downto reg.lfsr'low) & lfsr_in;
            end if;
          end if;

        when ADD_MIN =>
          -- Add minimum to the sum
          add_in <= reg.min;
          next_reg.sum <= sum;

          if reg.lfsr = padding_c then
            -- Continue with adding the maximum value to the sum
            next_reg.state <= ADD_MAX;
            next_reg.lfsr <= seed_c;
          else
            next_reg.lfsr <= reg.lfsr(reg.lfsr'high - 1 downto reg.lfsr'low) & lfsr_in;
          end if;

        when ADD_MAX =>
          -- Add maximum to the sum
          add_in <= reg.max;
          next_reg.sum <= sum;

          if reg.lfsr = padding_c then
            -- Reset
            next_reg.state <= DONE;
          else
            next_reg.lfsr <= reg.lfsr(reg.lfsr'high - 1 downto reg.lfsr'low) & lfsr_in;
          end if;

        when DONE =>
          -- Reset when done
          next_reg <= init_c;
      end case;
    end if;
  end process;

end architecture rtl;
