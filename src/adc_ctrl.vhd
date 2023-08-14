library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity adc_ctrl is
  port (
    clk            : in std_logic;
    reset_n        : in std_logic;
    drp_daddr      : out std_logic_vector(6 downto 0);
    drp_den        : out std_logic;
    drp_di         : out std_logic_vector(15 downto 0);
    drp_do         : in std_logic_vector(15 downto 0);
    drp_drdy       : in std_logic;
    drp_dwe        : out std_logic;
    adc_channel    : in std_logic_vector(4 downto 0);
    adc_eoc        : in std_logic;
    adc_eos        : in std_logic;
    adc_busy       : in std_logic;
    adc_convst     : out std_logic;
    adc_enable     : in std_logic;
    adc_sample     : in std_logic;
    vout           : out std_logic_vector(11 downto 0);
    vin            : out std_logic_vector(11 downto 0);
    adc_data_ready : out std_logic;
    adc_rdy        : out std_logic

  );
end entity adc_ctrl;

architecture rtl of adc_ctrl is

  constant vaux1_addr : std_logic_vector(6 downto 0) := "0010001";
  constant vaux9_addr : std_logic_vector(6 downto 0) := "0011001";

  type adc_state_type is (IDLE_ST, CONVERSION_ST, ADC_READ_RESULT_ST);
  signal adc_state      : adc_state_type;
  signal adc_state_next : adc_state_type;

  type drp_state_type is (idle, init_read_vaux1, init_read_vaux9, read_vaux1_waitrdy, read_vaux9_waitrdy);
  signal drp_state      : drp_state_type;
  signal drp_state_next : drp_state_type;

  signal config_done     : std_logic;
  signal read_adc_result : std_logic;
  signal read_adc_done   : std_logic;

  signal vaux1_wstb : std_logic;
  signal vaux9_wstb : std_logic;
  signal drp_busy   : std_logic;

  signal adc_to_zero : std_logic;
  signal adc_to_cnt  : natural range 0 to 4;

begin

  status_reg : process (reset_n, clk)
  begin
    if (reset_n = '0') then
      adc_state <= IDLE_ST;
      drp_state <= idle;
    elsif (rising_edge(clk)) then
      adc_state <= adc_state_next;
      drp_state <= drp_state_next;
    end if;
  end process; -- status_reg
  adc_fsm : process (adc_state, adc_enable, config_done, adc_sample, adc_eoc, adc_channel)
  begin
    adc_state_next  <= adc_state;
    adc_convst      <= '0';
    read_adc_result <= '0';
    case adc_state is
      when IDLE_ST =>
        if (adc_enable = '1' and adc_sample = '1') then
          adc_state_next <= CONVERSION_ST;
          adc_convst     <= '1';
        end if;
      when CONVERSION_ST =>
        if (adc_eoc = '1') then
          read_adc_result <= '1';
          adc_state_next  <= IDLE_ST;
        end if;
      when others =>
        null;
    end case;
  end process;

  drp_fsm : process (drp_state, read_adc_result, drp_drdy)
  begin

    drp_state_next <= drp_state;
    drp_daddr      <= (others => '0');
    drp_den        <= '0';
    drp_dwe        <= '0';
    drp_di         <= (others => '0');

    drp_busy   <= '0';
    vaux1_wstb <= '0';
    vaux9_wstb <= '0';

    case drp_state is
      when idle =>
        drp_busy <= '0';
        if (read_adc_result = '1') then
          drp_state_next <= init_read_vaux1;
        end if;
      when init_read_vaux1 =>
        if (drp_drdy = '0') then
          drp_daddr      <= vaux1_addr;
          drp_den        <= '1';
          drp_dwe        <= '0'; -- performing read
          drp_state_next <= read_vaux1_waitrdy;
        end if;
      when read_vaux1_waitrdy =>
        if (drp_drdy = '1') then
          vaux1_wstb     <= '1';
          drp_state_next <= init_read_vaux9;
        end if;
      when init_read_vaux9 =>
        if (drp_drdy = '0') then
          drp_daddr      <= vaux9_addr;
          drp_den        <= '1';
          drp_dwe        <= '0'; -- performing read
          drp_state_next <= read_vaux9_waitrdy;
        end if;
      when read_vaux9_waitrdy =>
        if (drp_drdy = '1') then
          vaux9_wstb     <= '1';
          drp_state_next <= idle;
        end if;
      when others =>
        null;
    end case;
  end process;

  vout_reg : process (reset_n, clk)
  begin
    if (reset_n = '0') then
      vout <= (others => '0');
    elsif rising_edge(clk) then
      if (vaux1_wstb = '1') then
        vout <= drp_do(15 downto 4);
      end if;
    end if;
  end process;

  vin_reg : process (reset_n, clk)
  begin
    if (reset_n = '0') then
      vin            <= (others => '0');
      adc_data_ready <= '0';
    elsif rising_edge(clk) then
      if (vaux9_wstb = '1') then
        vin            <= drp_do(15 downto 4);
        adc_data_ready <= '1';
      else
        adc_data_ready <= '0';
      end if;
    end if;
  end process;

  adc_to_p : process (reset_n, clk)
  begin
    if (reset_n = '0') then
    elsif rising_edge(clk) then
      if (adc_busy = '1') then
        adc_to_cnt <= 4;
      elsif (adc_to_cnt > 0) then
        adc_to_cnt <= adc_to_cnt - 1;
      else
        adc_to_cnt <= adc_to_cnt;
      end if;
    end if;
  end process;

  adc_to_zero <= '1' when adc_to_cnt = 0 else '0';
  adc_rdy     <= '1' when (adc_busy = '0' and adc_to_zero = '1') else '0';

end architecture;