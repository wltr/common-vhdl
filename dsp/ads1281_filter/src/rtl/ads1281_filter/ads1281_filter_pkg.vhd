--------------------------------------------------------------------------------
-- LGPL v2.1, Copyright (c) 2014 Johannes Walter <johannes@wltr.io>
--
-- Description:
-- ADS1281 filter package.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package ads1281_filter_pkg is

  -- Number of ADS1281 filter channels
  constant ads1281_filter_num_channels_c : positive := 3;

  -- Type for filter results
  type ads1281_filter_result_t is array (0 to ads1281_filter_num_channels_c - 1) of std_ulogic_vector(23 downto 0);

end package ads1281_filter_pkg;

package body ads1281_filter_pkg is
end package body ads1281_filter_pkg;
