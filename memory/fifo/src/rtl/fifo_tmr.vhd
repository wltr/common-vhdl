--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- First-in, first-out buffer with TMR.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity fifo_tmr is
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
    wr_en_i   : in  std_ulogic;
    data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    done_o    : out std_ulogic;
    full_o    : out std_ulogic;
    wr_busy_o : out std_ulogic;

    -- Read port
    rd_en_i   : in  std_ulogic;
    data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    empty_o   : out std_ulogic;
    rd_busy_o : out std_ulogic);
end entity fifo_tmr;

architecture rtl of fifo_tmr is

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal fifo_wr_en   : std_ulogic;
  signal fifo_data_in : std_ulogic_vector(width_g - 1 downto 0);
  signal fifo_done    : std_ulogic;

  signal fifo_rd_en       : std_ulogic;
  signal fifo_data_out    : std_ulogic_vector(width_g - 1 downto 0);
  signal fifo_data_out_en : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  rd_tmr_inst : entity work.mem_data_triplicator_rd
    generic map (
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      rd_en_i   => rd_en_i,
      data_o    => data_o,
      data_en_o => data_en_o,
      busy_o    => rd_busy_o,
      voted_o   => open,

      mem_rd_en_o   => fifo_rd_en,
      mem_data_i    => fifo_data_out,
      mem_data_en_i => fifo_data_out_en);

  wr_tmr_inst : entity work.mem_data_triplicator_wr
    generic map (
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      wr_en_i => wr_en_i,
      data_i  => data_i,
      busy_o  => wr_busy_o,
      done_o  => done_o,

      mem_wr_en_o => fifo_wr_en,
      mem_data_o  => fifo_data_in,
      mem_done_i  => fifo_done);

  fifo_inst : entity work.fifo
    generic map (
      depth_g => (depth_g * 3),
      width_g => width_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,

      wr_en_i => fifo_wr_en,
      data_i  => fifo_data_in,
      done_o  => fifo_done,
      full_o  => full_o,

      rd_en_i   => fifo_rd_en,
      data_o    => fifo_data_out,
      data_en_o => fifo_data_out_en,
      empty_o   => empty_o);

end architecture rtl;
