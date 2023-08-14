library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity edge_detection is
    port (
        clk   : in std_logic;
        reset_n : in std_logic;
        trigger : in std_logic;
        posedge : out std_logic;
        negedge : out std_logic
    );
end entity edge_detection;

architecture rtl of edge_detection is

    signal trigger_ff : std_logic;
begin

ff_p : process (reset_n, clk)
begin

    if(reset_n = '0') then
        trigger_ff <= '0';
    elsif rising_edge(clk) then
        trigger_ff <= trigger;
    end if;
end process;
    
posedge <= '1' when trigger_ff = '0' and trigger = '1' else '0';
negedge <= '1' when trigger_ff = '1' and trigger = '0' else '0';

end architecture;