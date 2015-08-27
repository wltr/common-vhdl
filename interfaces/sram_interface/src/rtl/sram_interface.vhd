--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Generic SRAM interface. Tested with:
-- 16 Mbit Renesas R1LV1616RSA-7S and 8 Mbit Cypress CY62157EV30.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.lfsr_pkg.all;

entity sram_interface is
  generic (
    -- SRAM address width
    addr_width_g : positive := 20;

    -- SRAM data width
    data_width_g : positive := 16;

    -- Number of clock cycles to finish read operations
    read_delay_g : positive := 3;

    -- Number of clock cycles to finish write operations
    write_delay_g : positive := 3);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    addr_i    : in  std_ulogic_vector(addr_width_g - 1 downto 0);
    rd_en_i   : in  std_ulogic;
    wr_en_i   : in  std_ulogic;
    data_i    : in  std_ulogic_vector(data_width_g - 1 downto 0);
    data_o    : out std_ulogic_vector(data_width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    busy_o    : out std_ulogic;
    done_o    : out std_ulogic;

    -- SRAM signals
    sram_addr_o   : out std_ulogic_vector(addr_width_g - 1 downto 0);
    sram_data_i   : in  std_ulogic_vector(data_width_g - 1 downto 0);
    sram_data_o   : out std_ulogic_vector(data_width_g - 1 downto 0);
    sram_cs1_n_o  : out std_ulogic;
    sram_cs2_o    : out std_ulogic;
    sram_we_n_o   : out std_ulogic;
    sram_oe_n_o   : out std_ulogic;
    sram_le_n_o   : out std_ulogic;
    sram_ue_n_o   : out std_ulogic;
    sram_byte_n_o : out std_ulogic);
end entity sram_interface;

architecture rtl of sram_interface is

  ------------------------------------------------------------------------------
  -- Functions
  ------------------------------------------------------------------------------

  function max (l, r : integer) return integer is
  begin
    if l > r then return l;
    else return r;
    end if;
  end function max;

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- LFSR counter bit length
  constant len_c : natural := lfsr_length(max(read_delay_g, write_delay_g));

  -- LFSR counter initial value
  constant seed_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_seed(len_c);

  -- LFSR counter strobe value
  constant rd_max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, read_delay_g - 1);
  constant wr_max_c : std_ulogic_vector(len_c - 1 downto 0) := lfsr_shift(seed_c, write_delay_g - 1);

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal data    : std_ulogic_vector(data_width_g - 1 downto 0);
  signal data_en : std_ulogic;
  signal done    : std_ulogic;

  signal sram_addr : std_ulogic_vector(addr_width_g - 1 downto 0);
  signal sram_data : std_ulogic_vector(data_width_g - 1 downto 0);
  signal sram_cs   : std_ulogic;
  signal sram_cs_n : std_ulogic;
  signal sram_we_n : std_ulogic;
  signal sram_oe_n : std_ulogic;

  signal count : std_ulogic_vector(len_c - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= data;
  data_en_o <= data_en;
  busy_o    <= sram_cs;
  done_o    <= done;

  sram_addr_o   <= sram_addr;
  sram_data_o   <= sram_data;
  sram_cs1_n_o  <= sram_cs_n;
  sram_cs2_o    <= sram_cs;
  sram_we_n_o   <= sram_we_n;
  sram_oe_n_o   <= sram_oe_n;
  sram_le_n_o   <= '0';
  sram_ue_n_o   <= '0';
  sram_byte_n_o <= '1';

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- SRAM interface
  intf : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      data    <= (others => '0');
      data_en <= '0';
      done    <= '0';

      sram_addr <= (others => '0');
      sram_data <= (others => '0');
      sram_cs   <= '0';
      sram_cs_n <= '1';
      sram_we_n <= '1';
      sram_oe_n <= '1';

      count <= seed_c;
    end procedure reset;
  begin -- process intf
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Default values for flags
        done    <= '0';
        data_en <= '0';

        if sram_cs = '0' then
          -- SRAM is idle
          if rd_en_i /= wr_en_i then
            -- Common settings for read and write operations
            sram_addr <= addr_i;
            sram_cs   <= '1';
            sram_cs_n <= '0';
          end if;

          if rd_en_i = '1' and wr_en_i = '0' then
            -- Read operation
            sram_we_n <= '1';
            sram_oe_n <= '0';
          elsif rd_en_i = '0' and wr_en_i = '1' then
            -- Write operation
            sram_data <= data_i;
            sram_we_n <= '0';
            sram_oe_n <= '1';
          end if;
        else
          -- SRAM is busy
          if (sram_oe_n = '0' and count = rd_max_c) or (sram_we_n = '0' and count = wr_max_c) then
            -- Counter reached num_delay_g
            reset;
            if sram_oe_n = '0' then
              data    <= sram_data_i;
              data_en <= '1';
            end if;
            done <= '1';
          else
            -- Increment counter
            count <= lfsr_shift(count);
          end if;
        end if;
      end if;
    end if;
  end process intf;

end architecture rtl;
