----------------------------------------------------------------------------------
-- Company:  ziti, Uni. HD
-- Engineer:  wgao
-- 
-- Create Date:    17:01:32 19 Jun 2009
-- Design Name: 
-- Module Name:    class_ctl - Behavioral 
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

entity class_ctl is
--    Generic (
--             C_PRO_DAQ_WIDTH  :  integer  :=  16 ;
--             C_PRO_DLM_WIDTH  :  integer  :=   4 ;
--             C_PRO_CTL_WIDTH  :  integer  :=  16
--            );
    Port ( 

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

           -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

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
end entity class_ctl;


architecture Behavioral of class_ctl is

  -- Standard synchronous FIFO
  component sfifo_256x36
    port (
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(36-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(36-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          clk       : IN  std_logic;
          rst       : IN  std_logic
          );
  end component;

  -- Standard asynchronous FIFO
  component afifo_256x36
    port (
          wr_clk    : IN  std_logic;
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(36-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_clk    : IN  std_logic;
          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(36-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          rst       : IN  std_logic
          );
  end component;

  -- FWFT synchronous FIFO
  component sfifo_256x36c_fwft
    port (
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(36-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(36-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          data_count: OUT std_logic_vector (9-1 downto 0);

          clk       : IN  std_logic;
          rst       : IN  std_logic
          );
  end component;

  -- FWFT asynchronous FIFO
  component afifo_256x36c_fwft
    port (
          wr_clk        : IN  std_logic;
          wr_en         : IN  std_logic;
          din           : IN  std_logic_VECTOR(36-1 downto 0);
          prog_full     : OUT std_logic;
          full          : OUT std_logic;

          rd_clk        : IN  std_logic;
          rd_en         : IN  std_logic;
          dout          : OUT std_logic_VECTOR(36-1 downto 0);
          empty         : OUT std_logic;
          prog_empty    : OUT std_logic;

          rd_data_count : OUT std_logic_vector (9-1 downto 0);

          rst       : IN  std_logic
          );
  end component;

  -- Packet counter
  component pkt_counter_1024
  port (
        wr_clk      : IN  std_logic;
        wr_en       : IN  std_logic;
        din         : IN  std_logic_VECTOR(0 downto 0);
        prog_full   : OUT std_logic;
        full        : OUT std_logic;

        rd_clk      : IN  std_logic;
        rd_en       : IN  std_logic;
        dout        : OUT std_logic_VECTOR(0 downto 0);
        empty       : OUT std_logic;
        prog_empty  : OUT std_logic;

        rst         : IN  std_logic
        );
  end component;

  -- Interrupter trigger
  signal  ctl_reset                : std_logic;
  signal  CTL_irq_i                : std_logic;
  signal  ctl_status_i             : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

  -- Fabric side: CTL Tx       
  signal  ctl_tv_i                 : std_logic;
  signal  ctl_td_i                 : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
  signal  ctl_rstop_i              : std_logic;

  -- protocol side: CTL Send   
  signal  ctrl2send_start_i        : std_logic;
  signal  ctrl2send_end_i          : std_logic;
  signal  ctrl2send_i              : std_logic_vector(16-1 downto 0);
  signal  ctrl_rec_stop_i          : std_logic;

  signal  ctl_down_buf_rden        : std_logic;
  signal  ctl_down_buf_dout        : std_logic_vector(36-1 downto 0);
  signal  ctl_down_buf_empty       : std_logic;
  signal  ctl_down_buf_afull       : std_logic;

  signal  ctl_rd_padded            : std_logic_vector(36-1 downto 0);
  signal  ctl_down_buf_rd_valid    : std_logic :='0';
  signal  ctl_down_buf_read_gap    : std_logic;
  signal  ctl_down_buf_eop         : std_logic;
  signal  ctl_down_buf_eop_r1      : std_logic :='0';

  signal  ctrl2send_stop_r1        : std_logic :='0';
  signal  ctl_down_buf_frame_rd    : std_logic :='0';
  signal  ctl_down_buf_stop_read   : std_logic;
  signal  pc_ctl_down_push         : std_logic;
  signal  pc_ctl_down_pop          : std_logic;
  signal  no_pkts_in_ctl_down_buf  : std_logic;
  signal  no_pkts_in_ctl_down_buf_r1: std_logic :='0';

  signal  ctl_up_buf_wren          : std_logic;
  signal  ctl_up_buf_din           : std_logic_vector(36-1 downto 0);
  signal  ctl_up_buf_din_b1        : std_logic_vector(36-1 downto 0);
  signal  ctl_up_buf_afull         : std_logic;

  signal  ctl_up_buf_re            : std_logic;
  signal  ctl_up_buf_dout          : std_logic_vector(36-1 downto 0);
  signal  ctl_up_buf_empty         : std_logic;
  signal  ctl_up_buf_dc_wire       : std_logic_vector (9-1 downto 0);
  signal  ctl_up_buf_dc_r1         : std_logic_vector (9-1 downto 0);
  signal  ctl_up_buf_dc_plus_r1    : std_logic_vector (9-1 downto 0);
  signal  ctl_up_buf_dc_i          : std_logic_vector (9-1 downto 0);
  signal  ctl_up_is_writing        : std_logic;
  signal  ctl_up_is_writing_r1     : std_logic;

  signal  ctl_up_buf_rd_valid      : std_logic;
  signal  pc_ctl_up_push           : std_logic;
  signal  pc_ctl_up_pop            : std_logic;
  signal  no_pkts_in_ctl_up_buf    : std_logic;
  signal  no_pkts_in_ctl_up_buf_r1 : std_logic;

begin


  -- Fabric side: CTL Tx
  ctl_tv             <=  ctl_tv_i      ;
  ctl_td             <=  ctl_td_i      ;

  ctl_rstop          <=  ctl_rstop_i   ;


  -- protocol side: CTL Send
  ctrl2send_start    <=  ctrl2send_start_i  ;
  ctrl2send_end      <=  ctrl2send_end_i    ;
  ctrl2send          <=  ctrl2send_i        ;

  ctrl_rec_stop      <=  ctrl_rec_stop_i    ;
  ctrl_rec_stop_i    <=  ctl_up_buf_afull;

  ctl_rstop_i        <=  ctl_down_buf_afull;

  ctl_status         <=  ctl_status_i       ;

  CTL_irq            <=  CTL_irq_i          ;
  CTL_irq_i          <=  not ctl_up_buf_empty   ;

  ctl_status_i       <=  X"000" & '0' & '0' & ctl_down_buf_afull & ctl_up_buf_empty
                     &   X"0" & '0' & '0' & ctl_up_buf_dc_i & no_pkts_in_ctl_up_buf_r1;


  -- ------------------------------------------------------------------------------
  -- 
  -- ------------------------------------------------------------------------------
  Synch_Local_Reset:
  process (trn_clk )
  begin
    if trn_clk'event and trn_clk = '1' then
      ctl_reset       <= protocol_rst;
    end if;
  end process;

  -- ------------------------------------------------------------------------------
  --   CTL buffer from the host
  -- ------------------------------------------------------------------------------
  ctl_buf_downstream:
  afifo_256x36
  port map (
            wr_clk     => trn_clk            ,  -- IN  std_logic;
            wr_en      => ctl_rv             ,  -- IN  std_logic;
            din        => ctl_rd_padded      ,  -- IN  std_logic_VECTOR(35 downto 0);
            prog_full  => ctl_down_buf_afull ,  -- ctl_rstop_i        ,  -- OUT std_logic;
            full       => open               ,  -- OUT std_logic;

            rd_clk     => link_tx_clk        ,  -- IN  std_logic;
            rd_en      => ctl_down_buf_rden  ,  -- IN  std_logic;
            dout       => ctl_down_buf_dout  ,  -- OUT std_logic_VECTOR(35 downto 0);
            prog_empty => open               ,  -- OUT std_logic;
            empty      => ctl_down_buf_empty ,  -- OUT std_logic;

            rst        => ctl_reset             -- IN  std_logic
           );

  ctl_rd_padded           <= "0000" & ctl_rd;
  ctl_down_buf_eop        <= ctl_down_buf_dout(16);
  ctl_down_buf_read_gap   <= ctl_down_buf_eop and not ctl_down_buf_eop_r1;
  ctl_down_buf_rden       <= ctl_down_buf_frame_rd and not ctl_down_buf_read_gap;


  -- Packet counter: ABB -> ROC
  pc_ctl_buf_downstream:
  pkt_counter_1024
  port map (
        wr_clk      => trn_clk           , -- IN  std_logic;
        wr_en       => pc_ctl_down_push  , -- IN  std_logic;
        din         => "1"               , -- IN  std_logic_VECTOR(0 downto 0);
        prog_full   => open              , -- OUT std_logic;
        full        => open              , -- OUT std_logic;

        rd_clk      => link_tx_clk       , -- IN  std_logic;
        rd_en       => pc_ctl_down_pop   , -- IN  std_logic;
        dout        => open              , -- OUT std_logic_VECTOR(0 downto 0);
        empty       => no_pkts_in_ctl_down_buf  , -- OUT std_logic;
        prog_empty  => open              , -- OUT std_logic;

        rst         => ctl_reset           -- IN  std_logic
        );


  Syn_pc_ctl_down_push:
  process (trn_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      pc_ctl_down_push  <= '0';
    elsif trn_clk'event and trn_clk = '1' then
      pc_ctl_down_push  <= ctl_rv and ctl_rd(16);
    end if;
  end process;

  Syn_pc_ctl_down_pop:
  process (link_tx_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      pc_ctl_down_pop   <= '0';
    elsif link_tx_clk'event and link_tx_clk = '1' then
      pc_ctl_down_pop   <= ctl_down_buf_rd_valid and ctl_down_buf_eop;
    end if;
  end process;

  ---------------------------------------------------
  -- Downstream CTL buffer read and packets number
  --  bit[17] : sof
  --  bit[16] : eof
  -- 
  Delay_CTL_downstream_frame:
  process (link_tx_clk )
  begin
    if link_tx_clk'event and link_tx_clk = '1' then

        no_pkts_in_ctl_down_buf_r1 <= no_pkts_in_ctl_down_buf;
        ctrl2send_stop_r1        <= ctrl2send_stop;
        ctl_down_buf_rd_valid    <= ctl_down_buf_rden and not ctl_down_buf_empty;
        ctl_down_buf_eop_r1      <= ctl_down_buf_eop;
        ctl_down_buf_frame_rd    <=  not no_pkts_in_ctl_down_buf_r1
                                 and not ctl_down_buf_read_gap
                                 and not ctl_down_buf_stop_read
                                 ;
    end if;
  end process;

  -- 
  Syn_rden_CTL_downstream_buf:
  process (link_tx_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
        ctl_down_buf_stop_read   <= '0';
    elsif link_tx_clk'event and link_tx_clk = '1' then
        if ctl_down_buf_read_gap='1' and ctrl2send_stop_r1='1' then
           ctl_down_buf_stop_read   <= '1';
        elsif ctl_down_buf_stop_read='0' and ctrl2send_stop_r1='1' then
           ctl_down_buf_stop_read   <= '0';
        else
           ctl_down_buf_stop_read   <= ctrl2send_stop_r1;
        end if;
    end if;
  end process;

  ctrl2send_start_i  <= ctl_down_buf_dout(17);
  ctrl2send_end_i    <= ctl_down_buf_eop and not ctl_down_buf_eop_r1;
  ctrl2send_i        <= ctl_down_buf_dout(16-1 downto 0);


  -- ------------------------------------------------------------------------------
  --   CTL buffer to the host
  -- ------------------------------------------------------------------------------
  ctl_buf_upstream:
  afifo_256x36c_fwft
  port map (
            wr_clk        => link_rx_clk         ,  -- IN  std_logic;
            wr_en         => ctl_up_buf_wren     ,  -- IN  std_logic;
            din           => ctl_up_buf_din      ,  -- IN  std_logic_VECTOR(35 downto 0);
            prog_full     => ctl_up_buf_afull    ,  -- ctrl_rec_stop_i  ,  -- OUT std_logic;
            full          => open                ,  -- OUT std_logic;

            rd_clk        => trn_clk            ,  -- IN  std_logic;
            rd_en         => ctl_up_buf_re      ,  -- IN  std_logic;
            dout          => ctl_up_buf_dout    ,  -- OUT std_logic_VECTOR(35 downto 0);
            prog_empty    => open               ,  -- OUT std_logic;
            empty         => ctl_up_buf_empty   ,  -- OUT std_logic;

            rd_data_count => ctl_up_buf_dc_wire ,  -- OUT std_logic_vector (9-1 downto 0 ); 

            rst           => ctl_reset             -- IN  std_logic
           );

  ctl_up_buf_re          <= ctl_ttake;
  ctl_up_buf_rd_valid    <= ctl_up_buf_re and not ctl_up_buf_empty;


  -- Special data count for FWFT FIFO
  Syn_up_fifo_fwft_dc:
  process (trn_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      ctl_up_buf_dc_i        <= (OTHERS=>'0');
      ctl_up_buf_dc_r1       <= (OTHERS=>'0');
      ctl_up_buf_dc_plus_r1  <= (OTHERS=>'0');
    elsif trn_clk'event and trn_clk = '1' then
      ctl_up_buf_dc_r1       <= ctl_up_buf_dc_wire;
      ctl_up_buf_dc_plus_r1  <= ctl_up_buf_dc_wire + "10";
      if ctl_up_buf_empty='1' then
         ctl_up_buf_dc_i        <= ctl_up_buf_dc_r1;
      else
         ctl_up_buf_dc_i        <= ctl_up_buf_dc_plus_r1;
      end if;
    end if;
  end process;

  -- Packet counter: ROC -> ABB
  pc_ctl_buf_upstream:
  pkt_counter_1024
  port map (
        wr_clk      => link_rx_clk     , -- IN  std_logic;
        wr_en       => pc_ctl_up_push  , -- IN  std_logic;
        din         => "1"             , -- IN  std_logic_VECTOR(0 downto 0);
        prog_full   => open            , -- OUT std_logic;
        full        => open            , -- OUT std_logic;

        rd_clk      => trn_clk         , -- IN  std_logic;
        rd_en       => pc_ctl_up_pop   , -- IN  std_logic;
        dout        => open            , -- OUT std_logic_VECTOR(0 downto 0);
        empty       => no_pkts_in_ctl_up_buf  , -- OUT std_logic;
        prog_empty  => open            , -- OUT std_logic;

        rst         => ctl_reset      -- IN  std_logic
        );


  Syn_pc_ctl_up_push:
  process (link_rx_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      pc_ctl_up_push    <= '0';
    elsif link_rx_clk'event and link_rx_clk = '1' then
      pc_ctl_up_push    <= ctl_up_buf_wren and ctl_up_buf_din(16);
    end if;
  end process;

  Syn_pc_ctl_up_pop:
  process (trn_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      pc_ctl_up_pop     <= '0';
      no_pkts_in_ctl_up_buf_r1  <= '1';
    elsif trn_clk'event and trn_clk = '1' then
      pc_ctl_up_pop     <= ctl_up_buf_rd_valid and ctl_up_buf_dout(16);
      no_pkts_in_ctl_up_buf_r1  <= no_pkts_in_ctl_up_buf;
    end if;
  end process;

  -- CTL direction: upstream
  --     protocol side
  Transfer_CTL_upstream_protocol:
  process (link_rx_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      ctl_up_buf_din_b1    <= (OTHERS=>'0');
      ctl_up_buf_din       <= (OTHERS=>'0');
      ctl_up_buf_wren      <= '0';
      ctl_up_is_writing    <= '0';
      ctl_up_is_writing_r1 <= '0';

    elsif link_rx_clk'event and link_rx_clk = '1' then
      ctl_up_buf_din_b1  <= X"0000" & "00" & ctrl_rec_start & ctrl_rec_end & ctrl_rec;
      ctl_up_buf_din     <= ctl_up_buf_din_b1;
      ctl_up_buf_wren    <= (ctl_up_is_writing or ctl_up_is_writing_r1);
      if ctrl_rec_start='1' and ctrl_rec_end='1' then
         ctl_up_is_writing    <= '0';
         ctl_up_is_writing_r1 <= '1';
      elsif ctrl_rec_start='1' then
         ctl_up_is_writing    <= '1';
         ctl_up_is_writing_r1 <= ctl_up_is_writing;
      elsif ctrl_rec_end='1' then
         ctl_up_is_writing    <= '0';
         ctl_up_is_writing_r1 <= ctl_up_is_writing;
      else
         ctl_up_is_writing    <= ctl_up_is_writing;
         ctl_up_is_writing_r1 <= ctl_up_is_writing;
      end if;

    end if;
  end process;


  -- CTL direction: upstream
  --     fabric side
  Transfer_CTL_upstream_fabric:
  process (trn_clk, ctl_reset )
  begin
    if ctl_reset = '1' then
      ctl_tv_i   <=  '0';
      ctl_td_i   <=  (OTHERS=>'0');
    elsif trn_clk'event and trn_clk = '1' then
      ctl_tv_i   <=  not ctl_up_buf_empty;
      ctl_td_i   <=  ctl_up_buf_dout(C_DBUS_WIDTH/2-1 downto 0);
    end if;
  end process;


end architecture Behavioral;
