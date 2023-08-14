library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity test_ctrl is
    port (
        clk : in std_logic; -- 1 MHz
        reset_n : in std_logic;
        test_en : in std_logic;
        sw_div : in std_logic_vector(9 downto 0); 
        load_sw : out std_logic
    );
end entity test_ctrl;

architecture rtl of test_ctrl is
    signal cnt : integer range 0 to 1023;
    signal load_sw_s : std_logic;


    
    

begin


load_sw <= load_sw_s;

process (clk, reset_n)
begin
    if(reset_n = '0') then
        cnt <= 0;
        load_sw_s <= '0';
    elsif (rising_edge(clk)) then
        if(test_en = '1') then
            if(cnt = to_integer(unsigned(sw_div))) then
                cnt <= 0;
                load_sw_s <= not load_sw_s;
             else
                cnt <= cnt + 1;
                load_sw_s <= load_sw_s;
            end if;   
        else 
            cnt <= 0;
            load_sw_s <= '0';
        end if;
    end if;
         


end process;
    

end architecture;