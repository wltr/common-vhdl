-------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2015 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Testbench for Galois Linear Feedback Shift Register (LFSR) package.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lfsr_pkg.all;

entity lfsr_tb_top is
end entity lfsr_tb_top;

architecture rtl of lfsr_tb_top is

  ---------------------------------------------------------------------------
  -- Types and Constants
  ---------------------------------------------------------------------------

  constant period_c : natural := 10;

  constant len_c : natural := lfsr_length(period_c);

  constant seed_c : lfsr_t(len_c - 1 downto 0) := lfsr_seed(len_c);

  constant max_c : lfsr_t(len_c - 1 downto 0) := lfsr_shift(seed_c, period_c - 1);

  ---------------------------------------------------------------------------
  -- Internal Registers
  ---------------------------------------------------------------------------

  signal lfsr : lfsr_t(len_c - 1 downto 0);
  signal sig  : std_ulogic;

  ---------------------------------------------------------------------------
  -- Internal Wires
  ---------------------------------------------------------------------------

  signal clk   : std_ulogic := '1';
  signal rst_n : std_ulogic := '0';

begin -- architecture rtl

  ---------------------------------------------------------------------------
  -- Signal Assignments
  ---------------------------------------------------------------------------

  clk <= not clk after 10 ns;

  rst_n <= '1' after 42 ns;

  ---------------------------------------------------------------------------
  -- Registers
  ---------------------------------------------------------------------------

  regs : process(clk, rst_n) is
    procedure reset is
    begin
      lfsr <= seed_c;
      sig  <= '0';
    end procedure reset;
  begin -- process regs
    if rst_n = '0' then
      reset;
    elsif rising_edge(clk) then
      sig <= '0';

      lfsr <= lfsr + 1;

      if lfsr = max_c then
        sig  <= '1';
        lfsr <= seed_c;
      end if;
    end if;
  end process regs;

end architecture rtl;