----------------------------------------------------------------------------------
-- Company:  ziti, Uni. HD
-- Engineer:  wgao
-- 
-- Create Date:    17:01:32 19 Jun 2009
-- Design Name: 
-- Module Name:    pseudo_protocol_module - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision 1.00 - first release.  20.06.2009
-- 
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
use work.abb64Package.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pseudo_protocol_module is
--    Generic (
--             C_PRO_DAQ_WIDTH  :  integer  :=  16 ;
--             C_PRO_DLM_WIDTH  :  integer  :=   4 ;
--             C_PRO_CTL_WIDTH  :  integer  :=  16
--            );
    Port ( 

           -- DAQ Tx
           data2send_start          : IN    std_logic;
           data2send_end            : IN    std_logic;
           data2send                : IN    std_logic_vector(64-1 downto 0);
           crc_error_send           : IN    std_logic;
           data2send_stop           : OUT   std_logic;

           -- DAQ Rx
           data_rec_start           : OUT   std_logic;
           data_rec_end             : OUT   std_logic;
           data_rec                 : OUT   std_logic_vector(64-1 downto 0);
           crc_error_rec            : OUT   std_logic;
           data_rec_stop            : IN    std_logic;

           -- CTL Tx
           ctrl2send_start          : IN    std_logic;
           ctrl2send_end            : IN    std_logic;
           ctrl2send                : IN    std_logic_vector(16-1 downto 0);
           ctrl2send_stop           : OUT   std_logic;

           -- CTL Rx
           ctrl_rec_start           : OUT   std_logic;
           ctrl_rec_end             : OUT   std_logic;
           ctrl_rec                 : OUT   std_logic_vector(16-1 downto 0);
           ctrl_rec_stop            : IN    std_logic;

           -- DLM Tx
           dlm2send_va              : IN    std_logic;
           dlm2send_type            : IN    std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               : OUT   std_logic;
           dlm_rec_type             : OUT   std_logic_vector(4-1 downto 0);

           -- dummy pin input  !!!! not really exists
           dummy_pin_in             : IN    std_logic_vector(3-1 downto 0);

           -- Common interface
           link_tx_clk              : OUT   std_logic;
           link_rx_clk              : OUT   std_logic;
           link_active              : OUT   std_logic_vector(2-1 downto 0);
           clk                      : IN    std_logic;
           res_n                    : IN    std_logic
          );
end entity pseudo_protocol_module;


architecture Behavioral of pseudo_protocol_module is

  -- DAQ Rx
  signal  data_rec_start_i      : std_logic;
  signal  data_rec_end_i        : std_logic;
  signal  data_rec_i            : std_logic_vector(64-1 downto 0);
  signal  crc_error_rec_i       : std_logic;
  signal  data2send_stop_i      : std_logic;

  -- CTL Rx
  signal  ctrl_rec_start_i      : std_logic;
  signal  ctrl_rec_end_i        : std_logic;
  signal  ctrl_rec_i            : std_logic_vector(16-1 downto 0);
  signal  ctrl2send_stop_i      : std_logic;

  -- DLM Rx
  signal  dlm_rec_va_i          : std_logic;
  signal  dlm_rec_type_i        : std_logic_vector(4-1 downto 0);

  -- Link active latency
  signal  link_act_counter      : std_logic_vector(8-1 downto 0);
  signal  link_active_i         : std_logic_vector(2-1 downto 0);

  -- Dummy pin
  signal  dummy_pin_r1          : std_logic_vector(3-1 downto 0);
  signal  dummy_pin_r2          : std_logic_vector(3-1 downto 0);
  signal  dummy_pin_r3          : std_logic_vector(3-1 downto 0);
  signal  dummy_pin_r4          : std_logic_vector(3-1 downto 0);


begin

  link_tx_clk       <= clk;
  link_rx_clk       <= clk;
  link_active       <= link_active_i;

  data_rec_start    <= data_rec_start_i  ;
  data_rec_end      <= data_rec_end_i    ;
  data_rec          <= data_rec_i        ;
  crc_error_rec     <= crc_error_rec_i   ;
  data2send_stop    <= data2send_stop_i  ;

  ctrl_rec_start    <= ctrl_rec_start_i  ;
  ctrl_rec_end      <= ctrl_rec_end_i    ;
  ctrl_rec          <= ctrl_rec_i        ;
  ctrl2send_stop    <= ctrl2send_stop_i  ;

  dlm_rec_va        <= dlm_rec_va_i      ;
  dlm_rec_type      <= dlm_rec_type_i    ;


  -------------------------------------------
  -- Dummy pin delayed
  -- 
  Synchron_dummy_pin:
  process (clk, res_n )
  begin
    if res_n = '0' then
        dummy_pin_r1     <= (OTHERS=>'0');
        dummy_pin_r2     <= (OTHERS=>'0');
        dummy_pin_r3     <= (OTHERS=>'0');
        dummy_pin_r4     <= (OTHERS=>'0');
    elsif clk'event and clk = '1' then
        dummy_pin_r1     <= dummy_pin_in;
        dummy_pin_r2     <= dummy_pin_r1;
        dummy_pin_r3     <= dummy_pin_r2;
        dummy_pin_r4     <= dummy_pin_r3;
    end if;
  end process;


  -------------------------------------------
  -- Link active coutner up
  -- 
  Synchron_Link_Active:
  process (clk, res_n )
  begin
    if res_n = '0' then
        link_act_counter   <= (OTHERS=>'0');
        link_active_i      <= (OTHERS=>'0');
    elsif clk'event and clk = '1' then
        if link_active_i="11" then
           link_active_i      <= link_active_i;
           link_act_counter   <= link_act_counter;
        elsif link_act_counter=X"ff" then
           link_active_i      <= "11";
           link_act_counter   <= link_act_counter;
        else
           link_active_i      <= link_active_i;
           link_act_counter   <= link_act_counter + '1';
        end if;
    end if;
  end process;


  -------------------------------------------
  -- DAQ transferred over
  -- 
  --  (Data/Event generator can be built here ... ... ... )
  -- 
  Transfer_DAQ:
  process (clk, res_n )
  begin
    if res_n = '0' then
		  data_rec_start_i   <= '0';
        data_rec_end_i     <= '0';
		  data_rec_i         <= (OTHERS=>'0');
		  crc_error_rec_i    <= '0';
		  data2send_stop_i   <= '1';
    elsif clk'event and clk = '1' then
	   if dummy_pin_r1(0)='0' then
		  data_rec_start_i   <= data2send_start;
        data_rec_end_i     <= data2send_end;
		  data_rec_i         <= data2send;
		  crc_error_rec_i    <= crc_error_send;
		  data2send_stop_i   <= data_rec_stop;
		else
		  data_rec_start_i   <= '0';
        data_rec_end_i     <= '0';
		  data_rec_i         <= (OTHERS=>'0');
		  crc_error_rec_i    <= '0';
		  data2send_stop_i   <= '0';
		end if;
    end if;
  end process;


  -------------------------------------------
  -- CTL transferred over
  -- 
  Transfer_CTL:
  process (clk, res_n )
  begin
    if res_n = '0' then
		  ctrl_rec_start_i    <= '0';
		  ctrl_rec_end_i      <= '0';
		  ctrl_rec_i          <= (OTHERS=>'0');
		  ctrl2send_stop_i    <= '1';
    elsif clk'event and clk = '1' then
	   if dummy_pin_r1(2)='0' and dummy_pin_r2(2)='0' and dummy_pin_r3(2)='0' then
		  ctrl_rec_start_i    <= ctrl2send_start;
		  ctrl_rec_end_i      <= ctrl2send_end;
		  ctrl_rec_i          <= ctrl2send;
		  ctrl2send_stop_i    <= ctrl_rec_stop;
	   elsif dummy_pin_r1(2)='1' and dummy_pin_r2(2)='0' and dummy_pin_r3(2)='0' then
		  ctrl_rec_start_i    <= '1';
		  ctrl_rec_end_i      <= '0';
		  ctrl_rec_i          <= (OTHERS=>'1');
		  ctrl2send_stop_i    <= ctrl_rec_stop;
	   elsif dummy_pin_r1(2)='1' and dummy_pin_r2(2)='1' and dummy_pin_r3(2)='0' then
		  ctrl_rec_start_i    <= '0';
		  ctrl_rec_end_i      <= '1';
		  ctrl_rec_i          <= (OTHERS=>'0');
		  ctrl2send_stop_i    <= ctrl_rec_stop;
	   elsif dummy_pin_r1(2)='0' and dummy_pin_r2(2)='1' and dummy_pin_r3(2)='0' then
		  ctrl_rec_start_i    <= '0';
		  ctrl_rec_end_i      <= '1';
		  ctrl_rec_i          <= (OTHERS=>'0');
		  ctrl2send_stop_i    <= ctrl_rec_stop;
		else
		  ctrl_rec_start_i    <= '0';
		  ctrl_rec_end_i      <= '0';
		  ctrl_rec_i          <= (OTHERS=>'0');
		  ctrl2send_stop_i    <= '0';
		end if;
    end if;
  end process;


  -------------------------------------------
  -- DLM transferred over
  -- 
  Transfer_DLM:
  process (clk, res_n )
  begin
    if res_n = '0' then
		  dlm_rec_va_i     <= '0';
		  dlm_rec_type_i   <= (OTHERS=>'0');
    elsif clk'event and clk = '1' then
	   if dummy_pin_r1(1)='0' then
		  dlm_rec_va_i     <= dlm2send_va;
		  dlm_rec_type_i   <= dlm2send_type;
		else
		  dlm_rec_va_i     <= '0';
		  dlm_rec_type_i   <= (OTHERS=>'0');
		end if;
    end if;
  end process;


end architecture Behavioral;
