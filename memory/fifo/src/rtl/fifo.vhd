--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- First-in, first-out buffer.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo is
  generic (
    -- FIFO depth
    depth_g : positive := 32;

    -- Data bit width
    width_g : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Write port
    wr_en_i : in  std_ulogic;
    data_i  : in  std_ulogic_vector(width_g - 1 downto 0);
    done_o  : out std_ulogic;
    full_o  : out std_ulogic;

    -- Read port
    rd_en_i   : in  std_ulogic;
    data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    empty_o   : out std_ulogic);
end entity fifo;

architecture rtl of fifo is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  type mem_t is array (0 to depth_g - 1) of std_ulogic_vector(data_i'range);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal mem : mem_t;

  signal wr_addr : unsigned(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
  signal rd_addr : unsigned(natural(ceil(log2(real(depth_g)))) - 1 downto 0);

  signal data    : std_ulogic_vector(data_o'range);
  signal data_en : std_ulogic;

  signal done : std_ulogic;

  signal op : std_ulogic;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal full  : std_ulogic;
  signal empty : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= data;
  data_en_o <= data_en;

  done_o <= done;

  full_o  <= full;
  empty_o <= empty;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      wr_addr <= to_unsigned(0, wr_addr'length);
      rd_addr <= to_unsigned(0, rd_addr'length);

      data    <= (others => '0');
      data_en <= '0';

      done <= '0';

      op <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      data_en <= '0';
      done    <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if wr_en_i = '1' and full = '0' then
          mem(to_integer(wr_addr)) <= data_i;

          done <= '1';
          op   <= '1';

          if to_integer(wr_addr) < depth_g - 1 then
            wr_addr <= wr_addr + 1;
          else
            wr_addr <= to_unsigned(0, wr_addr'length);
          end if;
        elsif wr_en_i = '0' and rd_en_i = '1' and empty = '0' then
          data <= mem(to_integer(rd_addr));

          data_en <= '1';
          op      <= '0';

          if to_integer(rd_addr) < depth_g -1 then
            rd_addr <= rd_addr + 1;
          else
            rd_addr <= to_unsigned(0, rd_addr'length);
          end if;
        end if;
      end if;
    end if;
  end process regs;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  comb : process (wr_addr, rd_addr, op) is
  begin -- process comb
    -- Defaults
    empty <= '0';
    full  <= '0';

    if wr_addr = rd_addr then
      if op = '1' then
        full <= '1';
      else
        empty <= '1';
      end if;
    end if;
  end process comb;

end architecture rtl;
