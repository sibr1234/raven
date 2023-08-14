library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.raven_pkg.all;

entity pwm is
  generic (
    counter_size_g : natural                       := 10;
    Tclk_g         : std_logic_vector(11 downto 0) := x"355" -- ufix12_En8
  );
  port (
    clk      : in std_logic;
    reset_n  : in std_logic;
    pwm_gen_ena : in std_logic;
    comp_cur : in std_logic;
    vout     : in std_logic_vector(11 downto 0);
    vin      : in std_logic_vector (11 downto 0);
    vref     : in std_logic_vector(11 downto 0);
    pwm      : out std_logic;
    comp_oc  : in std_logic;
    Tsw      : in std_logic_vector(11 downto 0);
    trim_on  : in std_logic_vector(7 downto 0); -- int8
    trim_off : in std_logic_vector(7 downto 0)  -- int8
  );
end entity pwm;

architecture rtl of pwm is
  signal cnt             : integer range 0 to ((2 ** counter_size_g) - 1);
  signal cnt_on_val      : integer range 0 to ((2 ** counter_size_g) - 1);
  signal cnt_off_val     : integer range 0 to ((2 ** counter_size_g) - 1);
  signal cnt_on_val_slv  : std_logic_vector(9 downto 0);
  signal cnt_off_val_slv : std_logic_vector(9 downto 0);

  signal pwm_en : std_logic;
  signal pwm_s  : std_logic;

  
  signal cnt_on         : std_logic;
  signal stop_on        : std_logic;
  signal cnt_off        : std_logic;
  signal stop_off       : std_logic;


begin

  delay_calc_inst : entity work.delay_calc
    generic map(
      Tclk_g          => Tclk_g,
      T_prop_amp_g    => T_prop_amp_c,
      T_prop_comp_g   => T_prop_comp_c,
      T_prop_sw_on_g  => T_prop_sw_on_c,
      T_prop_sw_off_g => T_prop_sw_off_c,
      vout_gain_g     => vout_gain_c,
      vin_gain_g      => vin_gain_c
    )
    port map(
      Tsw         => Tsw,
      vref        => vref,
      vin         => vin,
      trim_on     => trim_on,
      trim_off    => trim_off,
      n_on_delay  => cnt_on_val_slv,
      n_off_delay => cnt_off_val_slv
    );

  cnt_on_val  <=  to_integer(unsigned(cnt_on_val_slv(counter_size_g-1 downto 0))) when to_integer(unsigned(cnt_on_val_slv(counter_size_g-1 downto 0))) > 5 else 5;
  cnt_off_val <= to_integer(unsigned(cnt_off_val_slv(counter_size_g-1 downto 0)));

  pwm <= pwm_s and pwm_en;

  cnt_on  <= not (not pwm_s or (pwm_s and comp_cur));
  cnt_off <= not (pwm_s or (not pwm_s and not comp_cur));
  pwm_en  <= '1' when comp_oc = '1' and vout < x"ed8" and pwm_gen_ena = '1' else '0';

  cnt_p : process (clk, reset_n) is
  begin
    if (reset_n = '0') then
      cnt      <= 0;
    elsif rising_edge(clk) then
      cnt      <= cnt;
      if (cnt = 0) then
        if(cnt_on_val /= 0 and cnt_on = '1') then
        cnt <= cnt_on_val;
        elsif(cnt_off_val /= 0 and cnt_off = '1') then
        cnt <= cnt_off_val;
        end if;
      elsif cnt > 0 then
        cnt <= cnt - 1;
      end if;
    end if;
  end process;

  pwm_p : process (clk,reset_n) is
  begin
    if (reset_n = '0') then
      pwm_s <= '0';
    elsif(rising_edge(clk)) then
      pwm_s <= pwm_s;
      if cnt = 1 then
        if(cnt_on = '1') then
          pwm_s <= '0';
        elsif cnt_off = '1' then
          pwm_s <= '1';
        end if;
      elsif(cnt = 0) then
        if cnt_on_val = 0 and cnt_on = '1' then
          pwm_s <= '0';
        elsif cnt_off_val = 0 and cnt_off = '1' then
          pwm_s <= '1';
        end if;
      end if;

          
        

        end if;
      
  end process;

end architecture;