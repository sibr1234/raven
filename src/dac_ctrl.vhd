----------------------------------------------------------------------
-- filename: dac_ctrl.vhd
-- author: Simon Brunner
-- date: 2023/06/02
-- description: driver for MAXIM MAX5184 DAC
--              when dac_en is high dac_d_i is driven to dac_d_o
--              the DAC latches this value at a rising edge of dac_clk     
---------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
entity dac_ctrl is
  port (
    clk      : in std_logic;                     --! dac driver clock clock
    reset_n  : in std_logic;                     --! dac driver reset active low
    dac_en_i : in std_logic;                     --! dac enable from top
    dac_d_i  : in std_logic_vector(9 downto 0);  --! data to dac from top
    dac_set  : in std_logic;                     --! command to set dac value from top
    dac_d_o  : out std_logic_vector(9 downto 0); --! data out to dac
    dac_en   : out std_logic;                    --! dac enable signal
    dac_cs_n : out std_logic;                    --! dac chip select signal active low
    dac_clk  : out std_logic                     --! clock signals at which signals to dac are sampled if dac_cs_n is low

  );
end entity;

architecture rtl of dac_ctrl is

  type dac_state_type is (IDLE, RDY, WAIT_CS, SET, DAC_WAIT); --!states of dac ctrl
  signal dac_state      : dac_state_type;                     --! holding state of fsm
  signal dac_state_next : dac_state_type;                     --! holding next state of fsm

  signal dac_clk_en : std_logic; --! outputs one dac_clk cycle
  constant dac_divider_c : natural := 1;
  signal timeout_cnt : natural range 0 to 1;
  signal timeout_ld : std_logic;
  signal timeout_zero : std_logic;
  

begin

  --! ff controlling dac state
  dac_state_p : process (clk, reset_n)
  begin

    if reset_n = '0' then
      dac_state <= IDLE;
      timeout_cnt <= 0;
    elsif rising_edge(clk) then
        dac_state <= dac_state_next;
        if(timeout_ld = '1') then
          timeout_cnt <= dac_divider_c;
        elsif timeout_cnt >0 then
          timeout_cnt <= timeout_cnt - 1;
        else
          timeout_cnt <= timeout_cnt;
      end if;
    end if;
  end process;

  timeout_zero <= '1' when timeout_cnt = 0 else '0';

  --! fsm controlling dac behaviour
  dac_fsm_p : process (dac_state, dac_set, dac_en_i, dac_d_i)
  begin

    dac_state_next <= dac_state;
    dac_en         <= '1';
    dac_cs_n       <= '1';
    dac_clk        <= '0';
    timeout_ld <= '0';
    case dac_state is
      when IDLE =>
        dac_en <= '0';
        if dac_en_i = '1' then
          dac_en         <= '1';
          dac_state_next <= RDY;
        end if;
      when RDY =>
        if dac_en_i = '0' then 
          dac_state_next <= IDLE;
        elsif (dac_set = '1') then
          dac_state_next <= WAIT_CS;
        end if;
      when WAIT_CS =>
        dac_cs_n       <= '0';
        dac_state_next <= SET;
        timeout_ld  <= '1';
       when SET =>
        dac_clk        <= '1';
        dac_cs_n       <= '0';
        if(timeout_zero = '1' ) then
          dac_state_next <= DAC_WAIT;
        end if;
      when DAC_WAIT =>
        dac_clk        <= '0';
        dac_cs_n       <= '0';
        dac_state_next <= RDY;
        
      when others =>
        null;
    end case;
  end process;

  dac_d_o <= dac_d_i;-- when dac_en_i = '1' else (others => '0');


end architecture;