--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Single port block RAM with TMR.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity single_port_ram_tmr is
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
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic);
end entity single_port_ram_tmr;

architecture rtl of single_port_ram_tmr is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal mem_addr        : std_ulogic_vector(natural(ceil(log2(real(depth_g * 3)))) - 1 downto 0);
  signal mem_rd_en       : std_ulogic;
  signal mem_wr_en       : std_ulogic;
  signal mem_data_in     : std_ulogic_vector(width_g - 1 downto 0);
  signal mem_data_out    : std_ulogic_vector(width_g - 1 downto 0);
  signal mem_data_out_en : std_ulogic;
  signal mem_done        : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  tmr_inst : entity work.mem_data_triplicator
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      addr_i    => addr_i,
      rd_en_i   => rd_en_i,
      wr_en_i   => wr_en_i,
      data_i    => data_i,
      data_o    => data_o,
      data_en_o => data_en_o,
      busy_o    => busy_o,
      done_o    => done_o,
      voted_o   => open,

      mem_addr_o    => mem_addr,
      mem_rd_en_o   => mem_rd_en,
      mem_wr_en_o   => mem_wr_en,
      mem_data_o    => mem_data_in,
      mem_data_i    => mem_data_out,
      mem_data_en_i => mem_data_out_en,
      mem_busy_i    => '0',
      mem_done_i    => mem_done);

  ram_inst : entity work.single_port_ram
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      addr_i    => mem_addr,
      rd_en_i   => mem_rd_en,
      wr_en_i   => mem_wr_en,
      data_i    => mem_data_in,
      data_o    => mem_data_out,
      data_en_o => mem_data_out_en,
      done_o    => mem_done);

end architecture rtl;
