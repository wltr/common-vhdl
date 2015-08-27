--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2013 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Detect edges on input signal.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity edge_detector is
  generic (
    -- Initial value of observed signal
    init_value_g : std_ulogic := '0';

    -- Edge type: 0 = Rising, 1 = Falling, 2 = Both
    edge_type_g : natural range 0 to 2 := 0;

    -- Hold flag until it is acknowledged
    hold_flag_g : boolean := false);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Acknowledge detected edges
    ack_i : in std_ulogic;

    -- Monitored signal
    sig_i : in std_ulogic;

    -- Detection flag
    edge_o : out std_ulogic);
end entity edge_detector;

architecture rtl of edge_detector is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal sig  : std_ulogic := init_value_g;
  signal edge : std_ulogic := '0';

  ------------------------------------------------------------------------------
  -- Internal Wires
  ------------------------------------------------------------------------------

  signal detected : std_ulogic;

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  edge_o <= edge;

  ------------------------------------------------------------------------------
  -- Signal Assignments
  ------------------------------------------------------------------------------

  -- Detect rising edge
  rising_gen : if edge_type_g = 0 generate
    detected <= (sig_i and not sig) and en_i;
  end generate rising_gen;

  -- Detect falling edge
  falling_gen : if edge_type_g = 1 generate
    detected <= (not sig_i and sig) and en_i;
  end generate falling_gen;

  -- Detect both edges
  both_gen : if edge_type_g = 2 generate
    detected <= (sig_i xor sig) and en_i;
  end generate both_gen;

  -- Directly report a detected edge
  direct_gen : if hold_flag_g = false generate
    edge <= detected;
  end generate direct_gen;

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      sig <= init_value_g;
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      else
        -- Save last state of observed signal
        sig <= sig_i;
      end if;
    end if;
  end process regs;

  -- Hold flag which reports a detected edge
  hold_gen : if hold_flag_g = true generate
    hold : process (clk_i, rst_asy_n_i) is
      procedure reset is
      begin
        edge <= '0';
      end procedure reset;
    begin -- process hold
      if rst_asy_n_i = '0' then
        reset;
      elsif rising_edge(clk_i) then
        if rst_syn_i = '1' then
          reset;
        else
          if ack_i = '1' then
            -- The acknowledge input resets the flag
            edge <= '0';
          elsif detected = '1' then
            -- Set flag when an edge is detected
            edge <= '1';
          end if;
        end if;
      end if;
    end process hold;
  end generate hold_gen;

end architecture rtl;
