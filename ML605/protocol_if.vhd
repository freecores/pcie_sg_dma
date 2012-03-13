----------------------------------------------------------------------------------
-- Company:   ziti
-- Engineer:  wgao
-- 
-- Create Date:    17:01:32 19 Jun 2009
-- Design Name: 
-- Module Name:    protocol_IF - Behavioral 
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

entity protocol_IF is
--    Generic (
--             C_PRO_DAQ_WIDTH  :  integer  :=  16 ;
--             C_PRO_DLM_WIDTH  :  integer  :=   4 ;
--             C_PRO_CTL_WIDTH  :  integer  :=  16
--            );
    Port ( 

           -- DAQ Tx
           data2send_start          : OUT   std_logic;
           data2send_end            : OUT   std_logic;
           data2send                : OUT   std_logic_vector(64-1 downto 0);
           crc_error_send           : OUT   std_logic;
           data2send_stop           : IN    std_logic;

           -- DAQ Rx
           data_rec_start           : IN    std_logic;
           data_rec_end             : IN    std_logic;
           data_rec                 : IN    std_logic_vector(64-1 downto 0);
           crc_error_rec            : IN    std_logic;
           data_rec_stop            : OUT   std_logic;

--           -- [dg] DAQ Rx
--           dg_data_rec_start        : IN    std_logic;
--           dg_data_rec_end          : IN    std_logic;
--           dg_data_rec              : IN    std_logic_vector(16-1 downto 0);
--           dg_crc_error_rec         : IN    std_logic;

           -- CTL Tx
           ctrl2send_start          : OUT   std_logic;
           ctrl2send_end            : OUT   std_logic;
           ctrl2send                : OUT   std_logic_vector(16-1 downto 0);
           ctrl2send_stop           : IN    std_logic;

           -- CTL Rx
           ctrl_rec_start           : IN    std_logic;
           ctrl_rec_end             : IN    std_logic;
           ctrl_rec                 : IN    std_logic_vector(16-1 downto 0);
           ctrl_rec_stop            : OUT   std_logic;

--           -- [dg] CTL Rx
--           dg_ctrl_rec_start        : IN    std_logic;
--           dg_ctrl_rec_end          : IN    std_logic;
--           dg_ctrl_rec              : IN    std_logic_vector(16-1 downto 0);

           -- DLM Tx
           dlm2send_va              : OUT   std_logic;
           dlm2send_type            : OUT   std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               : IN    std_logic;
           dlm_rec_type             : IN    std_logic_vector(4-1 downto 0);

--           -- [dg] DLM Rx
--           dg_dlm_rec_va            : IN    std_logic;
--           dg_dlm_rec_type          : IN    std_logic_vector(4-1 downto 0);

           -- Common signals
           link_tx_clk              : IN    std_logic;
           link_rx_clk              : IN    std_logic;
           link_active              : IN    std_logic_vector(2-1 downto 0);
           protocol_clk             : OUT   std_logic;
           protocol_res_n           : OUT   std_logic;

           -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

           -- Fabric side: DAQ Rx
           daq_rv                   : IN    std_logic;
           daq_rsof                 : IN    std_logic;
           daq_reof                 : IN    std_logic;
           daq_rd                   : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           daq_rstop                : OUT   std_logic;

           -- Fabric side: DAQ Tx
           daq_tv                   : OUT   std_logic;
           daq_tsof                 : OUT   std_logic;
           daq_teof                 : OUT   std_logic;
           daq_td                   : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           daq_tstop                : IN    std_logic;

           -- Fabric side: CTL Rx
           ctl_rv                   : IN    std_logic;
           ctl_rd                   : IN    std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           ctl_rstop                : OUT   std_logic;

           -- Fabric side: CTL Tx
           ctl_ttake                : IN    std_logic;
           ctl_tv                   : OUT   std_logic;
           ctl_td                   : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           ctl_tstop                : IN    std_logic;

           ctl_reset                : IN    std_logic;
           ctl_status               : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Fabric side: DLM Tx
           dlm_tv                   : IN    std_logic;
           dlm_td                   : IN    std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Fabric side: DLM Rx
           dlm_rv                   : OUT   std_logic;
           dlm_rd                   : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Interrupter triggers
           DAQ_irq                  : OUT   std_logic;
           CTL_irq                  : OUT   std_logic;
           DLM_irq                  : OUT   std_logic;

           -- Data generator table write port
           tab_sel                  : IN    STD_LOGIC;
           tab_we                   : IN    STD_LOGIC_VECTOR (2-1 downto 0);
           tab_wa                   : IN    STD_LOGIC_VECTOR (12-1 downto 0);
           tab_wd                   : IN    STD_LOGIC_VECTOR (64-1 downto 0);

           -- DG control/status signal
           dg_running               : OUT   STD_LOGIC;
           dg_mask                  : IN    STD_LOGIC;
           dg_rst                   : IN    STD_LOGIC;

           -- DG debug signal
           daq_start_led            : OUT   STD_LOGIC;

           -- Fabric side: Common signals
           trn_clk                  : IN    std_logic;
           protocol_link_act        : OUT   std_logic_vector(2-1 downto 0);
           protocol_rst             : IN    std_logic

          );
end entity protocol_IF;


architecture Behavioral of protocol_IF is

   -- Data generator
   COMPONENT abb_dgen
   PORT (
           -- Data generator table write port
           tab_sel            : IN    STD_LOGIC;
           tab_we             : IN    STD_LOGIC_VECTOR (2-1 downto 0);
           tab_wa             : IN    STD_LOGIC_VECTOR (12-1 downto 0);
           tab_wd             : IN    STD_LOGIC_VECTOR (64-1 downto 0);


           -- DAQ Rx
           data_rec_start     : OUT   std_logic;
           data_rec_end       : OUT   std_logic;
           data_rec           : OUT   std_logic_vector(64-1 downto 0);
           crc_error_rec      : OUT   std_logic;
           data_rec_stop      : IN    std_logic;

           -- CTL Rx
           ctrl_rec_start     : OUT   std_logic;
           ctrl_rec_end       : OUT   std_logic;
           ctrl_rec           : OUT   std_logic_vector(16-1 downto 0);
           ctrl_rec_stop      : IN    std_logic;

           -- DLM Rx
           dlm_rec_va         : OUT   std_logic;
           dlm_rec_type       : OUT   std_logic_vector(4-1 downto 0);

           -- status signal
           dg_running         : OUT   STD_LOGIC;
           daq_start_led      : OUT   STD_LOGIC;

           -- must signals
           dg_clk             : IN    STD_LOGIC;
           dg_mask            : IN    STD_LOGIC;
           dg_rst             : IN    STD_LOGIC
           );
   END COMPONENT;


   COMPONENT class_daq
   PORT(
        -- DAQ Tx
        data2send_start          : OUT   std_logic;
        data2send_end            : OUT   std_logic;
        data2send                : OUT   std_logic_vector(64-1 downto 0);
        crc_error_send           : OUT   std_logic;
        data2send_stop           : IN    std_logic;

        -- DAQ Rx
        data_rec_start           : IN    std_logic;
        data_rec_end             : IN    std_logic;
        data_rec                 : IN    std_logic_vector(64-1 downto 0);
        crc_error_rec            : IN    std_logic;
        data_rec_stop            : OUT   std_logic;

        -- Common signals
        link_tx_clk              : IN    std_logic;
        link_rx_clk              : IN    std_logic;


        -- Fabric side: DAQ Rx
        daq_rv                   : IN    std_logic;
        daq_rsof                 : IN    std_logic;
        daq_reof                 : IN    std_logic;
        daq_rd                   : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        daq_rstop                : OUT   std_logic;

        -- Fabric side: DAQ Tx
        daq_tv                   : OUT   std_logic;
        daq_tsof                 : OUT   std_logic;
        daq_teof                 : OUT   std_logic;
        daq_td                   : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        daq_tstop                : IN    std_logic;

        -- Interrupter trigger
        DAQ_irq                  : OUT   std_logic;

        -- Fabric side: Common signals
        trn_clk                  : IN    std_logic;
        protocol_rst             : IN    std_logic
       );
   END COMPONENT;

   COMPONENT class_ctl
   PORT(
        -- CTL Tx
        ctrl2send_start          : OUT   std_logic;
        ctrl2send_end            : OUT   std_logic;
        ctrl2send                : OUT   std_logic_vector(16-1 downto 0);
        ctrl2send_stop           : IN    std_logic;

        -- CTL Rx
        ctrl_rec_start           : IN    std_logic;
        ctrl_rec_end             : IN    std_logic;
        ctrl_rec                 : IN    std_logic_vector(16-1 downto 0);
        ctrl_rec_stop            : OUT   std_logic;

        -- Common signals
        link_active              : IN    std_logic_vector(2-1 downto 0);
        link_tx_clk              : IN    std_logic;
        link_rx_clk              : IN    std_logic;


        -- Fabric side: CTL Rx
        ctl_rv                   : IN    std_logic;
        ctl_rd                   : IN    std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        ctl_rstop                : OUT   std_logic;

        -- Fabric side: CTL Tx
        ctl_ttake                : IN    std_logic;
        ctl_tv                   : OUT   std_logic;
        ctl_td                   : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        ctl_tstop                : IN    std_logic;

        -- Interrupter trigger
        CTL_irq                  : OUT   std_logic;
        ctl_status               : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- Fabric side: Common signals
        trn_clk                  : IN    std_logic;
        protocol_rst             : IN    std_logic
		);
   END COMPONENT;

   COMPONENT class_dlm
   PORT(
        -- DLM Tx
        dlm2send_va              : OUT   std_logic;
        dlm2send_type            : OUT   std_logic_vector(4-1 downto 0);

        -- DLM Rx
        dlm_rec_va               : IN    std_logic;
        dlm_rec_type             : IN    std_logic_vector(4-1 downto 0);

        -- Common signals
        link_tx_clk              : IN    std_logic;
        link_rx_clk              : IN    std_logic;


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
   END COMPONENT;

   -- Protocol module reset
   signal  protocol_link_act_i   : std_logic_vector(2-1 downto 0);

   -- Flow control signals
   signal  data_rec_stop_i       : std_logic;
   signal  ctrl_rec_stop_i       : std_logic;


   -- DAQ Tx
   signal  data2send_start_i     : std_logic;
   signal  data2send_end_i       : std_logic;
   signal  data2send_i           : std_logic_vector(64-1 downto 0);
   signal  crc_error_send_i      : std_logic;
   signal  data2send_stop_i      : std_logic;

   -- CTL Tx
   signal  ctrl2send_start_i     : std_logic;
   signal  ctrl2send_end_i       : std_logic;
   signal  ctrl2send_i           : std_logic_vector(16-1 downto 0);
   signal  ctrl2send_stop_i      : std_logic;

   -- DLM Tx
   signal  dlm2send_va_i         : std_logic;
   signal  dlm2send_type_i       : std_logic_vector(4-1 downto 0);

   -- [dg] DAQ Rx
   signal  dg_data_rec_start     : std_logic;
   signal  dg_data_rec_end       : std_logic;
   signal  dg_data_rec           : std_logic_vector(64-1 downto 0);
   signal  dg_crc_error_rec      : std_logic;

   -- [dg] CTL Rx
   signal  dg_ctrl_rec_start     : std_logic;
   signal  dg_ctrl_rec_end       : std_logic;
   signal  dg_ctrl_rec           : std_logic_vector(16-1 downto 0);

   -- [dg] DLM Rx
   signal  dg_dlm_rec_va         : std_logic;
   signal  dg_dlm_rec_type       : std_logic_vector(4-1 downto 0);

   -- DAQ Rx wire
   signal  data_rec_start_i      : std_logic;
   signal  data_rec_end_i        : std_logic;
   signal  data_rec_i            : std_logic_vector(64-1 downto 0);
   signal  crc_error_rec_i       : std_logic;

   -- CTL Rx wire
   signal  ctrl_rec_start_i      : std_logic;
   signal  ctrl_rec_end_i        : std_logic;
   signal  ctrl_rec_i            : std_logic_vector(16-1 downto 0);

   -- DLM Rx wire
   signal  dlm_rec_va_i          : std_logic;
   signal  dlm_rec_type_i        : std_logic_vector(4-1 downto 0);


begin

   protocol_clk       <= trn_clk;
   protocol_res_n     <= not protocol_rst;
   protocol_link_act  <= protocol_link_act_i;

   data2send_start    <= (data2send_start_i or dg_data_rec_start);
   data2send_end      <= (data2send_end_i   or dg_data_rec_end  );
   data2send          <= (data2send_i       or dg_data_rec      );
   crc_error_send     <= (crc_error_send_i  or dg_crc_error_rec );
   data2send_stop_i   <= data2send_stop  ;

   data_rec_start_i   <= data_rec_start  ; 
   data_rec_end_i     <= data_rec_end    ; 
   data_rec_i         <= data_rec        ; 
   crc_error_rec_i    <= crc_error_rec   ; 
   data_rec_stop      <= data_rec_stop_i;

   ctrl2send_start    <= (ctrl2send_start_i or dg_ctrl_rec_start  );
   ctrl2send_end      <= (ctrl2send_end_i   or dg_ctrl_rec_end    );
   ctrl2send          <= (ctrl2send_i       or dg_ctrl_rec        );
   ctrl2send_stop_i   <= ctrl2send_stop ;

   ctrl_rec_start_i   <= ctrl_rec_start ;
   ctrl_rec_end_i     <= ctrl_rec_end   ;
   ctrl_rec_i         <= ctrl_rec       ;
   ctrl_rec_stop      <= ctrl_rec_stop_i;

   dlm2send_va        <= (dlm2send_va_i    or dg_dlm_rec_va    );
   dlm2send_type      <= (dlm2send_type_i  or dg_dlm_rec_type  );

   dlm_rec_va_i       <= dlm_rec_va   ;
   dlm_rec_type_i     <= dlm_rec_type ;


   -- Protocol link active signal register
   Synch_protocol_link_act:
   process (trn_clk )
   begin
     if trn_clk'event and trn_clk = '1' then
       protocol_link_act_i <= link_active;
     end if;
   end process;


   -- Data generator implementation
   Gen_DataGen: if IMP_DATA_GENERATOR generate

   data_generator_0:
   abb_dgen
     port map (
          -- Data generator table write port
          tab_sel           =>  '1'               ,  -- IN    STD_LOGIC;
          tab_we            =>  tab_we            ,  -- IN    STD_LOGIC_VECTOR (8-1 downto 0);
          tab_wa            =>  tab_wa            ,  -- IN    STD_LOGIC_VECTOR (12-1 downto 0);
          tab_wd            =>  tab_wd            ,  -- IN    STD_LOGIC_VECTOR (64-1 downto 0);

          -- DAQ Rx
          data_rec_start    =>  dg_data_rec_start ,  -- OUT   std_logic;
          data_rec_end      =>  dg_data_rec_end   ,  -- OUT   std_logic;
          data_rec          =>  dg_data_rec       ,  -- OUT   std_logic_vector(16-1 downto 0);
          crc_error_rec     =>  dg_crc_error_rec  ,  -- OUT   std_logic;
          data_rec_stop     =>  data_rec_stop_i   ,  -- IN    std_logic;

          -- CTL Rx
          ctrl_rec_start    =>  dg_ctrl_rec_start ,  -- OUT   std_logic;
          ctrl_rec_end      =>  dg_ctrl_rec_end   ,  -- OUT   std_logic;
          ctrl_rec          =>  dg_ctrl_rec       ,  -- OUT   std_logic_vector(16-1 downto 0);
          ctrl_rec_stop     =>  ctrl_rec_stop_i   ,  -- IN    std_logic;

          -- DLM Rx
          dlm_rec_va        =>  dg_dlm_rec_va     ,  -- OUT   std_logic;
          dlm_rec_type      =>  dg_dlm_rec_type   ,  -- OUT   std_logic_vector(4-1 downto 0);

          -- status signals
          dg_running        =>  dg_running        ,  -- OUT   STD_LOGIC;
          daq_start_led     =>  daq_start_led     ,  -- OUT   STD_LOGIC;

          -- common signals
          dg_clk            =>  trn_clk           ,  -- IN    STD_LOGIC;
          dg_mask           =>  dg_mask           ,  -- IN    STD_LOGIC;
          dg_rst            =>  dg_rst               -- IN    STD_LOGIC
          );

   end generate;


   -- No data generator implementation
   NotGen_DataGen: if not IMP_DATA_GENERATOR generate

          -- debug signal
          daq_start_led        <=  '0';

          -- DAQ Rx
          dg_data_rec_start    <=  '0';
          dg_data_rec_end      <=  '0';
          dg_data_rec          <=  (OTHERS=>'0');
          dg_crc_error_rec     <=  '0';

          -- CTL Rx
          dg_ctrl_rec_start    <=  '0';
          dg_ctrl_rec_end      <=  '0';
          dg_ctrl_rec          <=  (OTHERS=>'0');

          -- DLM Rx
          dg_dlm_rec_va        <=  '0';
          dg_dlm_rec_type      <=  (OTHERS=>'0');

   end generate;



   module_class_daq:
   class_daq
   PORT MAP(
      -- DAQ Tx
      data2send_start          => data2send_start_i ,  -- OUT   std_logic;
      data2send_end            => data2send_end_i   ,  -- OUT   std_logic;
      data2send                => data2send_i       ,  -- OUT   std_logic_vector(16-1 downto 0);
      crc_error_send           => crc_error_send_i  ,  -- OUT   std_logic;
      data2send_stop           => data2send_stop_i  ,  -- IN    std_logic;

      -- DAQ Rx
      data_rec_start           => data_rec_start_i    ,  -- IN    std_logic;
      data_rec_end             => data_rec_end_i      ,  -- IN    std_logic;
      data_rec                 => data_rec_i          ,  -- IN    std_logic_vector(16-1 downto 0);
      crc_error_rec            => crc_error_rec_i     ,  -- IN    std_logic;
      data_rec_stop            => data_rec_stop_i     ,  -- OUT   std_logic;

      -- Common signals
      link_tx_clk              => link_tx_clk        ,  -- IN    std_logic;
      link_rx_clk              => link_tx_clk        ,  -- IN    std_logic;


      -- Fabric side - DAQ Rx
      daq_rv                   => daq_rv          ,  -- IN    std_logic;
      daq_rsof                 => daq_rsof        ,  -- IN    std_logic;
      daq_reof                 => daq_reof        ,  -- IN    std_logic;
      daq_rd                   => daq_rd          ,  -- IN    std_logic_vector(64-1 downto 0);
      daq_rstop                => daq_rstop       ,  -- OUT   std_logic;

      -- Fabric side - DAQ Tx
      daq_tv                   => daq_tv          ,  -- OUT   std_logic;
      daq_tsof                 => daq_tsof        ,  -- OUT   std_logic;
      daq_teof                 => daq_teof        ,  -- OUT   std_logic;
      daq_td                   => daq_td          ,  -- OUT   std_logic_vector(64-1 downto 0);
      daq_tstop                => daq_tstop       ,  -- IN    std_logic;

      -- Interrupter trigger
      DAQ_irq                  => DAQ_irq         ,  -- OUT   std_logic;

      -- Fabric side - Common signals
      trn_clk                  => trn_clk         ,  -- IN    std_logic;
      protocol_rst             => protocol_rst       -- IN    std_logic
   );



   module_class_ctl:
   class_ctl
   PORT MAP(
      -- CTL Tx
      ctrl2send_start          => ctrl2send_start_i   ,  -- OUT   std_logic;
      ctrl2send_end            => ctrl2send_end_i     ,  -- OUT   std_logic;
      ctrl2send                => ctrl2send_i         ,  -- OUT   std_logic_vector(32-1 downto 0);
      ctrl2send_stop           => ctrl2send_stop_i    ,  -- IN    std_logic;

      -- CTL Rx
      ctrl_rec_start           => ctrl_rec_start_i     ,  -- IN    std_logic;
      ctrl_rec_end             => ctrl_rec_end_i       ,  -- IN    std_logic;
      ctrl_rec                 => ctrl_rec_i           ,  -- IN    std_logic_vector(32-1 downto 0);
      ctrl_rec_stop            => ctrl_rec_stop_i      ,  -- OUT   std_logic;

      -- Common signals
      link_active              => link_active          ,  -- IN    std_logic_vector(2-1 downto 0);
      link_tx_clk              => link_tx_clk          ,  -- IN    std_logic;
      link_rx_clk              => link_tx_clk          ,  -- IN    std_logic;


      -- Fabric side - CTL Rx
      ctl_rv                   => ctl_rv           ,  -- IN    std_logic;
      ctl_rd                   => ctl_rd           ,  -- IN    std_logic_vector(32-1 downto 0);
      ctl_rstop                => ctl_rstop        ,  -- OUT   std_logic;

      -- Fabric side - CTL Tx
      ctl_ttake                => ctl_ttake        ,  -- IN    std_logic;
      ctl_tv                   => ctl_tv           ,  -- OUT   std_logic;
      ctl_td                   => ctl_td           ,  -- OUT   std_logic_vector(32-1 downto 0);
      ctl_tstop                => ctl_tstop        ,  -- IN    std_logic;

      -- Interrupter trigger
      CTL_irq                  => CTL_irq          ,  -- OUT   std_logic;
      ctl_status               => ctl_status       ,  -- OUT   std_logic_vector(32-1 downto 0);

      -- Fabric side - Common signals
      trn_clk                  => trn_clk          ,  -- IN    std_logic;
      protocol_rst             => ctl_reset           -- IN    std_logic

   );


   module_class_dlm:
   class_dlm
   PORT MAP(
      -- DLM Tx
      dlm2send_va              => dlm2send_va_i     ,  -- OUT   std_logic;
      dlm2send_type            => dlm2send_type_i   ,  -- OUT   std_logic_vector(4-1 downto 0);

      -- DLM Rx
      dlm_rec_va               => dlm_rec_va_i       ,  -- IN    std_logic;
      dlm_rec_type             => dlm_rec_type_i     ,  -- IN    std_logic_vector(4-1 downto 0);

      -- Common signals
      link_tx_clk              => link_tx_clk        ,  -- IN    std_logic;
      link_rx_clk              => link_tx_clk        ,  -- IN    std_logic;


      -- Fabric side - DLM Tx
      dlm_tv                   => dlm_tv          ,  -- IN    std_logic;
      dlm_td                   => dlm_td          ,  -- IN    std_logic_vector(4-1 downto 0);

      -- Fabric side - DLM Rx
      dlm_rv                   => dlm_rv          ,  -- OUT   std_logic;
      dlm_rd                   => dlm_rd          ,  -- OUT   std_logic_vector(4-1 downto 0);

      -- Interrupter trigger
      DLM_irq                  => DLM_irq         ,  -- OUT   std_logic;

      -- Fabric side - Common signals
      trn_clk                  => trn_clk         ,  -- IN    std_logic;
      protocol_rst             => protocol_rst       -- IN    std_logic

   );


end architecture Behavioral;
