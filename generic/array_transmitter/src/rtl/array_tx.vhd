--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Send multiple packets.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.lfsr_pkg.all;

entity array_tx is
  generic (
    -- Number of data packets
    data_count_g : positive range 2 to positive'high := 8;

    -- Data bit width
    data_width_g : positive := 32);
  port (
    -- Clock and resets
    clk_i       : in  std_ulogic;
    rst_asy_n_i : in  std_ulogic;
    rst_syn_i   : in  std_ulogic;

    -- Internal interface
    data_i    : in  std_ulogic_vector((data_count_g * data_width_g) - 1 downto 0);
    data_en_i : in  std_ulogic;
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;

    -- Transmitter interface
    tx_data_o    : out std_ulogic_vector(data_width_g - 1 downto 0);
    tx_data_en_o : out std_ulogic;
    tx_done_i    : in  std_ulogic);
end entity array_tx;

architecture rtl of array_tx is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(data_count_g);

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter maximum value
  constant max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, data_count_g - 1);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal count : std_ulogic_vector(len_c - 1 downto 0) := seed_c;
  signal tx_en : std_ulogic := '0';
  signal busy  : std_ulogic := '0';
  signal done  : std_ulogic := '0';
  signal data  : std_ulogic_vector(data_i'range) := (others => '0');

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= busy;
  done_o <= done;

  tx_data_o    <= data(data'high downto data'high - data_width_g + 1);
  tx_data_en_o <= tx_en;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      count <= seed_c;
      tx_en <= '0';
      busy  <= '0';
      done  <= '0';
      data  <= (others => '0');
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        tx_en <= '0';
        done  <= '0';

        if busy = '1' and tx_done_i = '1' then
          if count = max_c then
            count <= seed_c;
            busy  <= '0';
            done  <= '1';
          else
            count <= lfsr_shift(count);
            tx_en <= '1';
            data  <= data(data'high - data_width_g downto data'low) & (data_width_g - 1 downto 0 => '0');
          end if;
        end if;

        if data_en_i = '1' then
          busy  <= '1';
          tx_en <= '1';
          data  <= data_i;
        end if;
      end if;
    end if;
  end process regs;

end architecture rtl;
