library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
entity facm_eval is
  generic (
    counter_size_g : natural                       := 10;
    counter_tclk_g : std_logic_vector(11 downto 0) := x"355" -- ufix12_En8
  );

  port
  (
    clk_100     : in std_logic;
    clk_counter : in std_logic;
    reset_n     : in std_logic;

    comp_cur_async : in std_logic;
    comp_oc_async  : in std_logic;

    pwm : out std_logic;

    -- DAC signals
    dac_d_i    : in std_logic_vector(9 downto 0); --! data out to dac
    dac_en_i   : in std_logic; --! dac enable signal
    pwm_gen_en : in std_logic;

    dac_d_o  : out std_logic_vector(9 downto 0); --! data out to dac
    dac_en   : out std_logic; --! dac enable signal
    dac_cs_n : out std_logic; --! dac chip select signal active low
    dac_clk  : out std_logic; --! clock signals at which signals to dac are sampled if dac_cs_n is low

    led0 : out std_logic;
    led1 : out std_logic;
    led2 : out std_logic;
    led3 : out std_logic;

    pmoda : out std_logic_vector(7 downto 0);
    pmodb : out std_logic_vector(7 downto 0);

    trim_on : in std_logic_vector(7 downto 0);
    trim_off : in std_logic_vector(7 downto 0)

  );
end entity facm_eval;
architecture rtl of facm_eval is

  signal pwm_gen_ena_sync_fast : std_logic;
  signal comp_cur_sync_fast    : std_logic;
  signal comp_oc_sync_fast     : std_logic;
  signal dac_en_s : std_logic;
  signal dac_clk_s : std_logic;
  signal dac_d_o_s : std_logic_vector(9 downto 0);
begin

    dac_en <= dac_en_s;
    dac_clk <= dac_clk_s;
    dac_d_o <= dac_d_o_s;

  led0 <= dac_en_i;
  led1 <= pwm_gen_ena_sync_fast;
  led2 <= dac_en_s;
  led3 <= '0';

  pmoda(0) <= dac_clk_s;

  pmodb <= dac_d_o_s(9 downto 2);

  dac_ctrl_i0 : entity work.dac_ctrl
    port map(
      clk      => clk_100,
      reset_n  => reset_n,
      dac_en_i => dac_en_i,
      dac_d_i  => dac_d_i,
      dac_set  => '1',
      dac_d_o  => dac_d_o,
      dac_en   => dac_en,
      dac_cs_n => dac_cs_n,
      dac_clk  => dac_clk
    );

  pwm_i0 : entity work.pwm
    generic
    map(
    counter_size_g => counter_size_g,
    Tclk_g         => counter_tclk_g
    )
    port
    map(
    clk         => clk_counter,
    reset_n     => reset_n,
    pwm_gen_ena => pwm_gen_ena_sync_fast,
    comp_cur    => comp_cur_sync_fast,
    vout        => x"ed5",
    vin         => x"ba0",
    vref        => x"988",
    pwm         => pwm,
    comp_oc     => comp_oc_sync_fast,
    Tsw         => x"9c4",
    trim_on     => trim_on,
    trim_off    => trim_off
    );

  synch_i0 : entity work.synch
    generic
    map(
    size_g => 1
    )
    port
    map(
    clk         => clk_counter,
    reset_n     => reset_n,
    in_async(0) => comp_cur_async,
    out_sync(0) => comp_cur_sync_fast
    );

  synch_i1 : entity work.synch
    generic
    map(
    size_g => 1
    )
    port
    map(
    clk         => clk_counter,
    reset_n     => reset_n,
    in_async(0) => comp_oc_async,
    out_sync(0) => comp_oc_sync_fast
    );

  synch_i4 : entity work.synch
    generic
    map(
    size_g => 1
    )
    port
    map(
    clk         => clk_counter,
    reset_n     => reset_n,
    in_async(0) => pwm_gen_en,
    out_sync(0) => pwm_gen_ena_sync_fast
    );

end architecture;