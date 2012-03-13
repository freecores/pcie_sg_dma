----------------------------------------------------------------------------------
-- Company:   ziti
-- Engineer:  wgao
-- 
-- Create Date:    18:29:15 29 Jun 2009 
-- Design Name: 
-- Module Name:    abb_dgen - Behavioral 
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

entity abb_dgen is
    port (

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

           -- status signals
           dg_running         : OUT   STD_LOGIC;
           daq_start_led      : OUT   STD_LOGIC;

           -- must signals
           dg_clk             : IN    STD_LOGIC;
           dg_mask            : IN    STD_LOGIC;
           dg_rst             : IN    STD_LOGIC
           );
end abb_dgen;


architecture Behavioral of abb_dgen is

  type DGHaltStates is           ( dgST_RESET
                                 , dgST_Run
                                 , dgST_Halt
                                 );

  -- State variables
  signal dg_Halt_State      : DGHaltStates;

  -- Data generator table, without output registering
  component v6_bram4096x64_fast
    port (
      clka           : IN  std_logic;
      addra          : IN  std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
      wea            : IN  std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
      dina           : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      douta          : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      clkb           : IN  std_logic;
      addrb          : IN  std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
      web            : IN  std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
      dinb           : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      doutb          : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0)
    );
  end component;

  -- DAQ Rx
  signal  data_rec_start_i : std_logic;
  signal  data_rec_end_i   : std_logic;
  signal  data_rec_i       : std_logic_vector(64-1 downto 0);
  signal  crc_error_rec_i  : std_logic;

  -- CTL Rx
  signal  ctrl_rec_start_i : std_logic;
  signal  ctrl_rec_end_i   : std_logic;
  signal  ctrl_rec_i       : std_logic_vector(16-1 downto 0);

  -- DLM Rx
  signal  dlm_rec_va_i     : std_logic;
  signal  dlm_rec_type_i   : std_logic_vector(4-1 downto 0);

  -- Table signals
  signal  dg_running_i     : std_logic;
  signal  tab_travel       : std_logic;
  signal  tab_halt         : std_logic;
  signal  tab_we_padded    : std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
  signal  tab_ra           : std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
  signal  tab_ra_r1        : std_logic_vector(C_PRAM_AWIDTH-1 downto 0);
  signal  tab_rb_dummy     : std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
  signal  tab_rd_dummy     : std_logic_vector(C_DBUS_WIDTH-1 downto 0);
  signal  tab_rq           : std_logic_vector(C_DBUS_WIDTH-1 downto 0);

  -- feature bits
  signal  tab_class_bits   : std_logic_vector(2-1 downto 0);
  signal  tab_enable_bit   : std_logic;
  signal  tab_stop_bit     : std_logic;
  signal  tab_cerr_bit     : std_logic;
  signal  tab_sop_bit      : std_logic;
  signal  tab_eop_bit      : std_logic;

  -- procedure control
  signal  congest_daq      : std_logic;
  signal  congest_ctl      : std_logic;
  signal  delay_time_over  : std_logic;
  signal  delay_counter    : std_logic_vector(16-1 downto 0);
  signal  dg_mask_r1       : std_logic;
  signal  dg_mask_rise     : std_logic;

  -- debug signal
  signal  daq_start_latch  : std_logic;
  signal  daq_start_led_i  : std_logic := '0';
  signal  cnt_daq_start    : std_logic_vector(20-1 downto 0);

  -- Constants
  Constant  C_CLASS_DAQ    : std_logic_vector(2-1 downto 0) := "01";
  Constant  C_CLASS_CTL    : std_logic_vector(2-1 downto 0) := "10";
  Constant  C_CLASS_DLM    : std_logic_vector(2-1 downto 0) := "11";

begin

   dg_running        <= dg_running_i;
   dg_running_i      <= tab_travel;

   dg_mask_rise      <= dg_mask and not dg_mask_r1;

   data_rec_start    <= data_rec_start_i  when dg_mask_r1='0' else '0';
   data_rec_end      <= (data_rec_end_i or dg_mask_rise)   when dg_mask_r1='0' else '0';
   data_rec          <= data_rec_i        when dg_mask_r1='0' else (OTHERS=>'0');
   crc_error_rec     <= crc_error_rec_i   when dg_mask_r1='0' else '0';
                        
   ctrl_rec_start    <= ctrl_rec_start_i  when dg_mask_r1='0' else '0';
   ctrl_rec_end      <= (ctrl_rec_end_i or dg_mask_rise)   when dg_mask_r1='0' else '0';
   ctrl_rec          <= ctrl_rec_i        when dg_mask_r1='0' else (OTHERS=>'0');
                        
   dlm_rec_va        <= dlm_rec_va_i      when dg_mask_r1='0' else '0';
   dlm_rec_type      <= dlm_rec_type_i    when dg_mask_r1='0' else (OTHERS=>'0');


   -- Syn. delay: dg_mask
   Delay_dg_mask:
   process ( dg_clk)
   begin
     if dg_clk'event and dg_clk = '1' then
        dg_mask_r1     <= dg_mask;
     end if;
   end process;


   -- -------------------------------------------------
   -- Debug LED
   --
   daq_start_latch   <= data_rec_start_i and not dg_mask;
   daq_start_led     <= daq_start_led_i;

   SynProc_DGen_Debug_LED:
   process ( dg_clk, daq_start_latch)
   begin
      if daq_start_latch='1' then
        daq_start_led_i   <=  '1';
        cnt_daq_start     <=  (OTHERS=>'0');
      elsif dg_clk'event and dg_clk = '1' then
--        if cnt_daq_start=X"0000F" then
        if cnt_daq_start=X"F0000" then
          daq_start_led_i     <=  '0';
          cnt_daq_start       <=  cnt_daq_start;
        else
          daq_start_led_i     <=  daq_start_led_i;
          cnt_daq_start       <=  cnt_daq_start + '1';
        end if;
      end if;
   end process;


   -- -------------------------------------------------
   -- Data generator table block RAM instantiate
   -- 
   dgen_RAM:
   v6_bram4096x64_fast
     port map (
         clka      =>    dg_clk  ,
         addra     =>    tab_wa  ,
         wea       =>    tab_we_padded  ,
         dina      =>    tab_wd  ,
         douta     =>    open    ,

         clkb      =>    dg_clk  ,
         addrb     =>    tab_ra  ,
         web       =>    tab_rb_dummy ,
         dinb      =>    tab_rd_dummy ,
         doutb     =>    tab_rq  
       );

   tab_rb_dummy   <= (OTHERS=>'0');
   tab_rd_dummy   <= (OTHERS=>'1');
   tab_we_padded  <= (tab_we(1) & tab_we(1) & tab_we(1) & tab_we(1)
                    & tab_we(0) & tab_we(0) & tab_we(0) & tab_we(0)) when tab_sel='1'
                else (OTHERS=>'0');

   tab_ra  <=    tab_rq(59 downto 48) when (tab_travel='1' and delay_time_over='1' and congest_daq='0' and congest_ctl='0')
           else  tab_ra_r1;

   tab_class_bits <= tab_rq(61 downto 60);
   tab_enable_bit <= tab_rq(63);
   tab_stop_bit   <= tab_rq(62);
   tab_cerr_bit   <= tab_rq(18);
   tab_sop_bit    <= tab_rq(17);
   tab_eop_bit    <= tab_rq(16);


   -- table control: travel
   Syn_tab_travel:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         tab_travel     <= '0';
      elsif dg_clk'event and dg_clk = '1' then
         if tab_enable_bit='1' then
           tab_travel     <= '1';
         elsif tab_halt='1' then
           tab_travel     <= '0';
         else
           tab_travel     <= tab_travel;
         end if;
      end if;
   end process;

   -- table control: halt
   Syn_tab_halt:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         tab_halt        <= '1';
         dg_Halt_State   <= dgST_RESET;
      elsif dg_clk'event and dg_clk = '1' then

         case dg_Halt_State  is
           when dgST_RESET =>
             dg_Halt_State  <= dgST_Run;
             tab_halt       <= '0';

           when dgST_Run =>
             if tab_stop_bit='1' then
               dg_Halt_State  <= dgST_Halt;
               tab_halt       <= '1';
             else
               dg_Halt_State  <= dgST_Run;
               tab_halt       <= '0';
             end if;

           when OTHERS =>  -- dgST_Halt
             dg_Halt_State  <= dgST_Halt;
             tab_halt       <= '1';

         end case;

      end if;
   end process;


   -- table read address latch
   Syn_tab_rd_address:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         tab_ra_r1     <= (OTHERS=>'0');
      elsif dg_clk'event and dg_clk = '1' then
         if tab_travel='1'
            and delay_time_over='1'
            and 
            (
              (congest_daq='0' and tab_class_bits=C_CLASS_DAQ)
              or 
              (congest_ctl='0' and tab_class_bits=C_CLASS_CTL)
            ) then
            tab_ra_r1     <= tab_rq(59 downto 48);
         else
            tab_ra_r1     <= tab_ra_r1;
         end if;
      end if;
   end process;


   -- Delay time over
   Syn_delay_time_over:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         delay_time_over  <= '0';
         delay_counter    <= (OTHERS=>'0');
      elsif dg_clk'event and dg_clk = '1' then
         if delay_time_over='1' then
           if tab_rq(47 downto 32)=C_ALL_ZEROS(47 downto 32)
             or tab_stop_bit='1' then
             delay_counter    <= (OTHERS=>'0');
             delay_time_over  <= '1';
           else
             delay_counter    <= tab_rq(47 downto 32);
             delay_time_over  <= '0';
           end if;
         else
           if delay_counter=C_ALL_ZEROS(47 downto 32) then
             delay_counter    <= (OTHERS=>'0');
             delay_time_over  <= '1';
           else
             delay_counter    <= delay_counter - '1';
             delay_time_over  <= '0';
           end if;
         end if;

      end if;
   end process;


   -- table control: Congestion
   Syn_tab_Congest:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         congest_daq     <= '0';
         congest_ctl     <= '0';
      elsif dg_clk'event and dg_clk = '1' then
         if tab_class_bits=C_CLASS_DAQ and tab_eop_bit='1' and data_rec_stop='1' then
           congest_daq     <= '1';
         elsif congest_daq='1' and (tab_class_bits/=C_CLASS_DAQ or data_rec_stop='0') then
           congest_daq     <= '0';
         else
           congest_daq     <= congest_daq;
         end if;

         if tab_class_bits=C_CLASS_CTL and tab_eop_bit='1' and ctrl_rec_stop='1' then
           congest_ctl     <= '1';
         elsif congest_ctl='1' and (tab_class_bits/=C_CLASS_CTL or ctrl_rec_stop='0') then
           congest_ctl     <= '0';
         else
           congest_ctl     <= congest_ctl;
         end if;
      end if;
   end process;


   -- table output: daq
   Syn_tab_to_daq:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         data_rec_start_i <= '0';
         data_rec_end_i   <= '0';
         data_rec_i       <= (OTHERS=>'0');
         crc_error_rec_i  <= '0';
      elsif dg_clk'event and dg_clk = '1' then
         if tab_class_bits=C_CLASS_DAQ then
           if tab_halt='1' then
             data_rec_start_i <= '0';
             data_rec_end_i   <= '0';
             data_rec_i       <= (OTHERS=>'0');
             crc_error_rec_i  <= '0';
           elsif congest_daq='1' then
             data_rec_start_i <= data_rec_start_i;
             data_rec_end_i   <= data_rec_end_i;
             data_rec_i       <= data_rec_i;
             crc_error_rec_i  <= crc_error_rec_i;
           else
             data_rec_start_i <= tab_sop_bit and tab_travel and delay_time_over;
             data_rec_end_i   <= tab_eop_bit and tab_travel and delay_time_over;
             data_rec_i       <= tab_rq(16-1 downto 0)&tab_rq(16-1 downto 0)&tab_rq(16-1 downto 0)&tab_rq(16-1 downto 0);
             crc_error_rec_i  <= tab_cerr_bit and tab_travel and delay_time_over;
           end if;
         else
           data_rec_start_i <= '0';
           data_rec_end_i   <= '0';
           data_rec_i       <= (OTHERS=>'0');
           crc_error_rec_i  <= '0';
         end if;
      end if;
   end process;


   -- table output: ctl
   Syn_tab_to_ctl:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         ctrl_rec_start_i <= '0';
         ctrl_rec_end_i   <= '0';
         ctrl_rec_i       <= (OTHERS=>'0');
      elsif dg_clk'event and dg_clk = '1' then
         if tab_class_bits=C_CLASS_CTL then
           if tab_halt='1' then
             ctrl_rec_start_i <= '0';
             ctrl_rec_end_i   <= '0';
             ctrl_rec_i       <= (OTHERS=>'0');
           elsif congest_ctl='1' then
             ctrl_rec_start_i <= ctrl_rec_start_i;
             ctrl_rec_end_i   <= ctrl_rec_end_i;
             ctrl_rec_i       <= ctrl_rec_i;
           else
             ctrl_rec_start_i <= tab_sop_bit and tab_travel and delay_time_over;
             ctrl_rec_end_i   <= tab_eop_bit and tab_travel and delay_time_over;
             ctrl_rec_i       <= tab_rq(16-1 downto 0);
           end if;
         else
           ctrl_rec_start_i <= '0';
           ctrl_rec_end_i   <= '0';
           ctrl_rec_i       <= (OTHERS=>'0');
         end if;
      end if;
   end process;


   -- table output: dlm
   Syn_tab_to_dlm:
   process ( dg_clk, dg_rst)
   begin
      if dg_rst = '1' then
         dlm_rec_va_i     <= '0';
         dlm_rec_type_i   <= (OTHERS=>'0');
      elsif dg_clk'event and dg_clk = '1' then
         if tab_class_bits=C_CLASS_DLM then
           if tab_halt='1' then
             dlm_rec_va_i     <= '0';
             dlm_rec_type_i   <= (OTHERS=>'0');
           else
             dlm_rec_va_i     <= (tab_sop_bit or tab_eop_bit) and tab_travel and delay_time_over;
             dlm_rec_type_i   <= tab_rq(4-1 downto 0);
           end if;
         else
           dlm_rec_va_i     <= '0';
           dlm_rec_type_i   <= (OTHERS=>'0');
         end if;
      end if;
   end process;


end Behavioral;
