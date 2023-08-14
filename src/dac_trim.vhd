library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
entity dac_trim is
  port (
    dac_d      : in std_logic_vector(9 downto 0);
    dac_d_trim : out std_logic_vector(9 downto 0)

  );
end entity dac_trim;

architecture rtl of dac_trim is

    signal dac_d_temp0  : std_logic_vector(9 downto 0); 
    signal dac_d_temp1  : std_logic_vector(10 downto 0); 

begin
    dac_d_temp0 <= '0' & dac_d(9 downto 1);
    dac_d_temp1 <= std_logic_vector(to_unsigned(to_integer(unsigned('0' & dac_d))+531,11));

    
  process ( dac_d_temp1)
  begin
    if dac_d_temp1(10) = '1' then
      dac_d_trim <= (others => '1');
    else
      dac_d_trim <= dac_d_temp1(9 DOWNTO 0);
    end if;
  end process;
end architecture;