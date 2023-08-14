
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity synch is
    generic (
        size_g : natural := 1
    );
    port (
        clk   : in std_logic;
        reset_n : in std_logic;
        in_async : in std_logic_vector(size_g-1 downto 0);
        out_sync : out std_logic_vector(size_g-1 downto 0)
    );
end entity synch;

architecture rtl of synch is

    signal sync_ff : std_logic_vector(size_g-1 downto 0);

begin

    synch_p : process (reset_n,clk)
    begin

    if reset_n = '0' then
        out_sync <= (OTHERS => '0');
        sync_ff  <= (OTHERS => '0');
    elsif rising_edge(clk) then
        sync_ff <=  in_async;    
        out_sync <=  sync_ff;
    end if;

    end process;


end architecture;