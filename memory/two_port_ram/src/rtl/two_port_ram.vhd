--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Two port block RAM.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity two_port_ram is
  generic (
    -- Memory depth
    depth_g : positive := 32;

    -- Data bit width
    width_g : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Write port
    wr_addr_i : in  std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    wr_en_i   : in  std_ulogic;
    wr_data_i : in  std_ulogic_vector(width_g - 1 downto 0);
    wr_done_o : out std_ulogic;

    -- Read port
    rd_addr_i    : in  std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    rd_en_i      : in  std_ulogic;
    rd_data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    rd_data_en_o : out std_ulogic);
end entity two_port_ram;

architecture rtl of two_port_ram is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  type mem_t is array (0 to depth_g - 1) of std_ulogic_vector(wr_data_i'range);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal mem : mem_t;

  signal rd_data    : std_ulogic_vector(rd_data_o'range);
  signal rd_data_en : std_ulogic;

  signal wr_done : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  rd_data_o    <= rd_data;
  rd_data_en_o <= rd_data_en;

  wr_done_o <= wr_done;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      rd_data    <= (others => '0');
      rd_data_en <= '0';

      wr_done <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      rd_data_en <= '0';
      wr_done    <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if wr_en_i = '1' then
          mem(to_integer(unsigned(wr_addr_i))) <= wr_data_i;

          wr_done <= '1';
        end if;

        if rd_en_i = '1' then
          rd_data <= mem(to_integer(unsigned(rd_addr_i)));

          rd_data_en <= '1';
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
