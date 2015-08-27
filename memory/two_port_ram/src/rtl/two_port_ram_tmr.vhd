--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Two port block RAM with TMR.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity two_port_ram_tmr is
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
    wr_addr_i : in std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    wr_en_i   : in std_ulogic;
    wr_data_i : in std_ulogic_vector(width_g - 1 downto 0);
    wr_done_o : out std_ulogic;
    wr_busy_o : out std_ulogic;

    -- Read port
    rd_addr_i    : in  std_ulogic_vector(natural(ceil(log2(real(depth_g)))) - 1 downto 0);
    rd_en_i      : in  std_ulogic;
    rd_data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    rd_data_en_o : out std_ulogic;
    rd_busy_o    : out std_ulogic);
end entity two_port_ram_tmr;

architecture rtl of two_port_ram_tmr is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal mem_wr_addr : std_ulogic_vector(natural(ceil(log2(real(depth_g * 3)))) - 1 downto 0);
  signal mem_wr_en   : std_ulogic;
  signal mem_wr_data : std_ulogic_vector(width_g - 1 downto 0);
  signal mem_wr_done : std_ulogic;

  signal mem_rd_addr    : std_ulogic_vector(natural(ceil(log2(real(depth_g * 3)))) - 1 downto 0);
  signal mem_rd_en      : std_ulogic;
  signal mem_rd_data    : std_ulogic_vector(width_g - 1 downto 0);
  signal mem_rd_data_en : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  rd_tmr_inst : entity work.mem_data_triplicator_rd_only
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      addr_i    => rd_addr_i,
      rd_en_i   => rd_en_i,
      data_o    => rd_data_o,
      data_en_o => rd_data_en_o,
      busy_o    => rd_busy_o,
      done_o    => open,
      voted_o   => open,

      mem_addr_o    => mem_rd_addr,
      mem_rd_en_o   => mem_rd_en,
      mem_data_i    => mem_rd_data,
      mem_data_en_i => mem_rd_data_en,
      mem_busy_i    => '0',
      mem_done_i    => mem_rd_data_en);

  wr_tmr_inst : entity work.mem_data_triplicator_wr_only
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      addr_i    => wr_addr_i,
      wr_en_i   => wr_en_i,
      data_i    => wr_data_i,
      busy_o    => wr_busy_o,
      done_o    => wr_done_o,

      mem_addr_o    => mem_wr_addr,
      mem_wr_en_o   => mem_wr_en,
      mem_data_o    => mem_wr_data,
      mem_busy_i    => '0',
      mem_done_i    => mem_wr_done);

  ram_inst : entity work.two_port_ram
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      wr_addr_i => mem_wr_addr,
      wr_en_i   => mem_wr_en,
      wr_data_i => mem_wr_data,
      wr_done_o => mem_wr_done,

      rd_addr_i    => mem_rd_addr,
      rd_en_i      => mem_rd_en,
      rd_data_o    => mem_rd_data,
      rd_data_en_o => mem_rd_data_en);

end architecture rtl;
