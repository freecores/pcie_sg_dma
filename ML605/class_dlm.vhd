----------------------------------------------------------------------------------
-- Company:   ziti
-- Engineer:  wgao
-- 
-- Create Date:    17:01:32 19 Jun 2009
-- Design Name: 
-- Module Name:    class_dlm - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
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

entity class_dlm is
--    Generic (
--             C_PRO_DAQ_WIDTH  :  integer  :=  16 ;
--             C_PRO_DLM_WIDTH  :  integer  :=   4 ;
--             C_PRO_CTL_WIDTH  :  integer  :=  16
--            );
    Port ( 

           -- DLM Tx
           dlm2send_va              : OUT   std_logic;
           dlm2send_type            : OUT   std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               : IN    std_logic;
           dlm_rec_type             : IN    std_logic_vector(4-1 downto 0);

           -- Link side: common signals
           link_tx_clk              : IN    std_logic;
           link_rx_clk              : IN    std_logic;

           -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

           -- Fabric side: DLM Rx
           dlm_tv                   : IN    std_logic;
           dlm_td                   : IN    std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Fabric side: DLM Tx
           dlm_rv                   : OUT   std_logic;
           dlm_rd                   : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Interrupter trigger
           DLM_irq                  : OUT   std_logic;

           -- Fabric side: Common signals
           trn_clk                  : IN    std_logic;
           protocol_rst             : IN    std_logic

          );
end entity class_dlm;


architecture Behavioral of class_dlm is

  -- to synchronize the DLM messages across clock domains
  component v6_afifo_8x8
    port (
          wr_clk  : IN  std_logic;
          din     : IN  std_logic_VECTOR(8-1 downto 0);
          wr_en   : IN  std_logic;
          full    : OUT std_logic;

          rd_clk  : IN  std_logic;
          rd_en   : IN  std_logic;
          dout    : OUT std_logic_VECTOR(8-1 downto 0);
          empty   : OUT std_logic;

          rst     : IN  std_logic
          );
  end component;

  -- Interrupter trigger
  signal  DLM_irq_i             : std_logic;

  -- Fabric side: DLM Tx
  signal  dlm_rv_i              : std_logic;
  signal  dlm_rd_i              : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

  -- protocol side: DLM Send
  signal  dlm2send_va_i         : std_logic;
  signal  dlm2send_type_i       : std_logic_vector(4-1 downto 0);

  signal  dlm_rx_din_padded     : std_logic_vector(8-1 downto 0);
  signal  dlm_rx_dout           : std_logic_vector(8-1 downto 0);
  signal  dlm_rx_empty          : std_logic;
  signal  dlm_rx_empty_r1       : std_logic;
  signal  dlm_rx_full           : std_logic;

  signal  dlm_tx_din_padded     : std_logic_vector(8-1 downto 0);
  signal  dlm_tx_dout           : std_logic_vector(8-1 downto 0);
  signal  dlm_tx_empty          : std_logic;
  signal  dlm_tx_empty_r1       : std_logic;
  signal  dlm_tx_full           : std_logic;


begin

  -- Fabric side: DLM Tx
  dlm_rv             <=  dlm_rv_i         ;
  dlm_rd             <=  dlm_rd_i         ;

  -- protocol side: DLM Send
  dlm2send_va        <=  dlm2send_va_i    ;
  dlm2send_type      <=  dlm2send_type_i  ;

  DLM_irq            <=  DLM_irq_i        ;
  DLM_irq_i          <=  '0';

  -- DLM direction: upstream
  Transfer_DLM_upstream:
  process (trn_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
      dlm_rx_empty_r1 <= '1'           ;
      dlm_rv_i        <= '0'           ;
      dlm_rd_i        <= (OTHERS=>'0') ;
    elsif trn_clk'event and trn_clk = '1' then
      dlm_rx_empty_r1 <= dlm_rx_empty        ;
      dlm_rv_i        <= not dlm_rx_empty_r1 ;
      dlm_rd_i        <= C_ALL_ZEROS(C_DBUS_WIDTH/2-1 downto 4) & dlm_rx_dout(4-1 downto 0)  ;
    end if;
  end process;


  -- DLM direction: downstream
  Transfer_DLM_downstream:
  process (link_tx_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
      dlm_tx_empty_r1     <= '1'           ;
      dlm2send_va_i       <= '0'           ;
      dlm2send_type_i     <= (OTHERS=>'0') ;
    elsif link_tx_clk'event and link_tx_clk = '1' then
      dlm_tx_empty_r1     <= dlm_tx_empty             ;
      dlm2send_va_i       <= not dlm_tx_empty_r1      ;
      dlm2send_type_i     <= dlm_tx_dout(4-1 downto 0);
    end if;
  end process;


  dlm_rx_din_padded  <= X"0" & dlm_rec_type(4-1 downto 0);
  dlm_tx_din_padded  <= X"0" & dlm_td(4-1 downto 0);


  Sync_stage_from_ROC:
  v6_afifo_8x8
  port map (
          wr_clk   =>   link_tx_clk         ,     -- IN  std_logic;
          wr_en    =>   dlm_rec_va          ,     -- IN  std_logic;
          din      =>   dlm_rx_din_padded   ,     -- IN  std_logic_VECTOR(7 downto 0);
          full     =>   dlm_rx_full         ,     -- OUT std_logic;

          rd_clk   =>   trn_clk             ,     -- IN  std_logic;
          rd_en    =>   '1'                 ,     -- IN  std_logic;
          dout     =>   dlm_rx_dout         ,     -- OUT std_logic_VECTOR(7 downto 0);
          empty    =>   dlm_rx_empty        ,     -- OUT std_logic;

          rst      =>   protocol_rst              -- IN  std_logic
          );


  Sync_stage_to_ROC:
  v6_afifo_8x8
  port map (
          wr_clk   =>   trn_clk             ,     -- IN  std_logic;
          wr_en    =>   dlm_tv              ,     -- IN  std_logic;
          din      =>   dlm_tx_din_padded   ,     -- IN  std_logic_VECTOR(7 downto 0);
          full     =>   dlm_tx_full         ,     -- OUT std_logic;

          rd_clk   =>   link_tx_clk         ,     -- IN  std_logic;
          rd_en    =>   '1'                 ,     -- IN  std_logic;
          dout     =>   dlm_tx_dout         ,     -- OUT std_logic_VECTOR(7 downto 0);
          empty    =>   dlm_tx_empty        ,     -- OUT std_logic;

          rst      =>   protocol_rst              -- IN  std_logic
          );                             

end architecture Behavioral;
