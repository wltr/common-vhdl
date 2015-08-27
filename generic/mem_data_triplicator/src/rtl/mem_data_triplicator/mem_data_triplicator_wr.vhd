--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Triplicate data on write.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mem_data_triplicator_wr is
  generic (
    -- Memory data width
    width_g : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    wr_en_i : in  std_ulogic;
    data_i  : in  std_ulogic_vector(width_g - 1 downto 0);
    busy_o  : out std_ulogic;
    done_o  : out std_ulogic;

    -- Memory interface
    mem_wr_en_o : out std_ulogic;
    mem_data_o  : out std_ulogic_vector(width_g - 1 downto 0);
    mem_done_i  : in  std_ulogic);
end entity mem_data_triplicator_wr;

architecture rtl of mem_data_triplicator_wr is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- FSM states
  type state_t is (IDLE, A_WRITTEN, B_WRITTEN, C_WRITTEN);

  -- FSM registers
  type reg_t is record
    state     : state_t;
    mem_wr_en : std_ulogic;
    mem_data  : std_ulogic_vector(width_g - 1 downto 0);
    busy      : std_ulogic;
    done      : std_ulogic;
  end record reg_t;

  -- FSM initial state
  constant init_c : reg_t := (
    state     => IDLE,
    mem_wr_en => '0',
    mem_data  => (others => '0'),
    busy      => '0',
    done      => '0');

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  busy_o <= reg.busy;
  done_o <= reg.done;

  mem_wr_en_o <= reg.mem_wr_en;
  mem_data_o  <= reg.mem_data;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  -- FSM registering
  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      reg <= init_c;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        reg <= next_reg;
      end if;
    end if;
  end process regs;

  ------------------------------------------------------------------------------
  -- Combinatorics
  ------------------------------------------------------------------------------

  -- FSM combinatorics
  comb : process(reg, wr_en_i, data_i, mem_done_i) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    next_reg.mem_wr_en <= init_c.mem_wr_en;
    next_reg.done      <= init_c.done;

    case reg.state is
      when IDLE =>
        if wr_en_i = '1' then
          next_reg.mem_data  <= data_i;
          next_reg.mem_wr_en <= '1';
          next_reg.busy      <= '1';
          next_reg.state     <= A_WRITTEN;
        end if;

      when A_WRITTEN =>
        if mem_done_i = '1' then
          next_reg.mem_wr_en <= '1';
          next_reg.state     <= B_WRITTEN;
        end if;

      when B_WRITTEN =>
        if mem_done_i = '1' then
          next_reg.mem_wr_en <= '1';
          next_reg.state     <= C_WRITTEN;
        end if;

      when C_WRITTEN =>
        if mem_done_i = '1' then
          next_reg      <= init_c;
          next_reg.done <= '1';
        end if;

    end case;
  end process comb;

end architecture rtl;
