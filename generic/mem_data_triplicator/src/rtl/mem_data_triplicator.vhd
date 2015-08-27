--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Triplicate data on write and perform majority voting on read.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity mem_data_triplicator is
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
    rd_en_i   : in  std_ulogic;
    wr_en_i   : in  std_ulogic;
    data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;
    voted_o   : out std_ulogic;

    -- Memory interface
    mem_addr_o    : out std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    mem_rd_en_o   : out std_ulogic;
    mem_wr_en_o   : out std_ulogic;
    mem_data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    mem_data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    mem_data_en_i : in  std_ulogic;
    mem_busy_i    : in  std_ulogic;
    mem_done_i    : in  std_ulogic);
end entity mem_data_triplicator;

architecture rtl of mem_data_triplicator is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal wr_en : std_ulogic;
  signal rd_en : std_ulogic;

  signal wr_busy : std_ulogic;
  signal rd_busy : std_ulogic;

  signal wr_done : std_ulogic;

  signal rd_data_en : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= wr_busy or rd_busy or mem_busy_i;
  done_o <= wr_done or rd_data_en;

  data_en_o <= rd_data_en;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  wr_en <= wr_en_i and (not rd_en_i);
  rd_en <= rd_en_i and (not wr_en_i);

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
      rd_en_i => rd_en,
      wr_en_i => wr_en,

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

      wr_en_i => wr_en,
      data_i  => data_i,
      busy_o  => wr_busy,
      done_o  => wr_done,

      mem_wr_en_o => mem_wr_en_o,
      mem_data_o  => mem_data_o,
      mem_done_i  => mem_done_i);

  -- Perform majority voting on read
  mem_data_triplicator_rd_inst : entity work.mem_data_triplicator_rd
    generic map (
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      rd_en_i   => rd_en,
      data_o    => data_o,
      data_en_o => rd_data_en,
      busy_o    => rd_busy,
      voted_o   => voted_o,

      mem_rd_en_o   => mem_rd_en_o,
      mem_data_i    => mem_data_i,
      mem_data_en_i => mem_data_en_i);

end architecture rtl;
