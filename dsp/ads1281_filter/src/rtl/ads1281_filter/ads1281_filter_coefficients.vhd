--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generate FIR filter coefficients on the fly.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_pkg.all;

entity ads1281_filter_coefficients is
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Compute next coefficient
    start_i : in std_ulogic;
    next_i  : in std_ulogic;

    -- Coefficient
    coeff_o    : out unsigned(23 downto 0);
    coeff_en_o : out std_ulogic;

    -- Control flags
    done_o : out std_ulogic);
end entity ads1281_filter_coefficients;

architecture rtl of ads1281_filter_coefficients is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Filter length
  constant filter_len_c : natural := 2000;

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(filter_len_c);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter maximum value
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, filter_len_c - 10);

  type state_t is (IDLE, ACC_1, ACC_2, ACC_3_1, ACC_3_2, ACC_4_1, ACC_4_2, ACC_4_3);

  type reg_t is record
    state : state_t;
    lfsr  : std_ulogic_vector(len_c - 1 downto 0);
    carry : std_ulogic;
    acc_1 : signed(1 downto 0);
    acc_2 : signed(8 downto 0);
    acc_3 : signed(15 downto 0);
    acc_4 : unsigned(23 downto 0);
    en    : std_ulogic;
    done  : std_ulogic;
  end record reg_t;

  constant init_c : reg_t := (
    state => IDLE,
    lfsr  => seed_c,
    carry => '0',
    acc_1 => (others => '0'),
    acc_2 => (others => '0'),
    acc_3 => (others => '0'),
    acc_4 => (others => '0'),
    en    => '0',
    done  => '0');

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;
  signal root     : signed(1 downto 0);
  signal a        : unsigned(9 downto 0);
  signal b        : unsigned(9 downto 0);
  signal y        : unsigned(9 downto 0);

begin   -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  coeff_o    <= reg.acc_4;
  coeff_en_o <= reg.en;
  done_o     <= reg.done;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Shared adder: 3rd accumulator + 2nd accumulator (split in 2 parts)
  --           and 4th accumulator + 3rd accumulator (split in 3 parts)
  y <= a + b;

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  ads1281_filter_roots : entity work.ads1281_filter_roots
    generic map (
      seed_g => seed_c)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      lfsr_i      => reg.lfsr,
      root_o      => root);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      reg <= init_c;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        reg <= next_reg;
      end if;
    end if;
  end process regs;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  comb : process(reg, next_i, start_i, root, y) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    a <= (others => '0');
    b <= (others => '0');

    next_reg.en   <= '0';
    next_reg.done <= '0';

    -- Save carry of shared adder for consecutive states
    next_reg.carry <= y(y'high);

    case reg.state is
      when IDLE => null;

      when ACC_1 =>
        if next_i = '1' then
          -- Save value for 1st accumulator
          next_reg.acc_1 <= reg.acc_1 + root;
          next_reg.state <= ACC_2;
        end if;

      when ACC_2 =>
        -- Save value for 2nd accumulator
        next_reg.acc_2 <= reg.acc_2 + reg.acc_1;
        next_reg.state <= ACC_3_1;

      when ACC_3_1 =>
        a <= '0' & unsigned(reg.acc_3(7 downto 0)) & '0';
        b <= '0' & unsigned(reg.acc_2(7 downto 0)) & '0';
        -- Save 1st partial result for 3rd accumulator
        next_reg.acc_3(7 downto 0) <= signed(y(8 downto 1));
        next_reg.state <= ACC_3_2;

      when ACC_3_2 =>
        a <= '0' & unsigned(reg.acc_3(15 downto 8)) & reg.carry;
        b <= (8 downto 0 => reg.acc_2(reg.acc_2'high)) & '1';
        -- Save 2nd partial result for 3rd accumulator
        next_reg.acc_3(15 downto 8) <= signed(y(8 downto 1));
        next_reg.state <= ACC_4_1;

      when ACC_4_1 =>
        a <= '0' & unsigned(reg.acc_4(7 downto 0)) & '0';
        b <= '0' & unsigned(reg.acc_3(7 downto 0)) & '0';
        -- Save 1st partial result for 4th accumulator
        next_reg.acc_4(7 downto 0) <= y(8 downto 1);
        next_reg.state <= ACC_4_2;

      when ACC_4_2 =>
        a <= '0' & unsigned(reg.acc_4(15 downto 8)) & reg.carry;
        b <= '0' & unsigned(reg.acc_3(15 downto 8)) & '1';
        -- Save 2nd partial result for 4th accumulator
        next_reg.acc_4(15 downto 8) <= y(8 downto 1);
        next_reg.state <= ACC_4_3;

      when ACC_4_3 =>
        a <= '0' & unsigned(reg.acc_4(23 downto 16)) & reg.carry;
        b <= (8 downto 0 => reg.acc_3(reg.acc_3'high)) & '1';
        -- Save 3rd partial result for 4th accumulator
        next_reg.acc_4(23 downto 16) <= y(8 downto 1);

        next_reg.state <= ACC_1;

        if reg.lfsr = max_c then
          -- Reset calculation cycle and wait
          next_reg <= init_c;
          -- Emit strobe when filter cycle is done
          next_reg.done <= '1';
        else
          next_reg.lfsr <= lfsr_shift(reg.lfsr);
        end if;

        next_reg.en    <= '1';
    end case;

    -- Start the next calculation cycle
    if start_i = '1' then
      next_reg       <= init_c;
      next_reg.state <= ACC_1;
    end if;
  end process comb;

end architecture rtl;
