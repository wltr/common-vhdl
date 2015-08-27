--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Single port block RAM.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity single_port_ram is
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

    -- Interface
    addr_i    : in  std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    rd_en_i   : in  std_ulogic;
    wr_en_i   : in  std_ulogic;
    data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    done_o    : out std_ulogic);
end entity single_port_ram;

architecture rtl of single_port_ram is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  type mem_t is array (0 to depth_g - 1) of std_ulogic_vector(data_i'range);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal mem : mem_t;

  signal data    : std_ulogic_vector(data_o'range);
  signal data_en : std_ulogic;
  signal done    : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= data;
  data_en_o <= data_en;
  done_o    <= done;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      data    <= (others => '0');
      data_en <= '0';
      done    <= '0';
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
        if wr_en_i = '1' then
          mem(to_integer(unsigned(addr_i))) <= data_i;

          done <= '1';
        elsif rd_en_i = '1' then
          data <= mem(to_integer(unsigned(addr_i)));

          data_en <= '1';
          done    <= '1';
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
