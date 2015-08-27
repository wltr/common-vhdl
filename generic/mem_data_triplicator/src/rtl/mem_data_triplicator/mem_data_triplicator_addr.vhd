--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Calculate addresses for triplicated memory operations.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity mem_data_triplicator_addr is
  generic (
    -- Memory depth
    depth_g : positive := 1048576);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    addr_i  : in  std_ulogic_vector(natural(ceil(log2(real(depth_g / 3)))) - 1 downto 0);
    rd_en_i : in  std_ulogic;
    wr_en_i : in  std_ulogic;

    -- Memory interface
    mem_addr_o : out std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    mem_done_i : in  std_ulogic);
end entity mem_data_triplicator_addr;

architecture rtl of mem_data_triplicator_addr is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  constant addr_offset_c : natural := natural(floor(real(depth_g / 3)));

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal mem_addr : unsigned(natural(ceil(log2(real(depth_g)))) - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  mem_addr_o <= std_ulogic_vector(mem_addr);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- Calculate addresses
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      mem_addr <= to_unsigned(0, mem_addr'length);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        if wr_en_i = '1' or rd_en_i = '1' then
          mem_addr <= resize(unsigned(addr_i), mem_addr'length);
        elsif mem_done_i = '1' then
          mem_addr <= mem_addr + addr_offset_c;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
