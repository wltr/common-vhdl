--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Perform majority voting on read.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity mem_data_triplicator_rd is
  generic (
    -- Memory data width
    width_g : positive := 16);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Interface
    rd_en_i   : in  std_ulogic;
    data_o    : out std_ulogic_vector(width_g - 1 downto 0);
    data_en_o : out std_ulogic;
    busy_o    : out std_ulogic;
    voted_o   : out std_ulogic;

    -- Memory interface
    mem_rd_en_o   : out std_ulogic;
    mem_data_i    : in  std_ulogic_vector(width_g - 1 downto 0);
    mem_data_en_i : in  std_ulogic);
end entity mem_data_triplicator_rd;

architecture rtl of mem_data_triplicator_rd is

  ------------------------------------------------------------------------------
  -- Types and Constants
  ------------------------------------------------------------------------------

  -- Data type to store the three data outputs for comparison
  type data_t is array (0 to 2) of std_ulogic_vector(width_g - 1 downto 0);

  -- FSM states
  type state_t is (IDLE, A_READY, B_READY, C_READY, CHECK);

  -- FSM registers
  type reg_t is record
    state     : state_t;
    mem_rd_en : std_ulogic;
    data      : std_ulogic_vector(width_g - 1 downto 0);
    data_en   : std_ulogic;
    busy      : std_ulogic;
    err       : std_ulogic;
    check     : data_t;
  end record reg_t;

  -- FSM initial state
  constant init_c : reg_t := (
    state     => IDLE,
    mem_rd_en => '0',
    data      => (others => '0'),
    data_en   => '0',
    busy      => '0',
    err       => '0',
    check     => (others => (others => '0')));

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal reg : reg_t;

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal next_reg : reg_t;

  signal corr : std_ulogic_vector(width_g - 1 downto 0);
  signal err  : std_ulogic_vector(width_g - 1 downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  data_o    <= reg.data;
  data_en_o <= reg.data_en;
  busy_o    <= reg.busy;
  voted_o   <= reg.err;

  mem_rd_en_o <= reg.mem_rd_en;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Determine correct data
  corr <= (reg.check(0) and reg.check(1)) or (reg.check(1) and reg.check(2)) or (reg.check(0) and reg.check(2));

  -- Check for errors
  err  <= (reg.check(0) xor reg.check(1)) or (reg.check(1) xor reg.check(2)) or (reg.check(0) xor reg.check(2));

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
  comb : process(reg, rd_en_i, mem_data_i, mem_data_en_i, corr, err) is
  begin -- process comb
    -- Defaults
    next_reg <= reg;

    next_reg.data_en   <= init_c.data_en;
    next_reg.mem_rd_en <= init_c.mem_rd_en;
    next_reg.err       <= init_c.err;

    case reg.state is
      when IDLE =>
        if rd_en_i = '1' then
          next_reg.mem_rd_en <= '1';
          next_reg.busy      <= '1';
          next_reg.state     <= A_READY;
        end if;

      when A_READY =>
        if mem_data_en_i = '1' then
          next_reg.check(0)  <= mem_data_i;
          next_reg.mem_rd_en <= '1';
          next_reg.state     <= B_READY;
        end if;

      when B_READY =>
        if mem_data_en_i = '1' then
          next_reg.check(1)  <= mem_data_i;
          next_reg.mem_rd_en <= '1';
          next_reg.state     <= C_READY;
        end if;

      when C_READY =>
        if mem_data_en_i = '1' then
          next_reg.check(2) <= mem_data_i;
          next_reg.state    <= CHECK;
        end if;

      when CHECK =>
        next_reg         <= init_c;
        next_reg.data    <= corr;
        next_reg.data_en <= '1';
        if err /= (err'range => '0') then
          next_reg.err <= '1';
        end if;

    end case;
  end process comb;

end architecture rtl;
