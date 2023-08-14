library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


package raven_pkg is

  constant vout_gain_c     : std_logic_vector(9 downto 0)  := "1011110010";
  constant vin_gain_c      : std_logic_vector(9 downto 0)  := "0011111000";
  constant T_prop_amp_c    : std_logic_vector(7 downto 0)  := x"1c";
  constant T_prop_comp_c   : std_logic_vector(7 downto 0)  := x"07";
  constant T_prop_sw_on_c  : std_logic_vector(7 downto 0)  := x"44";
  constant T_prop_sw_off_c : std_logic_vector(7 downto 0)  := x"37";

end package;


