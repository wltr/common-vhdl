--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- Store values needed by the decoder in a shift register.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity ads1281_filter_fifo is
  generic (
    -- Initial value of input signal
    init_value_g : std_ulogic := '0';

    -- Output offset from top of FIFO
    offset_g : natural := 0);
  port (
    -- Clock and resets
    clk_i       : in std_ulogic;
    rst_asy_n_i : in std_ulogic;
    rst_syn_i   : in std_ulogic;

    -- Enable
    en_i : in std_ulogic;

    -- Input signal
    sig_i : in std_ulogic;

    -- Delayed signal
    fifo_o : out std_ulogic_vector(2 downto 0));
end entity ads1281_filter_fifo;

architecture rtl of ads1281_filter_fifo is

  ------------------------------------------------------------------------------
  -- Internal Registers
  ------------------------------------------------------------------------------

  signal fifo : std_ulogic_vector(fifo_o'high + offset_g downto 0);

begin -- architecture rtl

  ------------------------------------------------------------------------------
  -- Outputs
  ------------------------------------------------------------------------------

  fifo_o <= fifo(fifo'high downto offset_g);

  ------------------------------------------------------------------------------
  -- Registers
  ------------------------------------------------------------------------------

  regs : process (clk_i, rst_asy_n_i) is
    procedure reset is
    begin
      fifo <= (others => init_value_g);
    end procedure reset;
  begin -- process regs
    if rst_asy_n_i = '0' then
      reset;
    elsif rising_edge(clk_i) then
      if rst_syn_i = '1' then
        reset;
      elsif en_i = '1' then
        fifo <= fifo(fifo'high - 1 downto fifo'low) & sig_i;
      end if;
    end if;
  end process regs;

end architecture rtl;
