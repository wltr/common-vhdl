--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Receive asynchronous serial data.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

library work;
use work.lfsr_pkg.all;

entity uart_rx is
  generic (
    -- Data bit width
    data_width_g : positive := 8;

    -- Parity bit: 0 = None, 1 = Odd, 2 = Even
    parity_g : natural range 0 to 2 := 0;

    -- Number of stop bits
    stop_bits_g : positive range 1 to 2 := 1;

    -- Number of clock cycles per bit
    num_ticks_g  : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Reception line
    rx_i : in std_ulogic;

    -- Interface
    data_o    : out std_ulogic_vector(data_width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    error_o   : out std_ulogic);
end entity uart_rx;

architecture rtl of uart_rx is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Transmission bit length
  constant rx_len_c : natural := 1 + data_width_g + stop_bits_g + natural(ceil(real(parity_g / 2)));

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(rx_len_c);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count        : std_ulogic_vector(len_c - 1 downto 0);
  signal data         : std_ulogic_vector(rx_len_c - 1 downto 0);
  signal data_en      : std_ulogic;
  signal parity_error : std_ulogic;
  signal stop_error   : std_ulogic;
  signal busy         : std_ulogic;
  signal done         : std_ulogic;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal parity_init : std_ulogic;
  signal parity_bit  : std_ulogic;
  signal parity      : std_ulogic_vector(data_o'range);
  signal data_bits   : std_ulogic_vector(data_o'range);
  signal rx_fedge    : std_ulogic;
  signal bit_strobe  : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= data_bits;
  data_en_o <= data_en;
  error_o   <= parity_error or stop_error;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Extract data bits from received packet
  data_bits <= data(data_width_g downto 1);

  -- Set parity bit's initial value
  parity_init <= '1' when parity_g = 1 else '0';

  -- Compute parity bit
  parity(0) <= data_bits(0) xor parity_init;
  parity_gen : for i in 1 to parity'high generate
    parity(i) <= data_bits(i) xor parity(i - 1);
  end generate parity_gen;
  parity_bit <= parity(parity'high) xor data(data_width_g + 1);

  ------------------------------------------------------------------------------
  -- Instances
  ------------------------------------------------------------------------------

  -- Detect falling edge on rx_i
  rx_edge_inst : entity work.edge_detector
    generic map (
      init_value_g => '1',
      edge_type_g  => 1,
      hold_flag_g  => false)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => '1',
      ack_i       => '0',
      sig_i       => rx_i,
      edge_o      => rx_fedge);

  bit_clock_recovery_inst : entity work.bit_clock_recovery
    generic map (
      num_cycles_g => num_ticks_g)
    port map (
      clk_i       => clk_i,
      rst_asy_n_i => rst_asy_n_i,
      rst_syn_i   => rst_syn_i,
      en_i        => '1',
      sig_i       => rx_i,
      bit_clk_o   => bit_strobe);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count        <= seed_c;
      data         <= (others => '0');
      data_en      <= '0';
      parity_error <= '0';
      stop_error   <= '0';
      busy         <= '0';
      done         <= '0';
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      -- Defaults
      data_en      <= '0';
      parity_error <= '0';
      stop_error   <= '0';
      done         <= '0';

      if rst_syn_i = '1' then
        reset;
      else
        if busy = '0' and rx_fedge = '1' then
          busy <= '1';
        elsif busy = '1' and bit_strobe = '1' then
          data <= rx_i & data(data'high downto data'low + 1);

          if count = lfsr_shift(seed_c, rx_len_c - 1) then
            count <= seed_c;
            busy  <= '0';
            done  <= '1';
          else
            count <= lfsr_shift(count);
          end if;
        end if;

        stop_error <= done and not data(data'high);
        if parity_g = 0 then
          parity_error <= '0';
          data_en      <= done and data(data'high);
        else
          parity_error <= done and parity_bit;
          data_en      <= done and data(data'high) and not parity_bit;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
