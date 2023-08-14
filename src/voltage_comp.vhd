library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity voltage_comp is
    generic (
        counter_size : natural := 8

    );
    port (
        clk   : in std_logic;
        reset_n : in std_logic;
        delay_val : out std_logic_vector(counter_size-1 downto 0)
        
    );
end entity voltage_comp;

architecture rtl of voltage_comp is

   signal delay_val_s : std_logic_vector(counter_size-1 downto 0);

begin

    delay_val <= delay_val_s;

    -- instantiate simulink generated comp here
    process (clk, reset_n)
    begin
        if(reset_n = '0') then
            delay_val_s <= x"ff";
        elsif rising_edge(clk) then
            delay_val_s <= NOT delay_val_s;
        end if;
    end process;

end architecture;