--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Receive synchronous serial data over 3 wires.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity serial_3wire_rx is
  generic (
    -- Data bit width
    data_width_g : positive := 32);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Reception lines
    rx_frame_i  : in std_ulogic;
    rx_bit_en_i : in std_ulogic;
    rx_i        : in std_ulogic;

    -- Interface
    data_o    : out std_ulogic_vector(data_width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    error_o   : out std_ulogic);
end entity serial_3wire_rx;

architecture rtl of serial_3wire_rx is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Using odd parity detects empty frames as errors
  constant parity_init_c : std_ulogic := '1';

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal data         : std_ulogic_vector(data_width_g downto 0) := (others => '0');
  signal data_en      : std_ulogic := '0';
  signal parity       : std_ulogic := parity_init_c;
  signal parity_error : std_ulogic := '0';

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal frame_fedge  : std_ulogic;
  signal bit_en_redge : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= data(data_width_g - 1 downto 0);
  data_en_o <= data_en;
  error_o   <= parity_error;

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Detect falling edge on rx_frame_i
  frame_edge_inst : entity work.edge_detector
    generic map (
      init_value_g => '0',
      edge_type_g  => 1,
      hold_flag_g  => false)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => '1',
      ack_i       => '0',
      sig_i       => rx_frame_i,
      edge_o      => frame_fedge);

  -- Detect rising edge on rx_bit_en_i
  bit_en_edge_inst : entity work.edge_detector
    generic map (
      init_value_g => '0',
      edge_type_g  => 0,
      hold_flag_g  => false)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => '1',
      ack_i       => '0',
      sig_i       => rx_bit_en_i,
      edge_o      => bit_en_redge);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      data         <= (others => '0');
      data_en      <= '0';
      parity       <= parity_init_c;
      parity_error <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Shift-in data and calculate parity on rising edges within a valid frame
        if rx_frame_i = '1' and bit_en_redge = '1' then
          data   <= rx_i & data(data'high downto data'low + 1);
          parity <= parity xor rx_i;
        end if;

        -- Data is valid at the end of the frame if the parity is correct
        data_en <= frame_fedge and (not parity);

        -- If the parity is not correct at the end of the frame, an error is reported
        parity_error <= frame_fedge and parity;

        -- Reset parity at the end of every frame
        if frame_fedge = '1' then
          parity <= parity_init_c;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
