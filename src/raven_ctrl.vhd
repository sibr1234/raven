library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
entity raven_ctrl is
  port (
    clk            : in std_logic;
    reset_n        : in std_logic;
    v_comp_reset_n : out std_logic;
    raven_ena      : in std_logic;
    test_mode      : in std_logic;
    vref_set       : in std_logic_vector(11 downto 0);
    vref_set_wstb  : in std_logic;
    vref           : out std_logic_vector(11 downto 0);
    dac_en         : out std_logic;
    adc_en         : out std_logic;
    adc_sample     : out std_logic;
    comp_oc        : in std_logic;
    comp_cur       : in std_logic;
    over_voltage   : in std_logic;
    adc_data_rdy   : in std_logic;
    adc_rdy        : in std_logic;
    v_comp_en      : out std_logic;
    pwm_gen_ena    : out std_logic

  );
end entity;
architecture rtl of raven_ctrl is

  type state_t is (idle, init, ramp, active, error, test);
  signal state            : state_t;
  signal state_next       : state_t;
  signal ramp_step        : std_logic;
  signal error_s          : std_logic;
  signal ramp_vref        : std_logic;
  signal comp_cur_posedge : std_logic;
  signal comp_cur_negedge : std_logic;
  signal comp_cur_edge    : std_logic;
  signal comp_cur_to      : std_logic;
  signal comp_cur_to_cnt  : natural range 0 to 255;
  signal vref_s : std_logic_vector(11 downto 0);
  signal adc_en_s         : std_logic;
  

begin

  vref <= vref_s;
  adc_en <= adc_en_s;
  error_s <= '1' when (comp_oc = '0' or over_voltage = '1') else '0';

  state_ff_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      state <= idle;
    elsif rising_edge(clk) then
      state <= state_next;
    end if;
  end process;
  
  fsm_p : process (state, raven_ena, adc_data_rdy, vref_s, error_s, vref_set_wstb, test_mode)
  begin

    state_next     <= state;
    dac_en         <= '1';
    adc_en_s         <= '1';
    v_comp_reset_n <= '1';
    v_comp_en      <= '1';
    ramp_vref      <= '0';
    pwm_gen_ena    <= '0';
    case state is
      when idle =>
        dac_en         <= '0';
        adc_en_s         <= '0';
        v_comp_en      <= '0';
        v_comp_reset_n <= '0';
        if (raven_ena = '1') then
          state_next <= init;
        end if;
        if (test_mode = '1') then
          state_next <= test;
        end if;
      when init =>
        v_comp_en <= '0';
        if (adc_data_rdy = '1') then
          state_next <= ramp;
        end if;
      when ramp =>
        ramp_vref   <= '1';
        pwm_gen_ena <= '1';
        if error_s = '1' then
          state_next <= error;
        elsif (vref_s = vref_set) then
          state_next <= active;
        end if;
      when active =>
        pwm_gen_ena <= '1';
        if error_s = '1' then
          state_next <= error;
        elsif raven_ena = '0' then
          state_next <= idle;
        elsif (vref_set_wstb = '1') then
          state_next <= ramp;
         end if;

      when test =>
        pwm_gen_ena     <= '1';
        v_comp_en      <= '0';
        if test_mode = '0' then
          state_next <= idle;
        end if;
        if error_s = '1' then
          state_next <= error;
        end if;
      when error =>
        v_comp_en <= '0';
        if raven_ena = '0' then
          state_next <= idle;
        end if;

      when others =>
        null;
    end case;
  end process;

  edge_detection_inst : entity work.edge_detection
    port map(
      clk     => clk,
      reset_n => reset_n,
      trigger => comp_cur,
      posedge => comp_cur_posedge,
      negedge => comp_cur_negedge
    );

  comp_cur_edge <= comp_cur_posedge and comp_cur_negedge;

  adc_sample_p : process (reset_n, clk)
  begin
    if (reset_n = '0') then
      adc_sample <= '0';
    elsif rising_edge(clk) then
      if (comp_cur_edge = '1' and adc_rdy = '1') then
        adc_sample <= '1';
      elsif (comp_cur_to = '1' and adc_rdy = '1') then
        adc_sample <= '1';
      else
        adc_sample <= '0';
      end if;
    end if;
  end process;

  comp_cur_to_cnt_p : process (reset_n, clk)
  begin
    if reset_n = '0' then
      comp_cur_to_cnt <= 150;
    elsif rising_edge(clk) then
      comp_cur_to_cnt <= comp_cur_to_cnt;
      if (adc_en_s = '1') then
        if (comp_cur_edge = '1' or comp_cur_to = '1') then
          comp_cur_to_cnt <= 150;
        elsif (comp_cur_to_cnt > 0) then
          comp_cur_to_cnt <= comp_cur_to_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  comp_cur_to <= '1' when comp_cur_to_cnt = 0 else '0';

  vref_ramp_p : process (clk, reset_n)
  begin
    if reset_n = '0' then
      vref_s <= (others => '0');
    elsif rising_edge(clk) then
      if (ramp_vref = '1' and ramp_step = '1') then
        if (vref_s < vref_set) then
          vref_s <= std_logic_vector(to_unsigned(to_integer(unsigned(vref_s)) + 1, 12));
        elsif (vref_s > vref_set) then
          vref_s <= std_logic_vector(to_unsigned(to_integer(unsigned(vref_s)) - 1, 12));
        end if;
      end if;
    end if;
  end process;
  pulse_gen_i0 : entity work.pulse_gen
    generic map(
      divider => 20,
      width   => 5
    )
    port map(
      clk     => clk,
      reset_n => reset_n,
      pulse   => ramp_step
    );
end architecture;