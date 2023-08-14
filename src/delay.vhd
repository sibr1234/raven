library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity delay is
    generic(
        n_delay : natural ;
        width : natural
        );
    port (
        clk   : in std_logic;
        reset_n : in std_logic;
        sig_in : in std_logic_vector(width -1 downto 0);
        delayed_out : out std_logic_vector(width -1 downto 0) 
        
    );
end entity delay;

architecture rtl of delay is

    type buffer_t is array (0 to n_delay-1) of std_logic_vector(width-1 downto 0);
    signal delay_buffer : buffer_t;

begin

   g1: if n_delay = 1 generate
        delay_p : process (clk, reset_n)
        begin
            if reset_n = '0' then
                delayed_out <= (OTHERS =>'0');  
            elsif rising_edge(clk) then
                delayed_out <= sig_in; 
            end if;
        end process;
    end generate;

    

 g2:  if( n_delay = 2 )  generate
        delay_p : process (clk, reset_n)
        begin
            if(reset_n = '0') then
                for i in 0 to n_delay-1 loop
                    delay_buffer(i) <= (OTHERS => '0');
                end loop;    
                delayed_out <= (OTHERS =>'0');   
            elsif rising_edge(clk) then
                delay_buffer(0)<= sig_in;
                delayed_out <= delay_buffer(0); 
            end if;
        end process;
    end generate;

   
        
 g3:  if( n_delay > 2 )  generate
    delay_p : process (clk, reset_n)
    begin
        if(reset_n = '0') then
            for i in 0 to n_delay-1 loop
                delay_buffer(i) <= (OTHERS => '0');
            end loop;    
            delayed_out <= (OTHERS =>'0');   
        elsif rising_edge(clk) then
            delay_buffer(0)<= sig_in;
            for j in 0 to n_delay-2 loop
                delay_buffer(j+1) <=  delay_buffer(j);
            end loop;
        delayed_out <= delay_buffer(n_delay-2);
        end if;
    end process;
end generate;
   
    

end architecture;