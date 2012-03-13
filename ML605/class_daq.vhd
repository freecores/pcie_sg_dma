----------------------------------------------------------------------------------
-- Company:   ziti
-- Engineer:  wgao
-- 
-- Create Date:    17:01:32 19 Jun 2009
-- Design Name: 
-- Module Name:    class_daq - Behavioral 
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

entity class_daq is
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

           -- Common signals
           link_tx_clk              : IN    std_logic;
           link_rx_clk              : IN    std_logic;

           -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

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
end entity class_daq;


architecture Behavioral of class_daq is

  -- Standard synchronous FIFO
  component sfifo_1024x72
    port (
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(72-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(72-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          clk       : IN  std_logic;
          rst       : IN  std_logic
          );
  end component;

  -- Standard asynchronous FIFO
  component v6_afifo_1024x72
    port (
          wr_clk    : IN  std_logic;
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(72-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_clk    : IN  std_logic;
          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(72-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          rst       : IN  std_logic
          );
  end component;

  -- Standard synchronous FIFO
  component sfifo_256x18
    port (
          wr_en     : IN  std_logic;
          din       : IN  std_logic_VECTOR(18-1 downto 0);
          prog_full : OUT std_logic;
          full      : OUT std_logic;

          rd_en     : IN  std_logic;
          dout      : OUT std_logic_VECTOR(18-1 downto 0);
          empty     : OUT std_logic;
          prog_empty: OUT std_logic;

          clk       : IN  std_logic;
          rst       : IN  std_logic
          );
  end component;

  -- Interrupter trigger
  signal  DAQ_irq_i             : std_logic;

  -- Fabric side: DAQ Tx
  signal  daq_tv_i              : std_logic;
  signal  daq_tsof_i            : std_logic;
  signal  daq_tsof_vector       : std_logic_vector(C_DBUS_WIDTH/16-1 downto 0);
  signal  daq_teof_i            : std_logic;
  signal  daq_teof_vector       : std_logic_vector(C_DBUS_WIDTH/16-1 downto 0);
  signal  daq_td_i              : std_logic_vector(C_DBUS_WIDTH-1 downto 0);
  signal  daq_rstop_i           : std_logic;

  signal  daq_up_is_writing     : std_logic;
  signal  daq_up_is_writing_r1  : std_logic;
  signal  Tout_Cnt_daq_up_wr    : std_logic_vector(8-1 downto 0);

  -- protocol side: DAQ Send
  signal  data2send_start_i     : std_logic;
  signal  data2send_end_i       : std_logic;
  signal  data2send_i           : std_logic_vector(64-1 downto 0);
  signal  crc_error_send_i      : std_logic;
  signal  data_rec_start_r1     : std_logic;
  signal  data_rec_end_r1       : std_logic;
  signal  data_rec_end_r2       : std_logic;
  signal  data_rec_r1           : std_logic_vector(64-1 downto 0);
  signal  data_rec_stop_i       : std_logic;
  signal  data_rec_stop_r1      : std_logic;
  signal  data_rec_stop_r2      : std_logic;
  signal  data_rec_stop_r3      : std_logic;
  signal  data_rec_stop_r4      : std_logic;

  signal  daq_rd_padded         : std_logic_vector(72-1 downto 0);
  signal  daq_rd_r1             : std_logic_vector(C_DBUS_WIDTH-1 downto 0);

  -- DAQ packet number counting up
  signal  pkt_number_DAQ_down   : std_logic_vector(8-1 downto 0);

  signal  daq_down_buf_rden     : std_logic;
  signal  daq_down_buf_eop      : std_logic;
  signal  daq_down_buf_sop      : std_logic;
  signal  daq_down_buf_eop_r1   : std_logic;
  signal  daq_down_split_rden   : std_logic;
  signal  daq_down_buf_read_gap : std_logic;
  signal  daq_down_buf_stop_read: std_logic;
  signal  daq_down_buf_dout     : std_logic_vector(72-1 downto 0);
  signal  daq_down_buf_empty    : std_logic;
  signal  daq_down_buf_rd_valid : std_logic;
  signal  noPkt_in_daq_down_buf : std_logic;

  signal  daq_up_buf_we         : std_logic;
  signal  daq_up_buf_din        : std_logic_vector(72-1 downto 0);
  signal  daq_up_buf_afull      : std_logic;
  signal  daq_up_buf_afull_r1   : std_logic;
  signal  daq_up_buf_re         : std_logic;
  signal  daq_up_buf_rd_valid   : std_logic;
  signal  daq_up_buf_dout       : std_logic_vector(72-1 downto 0);
  signal  daq_up_buf_pempty     : std_logic;
  signal  daq_up_buf_empty      : std_logic;
  signal  daq_up_eop            : std_logic;
  signal  daq_up_eop_r1         : std_logic;


begin

  -- Fabric side: DAQ Tx
  daq_tv             <=  daq_tv_i;
  daq_tsof           <=  daq_tsof_i and daq_tv_i;
  daq_teof           <=  daq_teof_i and daq_tv_i;
  daq_td             <=  daq_td_i  when daq_tv_i='1' else (OTHERS=>'0');

  daq_rstop          <=  daq_rstop_i        ;

  DAQ_irq            <=  DAQ_irq_i          ;
  DAQ_irq_i          <=  '0';             -- ?

  -- protocol side: DAQ Send
  data2send_start    <=  data2send_start_i  ;
  data2send_end      <=  data2send_end_i    ;
  data2send          <=  data2send_i        ;
  crc_error_send     <=  crc_error_send_i   ;


  data_rec_stop      <=  data_rec_stop_i    ;
  data_rec_stop_i    <=  daq_up_buf_afull_r1   ;


  daq_up_eop         <=  daq_up_buf_dout(16) ;

  -- 
  DAQ_upstream_Read_Gap:
  process (trn_clk)
  begin
    if trn_clk'event and trn_clk = '1' then
      daq_up_eop_r1    <=  daq_up_eop;
    end if;
  end process;

  Syn_delay_daq_up_buf_afull:
  process (link_rx_clk)
  begin
    if link_rx_clk'event and link_rx_clk = '1' then
      daq_up_buf_afull_r1    <=  daq_up_buf_afull;
      data_rec_stop_r1       <=  data_rec_stop_i;
      data_rec_stop_r2       <=  data_rec_stop_r1;
      data_rec_stop_r3       <=  data_rec_stop_r2;
      data_rec_stop_r4       <=  data_rec_stop_r3;
    end if;
  end process;

  -- DAQ direction: upstream
  --     protocol side
  -- 
  Transfer_DAQ_upstream_protocol:
  process (link_rx_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
      daq_up_is_writing     <= '0';
      Tout_Cnt_daq_up_wr    <= (OTHERS=>'0');

    elsif link_rx_clk'event and link_rx_clk = '1' then

      if daq_up_is_writing='0' then
        if data_rec_start='1' and data_rec_start_r1='0' then
           daq_up_is_writing  <= '1';
           Tout_Cnt_daq_up_wr <= (OTHERS=>'0');
        else
           daq_up_is_writing  <= '0';
           Tout_Cnt_daq_up_wr <= (OTHERS=>'0');
        end if;
      else
        if data_rec_end_r1='1' and data_rec_end_r2='0' then
           daq_up_is_writing  <= '0';
           Tout_Cnt_daq_up_wr <= (OTHERS=>'0');
        elsif Tout_Cnt_daq_up_wr(6)='1' then
           daq_up_is_writing  <= '0';
           Tout_Cnt_daq_up_wr <= Tout_Cnt_daq_up_wr;
        else
           daq_up_is_writing  <= '1';
           Tout_Cnt_daq_up_wr <= Tout_Cnt_daq_up_wr + '1';
        end if;
      end if;

    end if;
  end process;


--  Transfer_DAQ_upstream_protocol:
--  process (link_rx_clk, protocol_rst )
--  begin
--    if protocol_rst = '1' then
--      daq_up_is_writing     <= '0';
--      daq_up_is_writing_r1  <= '0';
--
--    elsif link_rx_clk'event and link_rx_clk = '1' then
--      if data_rec_start='1' and data_rec_end='1' then
--         daq_up_is_writing     <= '0';
--         daq_up_is_writing_r1  <= not data_rec_stop_i  or not data_rec_stop_r1 
--                               or not data_rec_stop_r2 or not data_rec_stop_r3
--                               or not data_rec_stop_r4
--                               ;
--      elsif data_rec_start='1' then
--         daq_up_is_writing     <= not data_rec_stop_i  or not data_rec_stop_r1 
--                               or not data_rec_stop_r2 or not data_rec_stop_r3
--                               or not data_rec_stop_r4
--                               ;
--         daq_up_is_writing_r1  <= daq_up_is_writing;
--      elsif data_rec_end='1' then
--         daq_up_is_writing     <= '0';
--         daq_up_is_writing_r1  <= daq_up_is_writing;
--      else
--         daq_up_is_writing     <= daq_up_is_writing;
--         daq_up_is_writing_r1  <= daq_up_is_writing;
--      end if;
--
--    end if;
--  end process;

  -- direction: upstream
  Transfer_DAQ_upstream_link:
  process (link_rx_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
      data_rec_start_r1    <= '0';
      data_rec_end_r1      <= '0';
      data_rec_end_r2      <= '0';
      data_rec_r1          <= (OTHERS=>'0');
      daq_up_buf_we        <= '0';
      daq_up_buf_din       <= (OTHERS=>'0');

    elsif link_rx_clk'event and link_rx_clk = '1' then
      data_rec_start_r1    <= data_rec_start;
      data_rec_end_r1      <= data_rec_end;
      data_rec_end_r2      <= data_rec_end_r1;
      data_rec_r1          <= data_rec;
      daq_up_buf_we        <= daq_up_is_writing;  --(daq_up_is_writing or daq_up_is_writing_r1);
      daq_up_buf_din       <= "000000" & data_rec_start_r1 & data_rec_end_r1 & data_rec_r1;

    end if;
  end process;


  -- ------------------------------------------------------------------------------
  --   DAQ buffer to the host
  -- ------------------------------------------------------------------------------
  daq_buf_upstream:
  v6_afifo_1024x72
  port map (
            wr_clk     => link_rx_clk        ,  -- IN  std_logic;
            wr_en      => daq_up_buf_we      ,  -- IN  std_logic;
            din        => daq_up_buf_din     ,  -- IN  std_logic_VECTOR(17 downto 0);
            prog_full  => daq_up_buf_afull   ,  -- OUT std_logic;
            full       => open               ,  -- OUT std_logic;

            rd_clk     => trn_clk            ,  -- IN  std_logic;
            rd_en      => daq_up_buf_re      ,  -- IN  std_logic;
            dout       => daq_up_buf_dout    ,  -- OUT std_logic_VECTOR(17 downto 0);
            prog_empty => daq_up_buf_pempty  ,  -- OUT std_logic;
            empty      => daq_up_buf_empty   ,  -- OUT std_logic;

            rst        => protocol_rst          -- IN  std_logic
           );

  -- upstream: merging ...
  Transfer_DAQ_upstream_merge:
  process (trn_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
      daq_up_buf_re        <= '0';
      daq_up_buf_rd_valid  <= '0';
      daq_tv_i             <= '0';
      daq_tsof_i           <= '0';
      daq_teof_i           <= '0';
      daq_td_i             <= (OTHERS=>'0');

    elsif trn_clk'event and trn_clk = '1' then
      daq_up_buf_re        <= not daq_tstop;
      daq_up_buf_rd_valid  <= daq_up_buf_re and not daq_up_buf_empty;
      daq_tv_i             <= daq_up_buf_rd_valid;
      daq_tsof_i           <= daq_up_buf_dout(65);
      daq_teof_i           <= daq_up_buf_dout(64);
      daq_td_i             <= daq_up_buf_dout(64-1 downto 0);

    end if;
  end process;


  -- ------------------------------------------------------------------------------
  --   DAQ buffer from the host
  -- ------------------------------------------------------------------------------
  daq_buf_downstream:
  v6_afifo_1024x72
  port map (
            wr_clk     => trn_clk            ,  -- IN  std_logic;
            wr_en      => daq_rv             ,  -- IN  std_logic;
            din        => daq_rd_padded      ,  -- IN  std_logic_VECTOR(71 downto 0);
            prog_full  => daq_rstop_i        ,  -- OUT std_logic;
            full       => open               ,  -- OUT std_logic;

            rd_clk     => link_tx_clk        ,  -- IN  std_logic;
            rd_en      => daq_down_buf_rden  ,  -- IN  std_logic;
            dout       => daq_down_buf_dout  ,  -- OUT std_logic_VECTOR(71 downto 0);
            prog_empty => open               ,  -- OUT std_logic;
            empty      => daq_down_buf_empty ,  -- OUT std_logic;

            rst        => protocol_rst          -- IN  std_logic
           );

  daq_down_buf_sop       <= daq_down_buf_dout(65);
  daq_down_buf_eop       <= daq_down_buf_dout(64);
  daq_down_buf_read_gap  <= daq_down_buf_eop and not daq_down_buf_eop_r1;
  daq_down_buf_rden      <= daq_down_split_rden and not daq_down_buf_read_gap;
  daq_rd_padded          <= "000000" & daq_rsof & daq_reof & daq_rd;

  -- ------------------------------------------------
  Syn_Delay_daq_down_buf_eop:
  process (link_tx_clk)
  begin
    if link_tx_clk'event and link_tx_clk = '1' then
        daq_down_buf_eop_r1      <= daq_down_buf_eop;
    end if;
  end process;


  ---------------------------------------------------
  -- Downstream DAQ buffer read and packets number
  --  bit[71] : mask[3]
  --  bit[70] : mask[2]
  --  bit[69] : mask[1]
  --  bit[68] : mask[0]
  --  bit[67] : (reserved)
  --  bit[66] : crc_error
  --  bit[65] : sof
  --  bit[64] : eof
  -- 
  Syn_rden_DAQ_downstream_buf:
  process (link_tx_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
        pkt_number_DAQ_down      <= (OTHERS=>'0');
        daq_down_split_rden      <= '0';
        daq_down_buf_rd_valid    <= '0';
        noPkt_in_daq_down_buf    <= '1';
        daq_down_buf_stop_read   <= '0';

    elsif link_tx_clk'event and link_tx_clk = '1' then

        if daq_down_buf_read_gap='1' and data2send_stop='1' then
           daq_down_buf_stop_read   <= '1';
        elsif daq_down_buf_stop_read='0' and data2send_stop='1'  then
           daq_down_buf_stop_read   <= '0';
        else
           daq_down_buf_stop_read   <= data2send_stop;
        end if;

        daq_down_split_rden      <=  not noPkt_in_daq_down_buf
                                 --  maximal one read every four cycles
                                 and not daq_down_buf_read_gap
                                 and not daq_down_buf_stop_read
                                 ;

        daq_down_buf_rd_valid    <= daq_down_buf_rden and not daq_down_buf_empty;

        if (daq_rv='1' and daq_rd_padded(64)='1')
           and (daq_down_buf_rd_valid='1' and daq_down_buf_eop='1')
           then
           pkt_number_DAQ_down   <= pkt_number_DAQ_down;
        elsif daq_rv='1' and daq_rd_padded(64)='1' then
           pkt_number_DAQ_down   <= pkt_number_DAQ_down + '1';
        elsif daq_down_buf_rd_valid='1' and daq_down_buf_eop='1' then
           pkt_number_DAQ_down   <= pkt_number_DAQ_down - '1';
        else
           pkt_number_DAQ_down   <= pkt_number_DAQ_down;
        end if;

        if pkt_number_DAQ_down=C_ALL_ZEROS(8-1 downto 0) then
           noPkt_in_daq_down_buf <= '1';
        else
           noPkt_in_daq_down_buf <= '0';
        end if;

    end if;
  end process;

  -- ----------------------------------------------
  -- 
  -- 
  Syn_data2send_link:
  process (link_tx_clk, protocol_rst )
  begin
    if protocol_rst = '1' then
       data2send_start_i  <= '0';
       data2send_end_i    <= '0';
       data2send_i        <= (OTHERS=>'0');
       crc_error_send_i   <=  '0';
    elsif link_tx_clk'event and link_tx_clk = '1' then
       if daq_down_buf_rd_valid='1' then
          data2send_start_i  <= daq_down_buf_sop;
          data2send_end_i    <= daq_down_buf_eop;
          data2send_i        <= daq_down_buf_dout(64-1 downto 0);
       else
          data2send_start_i  <= '0';
          data2send_end_i    <= '0';
          data2send_i        <= (OTHERS=>'0');
       end if;
    end if;
  end process;


end architecture Behavioral;
