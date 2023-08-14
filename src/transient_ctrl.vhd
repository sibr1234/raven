library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity transient_ctrl is
    port (
        clk   : in std_logic;
        reset_n : in std_logic;
        transient_ena : in std_logic;
        divider : in std_logic_vector(9 downto 0);
        load_sw : out std_logic
        
    );
end entity transient_ctrl;

architecture rtl of transient_ctrl is

    signal divider_int : natural range 0 to 1023;
    signal cnt : natural range 0 to 1023;
    signal load_sw_s : std_logic;

begin

    divider_int <= to_integer(unsigned(divider));
    load_sw <= load_sw_s;

    process (clk, reset_n)
    begin
        if reset_n = '0' then
            cnt <= 0;
            load_sw_s <= '0';
        elsif rising_edge(clk) then
            if(transient_ena = '1') then
                if(cnt = 0) then
                    load_sw_s <=  NOT load_sw_s;
                    cnt <= divider_int;
                else
                    cnt <= cnt - 1;
                end if;
            else
                load_sw_s <= '0';
                cnt <= 0;
            end if;
        end if;
    end process;
    

end architecture;