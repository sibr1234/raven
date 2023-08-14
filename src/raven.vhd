library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.raven_pkg.all;
entity raven is
  generic (
    counter_size_g : natural                       := 10;
    counter_tclk_g : std_logic_vector(11 downto 0) := x"355" -- ufix12_En8
  );
  port (
    -- clk and reset

    clk_100     : in std_logic;
    clk_counter : in std_logic;
    reset_n     : in std_logic;

    -- ctrl and cfg signals
    raven_ena     : in std_logic;
    test_mode     : in std_logic;
    transient_ena : in std_logic;
    transient_div : in std_logic_vector(9 downto 0);
    vref_set      : in std_logic_vector(11 downto 0);
    vref_set_wstb : in std_logic;
    iref_test     : in std_logic_vector(9 downto 0);
    tsw           : in std_logic_vector(11 downto 0);
    trim_on       : in std_logic_vector(7 downto 0);
    trim_off      : in std_logic_vector(7 downto 0);
    a1            : in std_logic_vector(31 downto 0);
    a2            : in std_logic_vector(31 downto 0);
    b0            : in std_logic_vector(31 downto 0);
    b1            : in std_logic_vector(31 downto 0);
    b2            : in std_logic_vector(31 downto 0);

    -- ADC signals
    drp_daddr   : out std_logic_vector(6 downto 0);
    drp_den     : out std_logic;
    drp_di      : out std_logic_vector(15 downto 0);
    drp_do      : in std_logic_vector(15 downto 0);
    drp_drdy    : in std_logic;
    drp_dwe     : out std_logic;
    adc_channel : in std_logic_vector(4 downto 0);
    adc_eoc     : in std_logic;
    adc_eos     : in std_logic;
    adc_busy    : in std_logic;
    adc_convst  : out std_logic;
    -- DAC signals
    dac_d_o  : out std_logic_vector(9 downto 0); --! data out to dac
    dac_en   : out std_logic;                    --! dac enable signal
    dac_cs_n : out std_logic;                    --! dac chip select signal active low
    dac_clk  : out std_logic;                    --! clock signals at which signals to dac are sampled if dac_cs_n is low

    -- comparator signals
    comp_cur_async : in std_logic;
    comp_oc_async  : in std_logic;

    -- switching signal
    pwm     : out std_logic;
    load_sw : out std_logic;
    
    -- debug signals
    led0 : out std_logic;
    led1 : out std_logic;
    led2 : out std_logic;
    led3 : out std_logic;

    pmoda : out std_logic_vector(7 downto 0);
    pmodb : out std_logic_vector(7 downto 0)

  );
end entity;

architecture rtl of raven is

  signal comp_cur_sync_fast : std_logic;
  signal comp_cur_sync_100  : std_logic;
  signal comp_oc_sync_fast  : std_logic;
  signal comp_oc_sync_100   : std_logic;

  signal vout        : std_logic_vector(11 downto 0);
  signal vout_sync_24        : std_logic_vector(11 downto 0);
  signal vout_sync_fast        : std_logic_vector(11 downto 0);
  signal vin         : std_logic_vector(11 downto 0);
  signal vin_sync_24         : std_logic_vector(11 downto 0);
  signal vin_sync_fast         : std_logic_vector(11 downto 0);
  signal iref        : std_logic_vector(9 downto 0);
  signal dac_d_i     : std_logic_vector(9 downto 0);
  signal vref        : std_logic_vector(11 downto 0);
  signal dac_en_i    : std_logic;
  signal dac_set_100 : std_logic;
  signal dac_set     : std_logic;
  signal dac_set_24  : std_logic;

  signal adc_data_rdy           : std_logic;
  signal clk_enable             : std_logic;
  signal over_voltage           : std_logic;
  signal adc_enable             : std_logic;
  signal adc_sample             : std_logic;
  signal adc_rdy                : std_logic;
  signal v_comp_reset_n         : std_logic;
  signal v_comp_reset_n_sync_24 : std_logic;
  signal v_comp_en              : std_logic;
  signal v_comp_en_sync_24      : std_logic;
  signal filter_ena             : std_logic;
  signal dac_d_raw              : std_logic_vector(9 downto 0);
  signal pwm_gen_ena            : std_logic;
  signal pwm_gen_ena_sync_fast  : std_logic;

  signal iref_mux : std_logic_vector(9 downto 0);
  signal vref_mux : std_logic_vector(11 downto 0);

  signal transient_ena_sync_clk1 : std_logic;
  signal transient_div_sync_clk1 : std_logic_vector(9 downto 0);

  signal a1_sync_24 : std_logic_vector(31 downto 0);
  signal a2_sync_24 : std_logic_vector(31 downto 0);
  signal b0_sync_24 : std_logic_vector(31 downto 0);
  signal b1_sync_24 : std_logic_vector(31 downto 0);
  signal b2_sync_24 : std_logic_vector(31 downto 0);
  
   signal voltage_ctrl_reset_n : std_logic;
   signal voltage_ctrl_clk_enable : std_logic;

begin
  led0 <= raven_ena;
  led1 <= test_mode;
  led2 <= pwm_gen_ena;
  led3 <= comp_cur_sync_fast;

  pmoda(0) <= clk_1;
  pmoda(1) <= clk_100;
  pmoda(2) <= clk_counter;
  pmoda(7 downto 3) <= "00000" ;
  pmodb<= "00000000" ;
  
  voltage_ctrl_reset_n <= reset_n and v_comp_reset_n_sync_24;
  voltage_ctrl_clk_enable <= filter_ena and v_comp_en_sync_24;

  

  over_voltage <= '1' when vout > x"ed8" else '0';
  iref_mux     <= iref when test_mode = '0' else iref_test;
  vref_mux     <= vref when test_mode = '0' else vout;

  raven_ctrl_i0 : entity work.raven_ctrl
    port map(
      clk            => clk_100,
      reset_n        => reset_n,
      v_comp_reset_n => v_comp_reset_n,
      raven_ena      => raven_ena,
      test_mode      => test_mode,
      vref_set       => vref_set,
      vref_set_wstb  => vref_set_wstb,
      vref           => vref,
      dac_en         => dac_en_i,
      adc_en         => adc_enable,
      v_comp_en      => v_comp_en,
      comp_oc        => comp_oc_sync_100,
      comp_cur       => comp_cur_sync_100,
      over_voltage   => over_voltage,
      adc_data_rdy   => adc_data_rdy,
      adc_rdy        => adc_rdy,
      adc_sample     => adc_sample,
      pwm_gen_ena    => pwm_gen_ena

    );

  synch_i0 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      in_async(0) => comp_cur_async,
      out_sync(0) => comp_cur_sync_fast
    );

  synch_i1 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_100,
      reset_n     => reset_n,
      in_async(0) => comp_cur_async,
      out_sync(0) => comp_cur_sync_100
    );

  synch_i2 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_100,
      reset_n     => reset_n,
      in_async(0) => comp_oc_async,
      out_sync(0) => comp_oc_sync_100
    );

  synch_i3 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      in_async(0) => comp_oc_async,
      out_sync(0) => comp_oc_sync_fast
    );

  synch_i4 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      in_async(0) => pwm_gen_ena,
      out_sync(0) => pwm_gen_ena_sync_fast
    );


  adc_ctrl_i0 : entity work.adc_ctrl
    port map(
      clk            => clk_100,
      reset_n        => reset_n,
      drp_daddr      => drp_daddr,
      drp_den        => drp_den,
      drp_di         => drp_di,
      drp_do         => drp_do,
      drp_drdy       => drp_drdy,
      drp_dwe        => drp_dwe,
      adc_channel    => adc_channel,
      adc_eoc        => adc_eoc,
      adc_eos        => adc_eos,
      adc_busy       => adc_busy,
      adc_convst     => adc_convst,
      adc_enable     => adc_enable,
      adc_sample     => adc_sample,
      vout           => vout,
      vin            => vin,
      adc_data_ready => adc_data_rdy,
      adc_rdy        => adc_rdy
    );


  synch_i5 : entity work.synch
    generic map(
      size_g => 12
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => vout,
      out_sync => vout_sync_24
    );

  synch_i6 : entity work.synch
    generic map(
      size_g => 12
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      in_async => vout,
      out_sync => vout_sync_fast
    );

  synch_i7 : entity work.synch
    generic map(
      size_g => 12
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      in_async => vin,
      out_sync => vin_sync_fast
    );

  dac_ctrl_i0 : entity work.dac_ctrl
    port map(
      clk      => clk_100,
      reset_n  => reset_n,
      dac_en_i => dac_en_i,
      dac_d_i  => dac_d_i,
      dac_set  => dac_set,
      dac_d_o  => dac_d_o,
      dac_en   => dac_en,
      dac_cs_n => dac_cs_n,
      dac_clk  => dac_clk
    );

  dac_trim_inst : entity work.dac_trim
    port map(
      dac_d      => iref_mux,
      dac_d_trim => dac_d_i
    );

    
  pwm_i0 : entity work.pwm
    generic map(
      counter_size_g => counter_size_g,
      Tclk_g         => counter_tclk_g
    )
    port map(
      clk         => clk_counter,
      reset_n     => reset_n,
      pwm_gen_ena => pwm_gen_ena_sync_fast,
      comp_cur    => comp_cur_sync_fast,
      vout        => vout_sync_fast,
      vin         => vin_sync_fast,
      vref        => vref_mux,
      pwm         => pwm,
      comp_oc     => comp_oc_sync_fast,
      Tsw         => Tsw,
      trim_on     => trim_on,
      trim_off    => trim_off
    );

  pulse_gen_i0 : entity work.pulse_gen
    generic map(
      divider => 30, -- TODO change when controller has changed
      width   => 5
    )
    port map(
      clk     => clk_24,
      reset_n => reset_n,
      pulse   => filter_ena
    );

  synch_i8 : entity work.synch
    generic map(
      size_g => 32
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => a1,
      out_sync => a1_sync_24
    );
  synch_i9 : entity work.synch
    generic map(
      size_g => 32
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => a2,
      out_sync => a2_sync_24
    );
  synch_i10 : entity work.synch
    generic map(
      size_g => 32
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => b0,
      out_sync => b0_sync_24
    );
  synch_i11 : entity work.synch
    generic map(
      size_g => 32
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => b1,
      out_sync => b1_sync_24
    );
  synch_i12 : entity work.synch
    generic map(
      size_g => 32
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async => b2,
      out_sync => b2_sync_24
    );

  voltage_ctrl_i0 : entity work.voltage_ctrl
    port map(
      clk        => clk_24,
      reset_n    => voltage_ctrl_reset_n,
      clk_enable => voltage_ctrl_clk_enable,
      vout       => vout_sync_24,
      vref       => vref,
      a1         => a1,
      a2         => a2,
      b0         => b0,
      b1         => b1,
      b2         => b2,
      ce_out     => open,
      iref       => iref
    );

  synch_i13 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async(0) => v_comp_reset_n,
      out_sync(0) => v_comp_reset_n_sync_24
    );

  synch_i14 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_24,
      reset_n     => reset_n,
      in_async(0) => v_comp_en,
      out_sync(0) => v_comp_en_sync_24
    );
  delay_i0 : entity work.delay
    generic map(
      n_delay => 1,
      width   => 1
    )
    port map(
      clk            => clk_24,
      reset_n        => reset_n,
      sig_in(0)      => filter_ena,
      delayed_out(0) => dac_set_24
    );

  synch_i15 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_100,
      reset_n     => reset_n,
      in_async(0) => dac_set_24,
      out_sync(0) => dac_set_100
    );

  edge_detection_inst : entity work.edge_detection
    port map(
      clk     => clk_100,
      reset_n => reset_n,
      trigger => dac_set_100,
      posedge => dac_set,
      negedge => open
    );
  transient_ctrl_inst : entity work.transient_ctrl
    port map(
      clk           => clk_1,
      reset_n       => reset_n,
      transient_ena => transient_ena_sync_clk1,
      divider       => transient_div_sync_clk1,
      load_sw       => load_sw
    );

  synch_i16 : entity work.synch
    generic map(
      size_g => 1
    )
    port map(
      clk         => clk_1,
      reset_n     => reset_n,
      in_async(0) => transient_ena,
      out_sync(0) => transient_ena_sync_clk1
    );

  synch_i17 : entity work.synch
    generic map(
      size_g => 10
    )
    port map(
      clk      => clk_1,
      reset_n  => reset_n,
      in_async => transient_div,
      out_sync => transient_div_sync_clk1
    );

end architecture;