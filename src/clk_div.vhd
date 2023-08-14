library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

entity Clock_Divider is
  generic
  (
    clk_div : natural range 0 to 1023 := 100
  );
  port
  (
    clk       : in std_logic;
    reset_n   : in std_logic;
    clock_out : out std_logic
  );
end Clock_Divider;

architecture bhv of clock_divider is

  signal count : natural range 0 to 1023;
  signal tmp   : std_logic;

begin

  process (clk, reset_n)
  begin
    if (reset_n = '0') then
      count <= 1;
      tmp   <= '0';
    elsif (clk'event and clk = '1') then
      count <= count + 1;
      if (count = clk_div) then
        tmp   <= not tmp;
        count <= 1;
      end if;
    end if;
    clock_out <= tmp;
  end process;

end bhv;