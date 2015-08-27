--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Triplicate data on write.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity mem_data_triplicator_wr_only is
  generic (
    -- Memory depth
    depth_g : positive := 1048576;

    -- Memory data width
    width_g : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    addr_i    : in  std_ulogic_vector(natural(ceil(log2(real(depth_g / 3)))) - 1 downto 0);
    wr_en_i   : in  std_ulogic;
    data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;

    -- Memory interface
    mem_addr_o    : out std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    mem_wr_en_o   : out std_ulogic;
    mem_data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    mem_busy_i    : in  std_ulogic;
    mem_done_i    : in  std_ulogic);
end entity mem_data_triplicator_wr_only;

architecture rtl of mem_data_triplicator_wr_only is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal wr_busy : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= wr_busy or mem_busy_i;

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Calculate addresses
  mem_data_triplicator_addr_inst : entity work.mem_data_triplicator_addr
    generic map (
      depth_g => depth_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      addr_i  => addr_i,
      rd_en_i => '0',
      wr_en_i => wr_en_i,

      mem_addr_o => mem_addr_o,
      mem_done_i => mem_done_i);

  -- Triplicate data on write
  mem_data_triplicator_wr_inst : entity work.mem_data_triplicator_wr
    generic map (
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      wr_en_i => wr_en_i,
      data_i  => data_i,
      busy_o  => wr_busy,
      done_o  => done_o,

      mem_wr_en_o => mem_wr_en_o,
      mem_data_o  => mem_data_o,
      mem_done_i  => mem_done_i);

end architecture rtl;
