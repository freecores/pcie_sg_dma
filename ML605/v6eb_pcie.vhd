----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:12:51 01 Feb 2010
-- Design Name: 
-- Module Name:    v6pcieDMA - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- 
-- Revision 1.00 - File Released
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
library UNISIM;
use UNISIM.VComponents.all;

entity v6pcieDMA is
    generic (
          constant pcieLanes            : integer     := C_NUM_PCIE_LANES
          );
    Port (

          -- Optical links
          TILE0_REFCLK_PAD_N_IN         : IN  std_logic;
          TILE0_REFCLK_PAD_P_IN         : IN  std_logic;

          RXN_IN                        : IN  std_logic;
          RXP_IN                        : IN  std_logic;
          TXN_OUT                       : OUT std_logic;
          TXP_OUT                       : OUT std_logic;

          SFP_LOS                       : IN  std_logic;


          -- DDR interface

--          ddr2_sys_clk                  : IN    std_logic;
--v6          Button_Rst                    : IN    std_logic;

          -- dummy pin input  !!!! not really exists
--v6          dummy_pin_in                  : IN    std_logic_vector(3-1 downto 0);

          -- DPR blinker
          LEDs_IO_pin                   : OUT   std_logic_vector(7 downto 0);


--v6          refclkout                 : OUT   std_logic;

          -- PCIe transceivers
          pci_exp_rxp                   : IN    std_logic_vector(pcieLanes - 1 downto 0);
          pci_exp_rxn                   : IN    std_logic_vector(pcieLanes - 1 downto 0);
          pci_exp_txp                   : OUT   std_logic_vector(pcieLanes - 1 downto 0);
          pci_exp_txn                   : OUT   std_logic_vector(pcieLanes - 1 downto 0);

          -- Necessity signals
          sys_clk_p                     : IN    std_logic;
          sys_clk_n                     : IN    std_logic;
          sys_reset_n                   : IN    std_logic
          );                       

end entity v6pcieDMA;


architecture Behavioral of v6pcieDMA is



--   signal dlm_rec0              : std_logic_vector(3 downto 0);
--   signal dlm_rec_valid0        : std_logic;
--
--   signal dlm_rec1              : std_logic_vector(3 downto 0);
--   signal dlm_rec_valid1        : std_logic;



------------- COMPONENT Declaration: v6_pcie_v1_3 x4 ------
 component v6_pcie_v1_3
   generic (
         PL_FAST_TRAIN  : boolean
         );
   port (
    ---------------------------------------------------------
    -- 1. PCI Express (pci_exp) Interface
    ---------------------------------------------------------

    -- Tx
    pci_exp_txn                    : out STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
    pci_exp_txp                    : out STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
                  
    -- Rx
    pci_exp_rxn                    : in  STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
    pci_exp_rxp                    : in  STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
                  
    ---------------------------------------------------------
    -- 2. Transaction (TRN) Interface
    ---------------------------------------------------------

    -- Common
    trn_clk                        : out STD_LOGIC; 
    trn_reset_n                    : out STD_LOGIC; 
    trn_lnk_up_n                   : out STD_LOGIC; 

    -- Tx                      
    trn_tbuf_av                    : out STD_LOGIC_vector (6-1 downto 0); 
    trn_tcfg_req_n                 : out STD_LOGIC;
    trn_terr_drop_n                : out STD_LOGIC; 
    trn_tdst_rdy_n                 : out STD_LOGIC; 
    trn_td                         : in  STD_LOGIC_vector (64-1 downto 0); 
    trn_trem_n                     : in  STD_LOGIC; 
    trn_tsof_n                     : in  STD_LOGIC; 
    trn_teof_n                     : in  STD_LOGIC; 
    trn_tsrc_rdy_n                 : in  STD_LOGIC; 
    trn_tsrc_dsc_n                 : in  STD_LOGIC; 
    trn_terrfwd_n                  : in  STD_LOGIC; 
    trn_tcfg_gnt_n                 : in  STD_LOGIC; 
    trn_tstr_n                     : in  STD_LOGIC; 

    -- Rx                      
    trn_rd                         : out STD_LOGIC_vector (64-1 downto 0); 
    trn_rrem_n                     : out STD_LOGIC; 
    trn_rsof_n                     : out STD_LOGIC; 
    trn_reof_n                     : out STD_LOGIC; 
    trn_rsrc_rdy_n                 : out STD_LOGIC; 
    trn_rsrc_dsc_n                 : out STD_LOGIC; 
    trn_rerrfwd_n                  : out STD_LOGIC; 
    trn_rbar_hit_n                 : out STD_LOGIC_vector (7-1 downto 0); 
    trn_rdst_rdy_n                 : in  STD_LOGIC; 
    trn_rnp_ok_n                   : in  STD_LOGIC; 

    -- Flow Control            
    trn_fc_cpld                    : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_cplh                    : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_npd                     : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_nph                     : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_pd                      : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_ph                      : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_sel                     : in  STD_LOGIC_vector (3-1 downto 0); 
                               

    ---------------------------------------------------------
    -- 3. Configuration (CFG) Interface
    ---------------------------------------------------------

    cfg_do                         : out STD_LOGIC_vector (32-1 downto 0); 
    cfg_rd_wr_done_n               : out STD_LOGIC; 
    cfg_di                         : in  STD_LOGIC_vector (32-1 downto 0); 
    cfg_byte_en_n                  : in  STD_LOGIC_vector (4-1 downto 0); 
    cfg_dwaddr                     : in  STD_LOGIC_vector (10-1 downto 0); 
    cfg_wr_en_n                    : in  STD_LOGIC; 
    cfg_rd_en_n                    : in  STD_LOGIC; 

    cfg_err_cor_n                  : in  STD_LOGIC; 
    cfg_err_ur_n                   : in  STD_LOGIC; 
    cfg_err_ecrc_n                 : in  STD_LOGIC; 
    cfg_err_cpl_timeout_n          : in  STD_LOGIC; 
    cfg_err_cpl_abort_n            : in  STD_LOGIC; 
    cfg_err_cpl_unexpect_n         : in  STD_LOGIC; 
    cfg_err_posted_n               : in  STD_LOGIC; 
    cfg_err_locked_n               : in  STD_LOGIC; 
    cfg_err_tlp_cpl_header         : in  STD_LOGIC_vector (48-1 downto 0); 
    cfg_err_cpl_rdy_n              : out STD_LOGIC; 
    cfg_interrupt_n                : in  STD_LOGIC; 
    cfg_interrupt_rdy_n            : out STD_LOGIC; 
    cfg_interrupt_assert_n         : in  STD_LOGIC; 
    cfg_interrupt_di               : in  STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_do               : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_mmenable         : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_interrupt_msienable        : out STD_LOGIC; 
    cfg_interrupt_msixenable       : out STD_LOGIC; 
    cfg_interrupt_msixfm           : out STD_LOGIC; 
    cfg_turnoff_ok_n               : in  STD_LOGIC; 
    cfg_to_turnoff_n               : out STD_LOGIC; 
    cfg_trn_pending_n              : in  STD_LOGIC; 
    cfg_pm_wake_n                  : in  STD_LOGIC; 
    cfg_bus_number                 : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_device_number              : out STD_LOGIC_vector (5-1 downto 0); 
    cfg_function_number            : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_status                     : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_command                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand2                  : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_pcie_link_state_n          : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_dsn                        : in  STD_LOGIC_vector (64-1 downto 0); 
    cfg_pmcsr_pme_en               : out STD_LOGIC; 
    cfg_pmcsr_pme_status           : out STD_LOGIC; 
    cfg_pmcsr_powerstate           : out STD_LOGIC_vector (2-1 downto 0); 
    lnk_clk_en                     : out STD_LOGIC; 
                                

    ---------------------------------------------------------
    -- 4. Physical Layer Control and Status (PL) Interface
    ---------------------------------------------------------

    pl_initial_link_width          : out STD_LOGIC_vector (3-1 downto 0);
    pl_lane_reversal_mode          : out STD_LOGIC_vector (2-1 downto 0);
    pl_link_gen2_capable           : out STD_LOGIC;
    pl_link_partner_gen2_supported : out STD_LOGIC;
    pl_link_upcfg_capable          : out STD_LOGIC;
    pl_ltssm_state                 : out STD_LOGIC_vector (6-1 downto 0);
    pl_received_hot_rst            : out STD_LOGIC;
    pl_sel_link_rate               : out STD_LOGIC;
    pl_sel_link_width              : out STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_auton         : in  STD_LOGIC;
    pl_directed_link_change        : in  STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_speed         : in  STD_LOGIC;
    pl_directed_link_width         : in  STD_LOGIC_vector (2-1 downto 0);
    pl_upstream_prefer_deemph      : in  STD_LOGIC;


    ---------------------------------------------------------
    -- 5. System  (SYS) Interface
    ---------------------------------------------------------

    sys_clk                        : in  STD_LOGIC;
    sys_reset_n                    : in  STD_LOGIC
  );
 end component;



------------- COMPONENT Declaration: v6_pcie_v1_3 x8 ------
 component v6_pcie_v1_3x8
   generic (
         PL_FAST_TRAIN  : boolean
         );
   port (
    ---------------------------------------------------------
    -- 1. PCI Express (pci_exp) Interface
    ---------------------------------------------------------

    -- Tx
    pci_exp_txn                    : out STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
    pci_exp_txp                    : out STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
                  
    -- Rx
    pci_exp_rxn                    : in  STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
    pci_exp_rxp                    : in  STD_LOGIC_VECTOR ( pcieLanes - 1 downto 0 ); 
                  
    ---------------------------------------------------------
    -- 2. Transaction (TRN) Interface
    ---------------------------------------------------------

    -- Common
    trn_clk                        : out STD_LOGIC; 
    trn_reset_n                    : out STD_LOGIC; 
    trn_lnk_up_n                   : out STD_LOGIC; 

    -- Tx                      
    trn_tbuf_av                    : out STD_LOGIC_vector (6-1 downto 0); 
    trn_tcfg_req_n                 : out STD_LOGIC;
    trn_terr_drop_n                : out STD_LOGIC; 
    trn_tdst_rdy_n                 : out STD_LOGIC; 
    trn_td                         : in  STD_LOGIC_vector (64-1 downto 0); 
    trn_trem_n                     : in  STD_LOGIC; 
    trn_tsof_n                     : in  STD_LOGIC; 
    trn_teof_n                     : in  STD_LOGIC; 
    trn_tsrc_rdy_n                 : in  STD_LOGIC; 
    trn_tsrc_dsc_n                 : in  STD_LOGIC; 
    trn_terrfwd_n                  : in  STD_LOGIC; 
    trn_tcfg_gnt_n                 : in  STD_LOGIC; 
    trn_tstr_n                     : in  STD_LOGIC; 

    -- Rx                      
    trn_rd                         : out STD_LOGIC_vector (64-1 downto 0); 
    trn_rrem_n                     : out STD_LOGIC; 
    trn_rsof_n                     : out STD_LOGIC; 
    trn_reof_n                     : out STD_LOGIC; 
    trn_rsrc_rdy_n                 : out STD_LOGIC; 
    trn_rsrc_dsc_n                 : out STD_LOGIC; 
    trn_rerrfwd_n                  : out STD_LOGIC; 
    trn_rbar_hit_n                 : out STD_LOGIC_vector (7-1 downto 0); 
    trn_rdst_rdy_n                 : in  STD_LOGIC; 
    trn_rnp_ok_n                   : in  STD_LOGIC; 

    -- Flow Control            
    trn_fc_cpld                    : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_cplh                    : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_npd                     : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_nph                     : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_pd                      : out STD_LOGIC_vector (12-1 downto 0); 
    trn_fc_ph                      : out STD_LOGIC_vector (8-1 downto 0); 
    trn_fc_sel                     : in  STD_LOGIC_vector (3-1 downto 0); 
                               

    ---------------------------------------------------------
    -- 3. Configuration (CFG) Interface
    ---------------------------------------------------------

    cfg_do                         : out STD_LOGIC_vector (32-1 downto 0); 
    cfg_rd_wr_done_n               : out STD_LOGIC; 
    cfg_di                         : in  STD_LOGIC_vector (32-1 downto 0); 
    cfg_byte_en_n                  : in  STD_LOGIC_vector (4-1 downto 0); 
    cfg_dwaddr                     : in  STD_LOGIC_vector (10-1 downto 0); 
    cfg_wr_en_n                    : in  STD_LOGIC; 
    cfg_rd_en_n                    : in  STD_LOGIC; 

    cfg_err_cor_n                  : in  STD_LOGIC; 
    cfg_err_ur_n                   : in  STD_LOGIC; 
    cfg_err_ecrc_n                 : in  STD_LOGIC; 
    cfg_err_cpl_timeout_n          : in  STD_LOGIC; 
    cfg_err_cpl_abort_n            : in  STD_LOGIC; 
    cfg_err_cpl_unexpect_n         : in  STD_LOGIC; 
    cfg_err_posted_n               : in  STD_LOGIC; 
    cfg_err_locked_n               : in  STD_LOGIC; 
    cfg_err_tlp_cpl_header         : in  STD_LOGIC_vector (48-1 downto 0); 
    cfg_err_cpl_rdy_n              : out STD_LOGIC; 
    cfg_interrupt_n                : in  STD_LOGIC; 
    cfg_interrupt_rdy_n            : out STD_LOGIC; 
    cfg_interrupt_assert_n         : in  STD_LOGIC; 
    cfg_interrupt_di               : in  STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_do               : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_interrupt_mmenable         : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_interrupt_msienable        : out STD_LOGIC; 
    cfg_interrupt_msixenable       : out STD_LOGIC; 
    cfg_interrupt_msixfm           : out STD_LOGIC; 
    cfg_turnoff_ok_n               : in  STD_LOGIC; 
    cfg_to_turnoff_n               : out STD_LOGIC; 
    cfg_trn_pending_n              : in  STD_LOGIC; 
    cfg_pm_wake_n                  : in  STD_LOGIC; 
    cfg_bus_number                 : out STD_LOGIC_vector (8-1 downto 0); 
    cfg_device_number              : out STD_LOGIC_vector (5-1 downto 0); 
    cfg_function_number            : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_status                     : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_command                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lstatus                    : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_lcommand                   : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_dcommand2                  : out STD_LOGIC_vector (16-1 downto 0); 
    cfg_pcie_link_state_n          : out STD_LOGIC_vector (3-1 downto 0); 
    cfg_dsn                        : in  STD_LOGIC_vector (64-1 downto 0); 
    cfg_pmcsr_pme_en               : out STD_LOGIC; 
    cfg_pmcsr_pme_status           : out STD_LOGIC; 
    cfg_pmcsr_powerstate           : out STD_LOGIC_vector (2-1 downto 0); 
    lnk_clk_en                     : out STD_LOGIC; 
                                

    ---------------------------------------------------------
    -- 4. Physical Layer Control and Status (PL) Interface
    ---------------------------------------------------------

    pl_initial_link_width          : out STD_LOGIC_vector (3-1 downto 0);
    pl_lane_reversal_mode          : out STD_LOGIC_vector (2-1 downto 0);
    pl_link_gen2_capable           : out STD_LOGIC;
    pl_link_partner_gen2_supported : out STD_LOGIC;
    pl_link_upcfg_capable          : out STD_LOGIC;
    pl_ltssm_state                 : out STD_LOGIC_vector (6-1 downto 0);
    pl_received_hot_rst            : out STD_LOGIC;
    pl_sel_link_rate               : out STD_LOGIC;
    pl_sel_link_width              : out STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_auton         : in  STD_LOGIC;
    pl_directed_link_change        : in  STD_LOGIC_vector (2-1 downto 0);
    pl_directed_link_speed         : in  STD_LOGIC;
    pl_directed_link_width         : in  STD_LOGIC_vector (2-1 downto 0);
    pl_upstream_prefer_deemph      : in  STD_LOGIC;


    ---------------------------------------------------------
    -- 5. System  (SYS) Interface
    ---------------------------------------------------------

    sys_clk                        : in  STD_LOGIC;
    sys_reset_n                    : in  STD_LOGIC
  );
 end component;


--
--   signal ddr2_sys_clk_i               : std_logic;
--   signal idelay_value_counter         : std_logic_vector(6-1 downto 0);
--   signal idelay_calibrate_successful  : std_logic;
   signal fifo_reset_done              : std_logic;
--   signal failure_read                 : std_logic;
   signal pio_reading_status           : std_logic;


-- -----------------------------------------------------------------------
--  DDR SDRAM control module
--   1 or 2 DDR RAM modules are used
--
   COMPONENT bram_DDRs_Control
   GENERIC (
             C_ASYNFIFO_WIDTH  :  integer ;
             P_SIMULATION      :  boolean
            );
   PORT (


      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      DDR_wr_sof               : IN    std_logic;
      DDR_wr_eof               : IN    std_logic;
      DDR_wr_v                 : IN    std_logic;
      DDR_wr_FA                : IN    std_logic;
      DDR_wr_Shift             : IN    std_logic;
      DDR_wr_Mask              : IN    std_logic_vector(2-1 downto 0);
      DDR_wr_din               : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_wr_full              : OUT   std_logic;

      DDR_rdc_sof              : IN    std_logic;
      DDR_rdc_eof              : IN    std_logic;
      DDR_rdc_v                : IN    std_logic;
      DDR_rdc_FA               : IN    std_logic;
      DDR_rdc_Shift            : IN    std_logic;
      DDR_rdc_din              : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_rdc_full             : OUT   std_logic;

      -- DDR payload FIFO Read Port
      DDR_FIFO_RdEn            : IN    std_logic;
      DDR_FIFO_Empty           : OUT   std_logic;
      DDR_FIFO_RdQout          : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
--      DDR_rdD_sof              : OUT   std_logic;
--      DDR_rdD_eof              : OUT   std_logic;
--      DDR_rdDout_V             : OUT   std_logic;
--      DDR_rdDout               : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      -- Common interface
      DDR_Ready                : OUT   std_logic;
      DDR_Blinker              : OUT   std_logic;
      mem_clk                  : IN    std_logic;
      trn_clk                  : IN    std_logic;
      trn_reset_n              : IN    std_logic
    );
   END COMPONENT;

   signal    DDR_wr_sof               :  std_logic;
   signal    DDR_wr_eof               :  std_logic;
   signal    DDR_wr_v                 :  std_logic;
   signal    DDR_wr_FA                :  std_logic;
   signal    DDR_wr_Shift             :  std_logic;
   signal    DDR_wr_Mask              :  std_logic_vector(2-1 downto 0);
   signal    DDR_wr_din               :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal    DDR_wr_full              :  std_logic;

   signal    DDR_rdc_sof              :  std_logic;
   signal    DDR_rdc_eof              :  std_logic;
   signal    DDR_rdc_v                :  std_logic;
   signal    DDR_rdc_FA               :  std_logic;
   signal    DDR_rdc_Shift            :  std_logic;
   signal    DDR_rdc_din              :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal    DDR_rdc_full             :  std_logic;

   signal    DDR_FIFO_RdEn            :  std_logic; 
   signal    DDR_FIFO_Empty           :  std_logic;
   signal    DDR_FIFO_RdQout          :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

--   signal    DDR_rdD_sof              :  std_logic;
--   signal    DDR_rdD_eof              :  std_logic;
--   signal    DDR_rdDout_V             :  std_logic;
--   signal    DDR_rdDout               :  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

   signal    DDR_Ready                :  std_logic;
   signal    DDR_Blinker              :  std_logic;

--   signal    mem_clk                  :  std_logic;

   -- -----------------------------------------------------------------------
   -- FIFO module
   --      16K x 8B
   component eb_wrapper
     port (
           wr_clk      : IN  std_logic;
           wr_en       : IN  std_logic;
           din         : IN  std_logic_VECTOR(72-1 downto 0);
           pfull       : OUT std_logic;
           full        : OUT std_logic;

           rd_clk      : IN  std_logic;
           rd_en       : IN  std_logic;
           dout        : OUT std_logic_VECTOR(72-1 downto 0);
           pempty      : OUT std_logic;
           empty       : OUT std_logic;

           data_count  : OUT std_logic_VECTOR(C_EMU_FIFO_DC_WIDTH-1 downto 0);
           rst         : IN  std_logic
           );
   end component;

   signal  eb_wclk            :  std_logic;
   signal  eb_we              :  std_logic;
   signal  eb_wsof            :  std_logic;
   signal  eb_weof            :  std_logic;
   signal  eb_din             :  std_logic_VECTOR(72-1 downto 0);
   signal  eb_pfull           :  std_logic;
   signal  eb_full            :  std_logic;
   signal  eb_rclk            :  std_logic;
   signal  eb_re              :  std_logic;
   signal  eb_dout            :  std_logic_VECTOR(72-1 downto 0);
   signal  eb_pempty          :  std_logic;
   signal  eb_empty           :  std_logic;
   signal  eb_rst             :  std_logic;
   signal  eb_FIFO_Status     :  std_logic_VECTOR(C_DBUS_WIDTH-1 downto 0);
   signal  eb_data_count      :  std_logic_vector(C_FIFO_DC_WIDTH downto 0);
   signal  pio_read_status    :  std_logic;
   signal  eb_FIFO_ow         :  std_logic;

   signal  eb_we_up           :  std_logic;
   signal  eb_din_up          :  std_logic_VECTOR(72-1 downto 0);


   signal  tab_sel            : STD_LOGIC;
   signal  tab_we             : STD_LOGIC_VECTOR (2-1 downto 0);
   signal  tab_wa             : STD_LOGIC_VECTOR (12-1 downto 0);
   signal  tab_wd             : STD_LOGIC_VECTOR (C_DBUS_WIDTH-1 downto 0);

   signal  dg_running         : STD_LOGIC;
   signal  dg_mask            : STD_LOGIC;
   signal  dg_rst             : STD_LOGIC;

   -- debug signal
   signal  dg_debug_led       : STD_LOGIC;

   -- Protocol Interface module
   COMPONENT protocol_IF
   PORT (
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

           -- DLM Tx
           dlm2send_va              : OUT   std_logic;
           dlm2send_type            : OUT   std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               : IN    std_logic;
           dlm_rec_type             : IN    std_logic_vector(4-1 downto 0);

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

           -- Fabric side: DLM Rx
           dlm_rv                   : IN    std_logic;
           dlm_rd                   : IN    std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

           -- Fabric side: DLM Tx
           dlm_tv                   : OUT   std_logic;
           dlm_td                   : OUT   std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

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
   END COMPONENT;

   -- DAQ Tx
   signal  data2send_start          : std_logic;
   signal  data2send_end            : std_logic;
   signal  data2send                : std_logic_vector(64-1 downto 0);
   signal  crc_error_send           : std_logic;
   signal  data2send_stop           : std_logic
                                    := '0';

   -- DAQ Rx
   signal  data_rec_start           : std_logic;
   signal  data_rec_end             : std_logic;
   signal  data_rec                 : std_logic_vector(64-1 downto 0);
   signal  crc_error_rec            : std_logic;
   signal  data_rec_stop            : std_logic;

   -- CTL Tx
   signal  ctrl2send_start          : std_logic;
   signal  ctrl2send_end            : std_logic;
   signal  ctrl2send                : std_logic_vector(16-1 downto 0);
   signal  ctrl2send_stop           : std_logic;

   -- CTL Rx
   signal  ctrl_rec_start           : std_logic;
   signal  ctrl_rec_end             : std_logic;
   signal  ctrl_rec                 : std_logic_vector(16-1 downto 0);
   signal  ctrl_rec_stop            : std_logic;

   -- DLM Tx
   signal  dlm2send_va              : std_logic;
   signal  dlm2send_type            : std_logic_vector(4-1 downto 0);

   -- DLM Rx
   signal  dlm_rec_va               : std_logic;
   signal  dlm_rec_type             : std_logic_vector(4-1 downto 0);


   -- Common signals
   signal  link_rx_clk              : std_logic;
   signal  link_tx_clk              : std_logic;
   signal  link_active              : std_logic_vector(2-1 downto 0);
   signal  protocol_clk             : std_logic;
   signal  protocol_res_n           : std_logic;


   -- Fabric side: DAQ Rx
   signal  daq_rv                   : std_logic;
   signal  daq_rsof                 : std_logic;
   signal  daq_reof                 : std_logic;
   signal  daq_rd                   : std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal  daq_rstop                : std_logic;

   -- Fabric side: DAQ Tx
   signal  daq_tv                   : std_logic;
   signal  daq_tsof                 : std_logic;
   signal  daq_teof                 : std_logic;
   signal  daq_td                   : std_logic_vector(C_DBUS_WIDTH-1 downto 0);
   signal  daq_tstop                : std_logic;

   -- Fabric side: DLM Rx
   signal  dlm_rv                   : std_logic;
   signal  dlm_rd                   : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

   -- Fabric side: DLM Tx
   signal  dlm_tv                   : std_logic;
   signal  dlm_td                   : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

   -- Fabric side: CTL Rx
   signal  ctl_rv                   : std_logic;
   signal  ctl_rd                   : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  ctl_rstop                : std_logic;

   -- Fabric side: CTL Tx
   signal  ctl_ttake                : std_logic;
   signal  ctl_tv                   : std_logic;
   signal  ctl_td                   : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
   signal  ctl_tstop                : std_logic;

   signal  ctl_reset                : std_logic;
   signal  ctl_status               : std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

   -- Interrupter triggers
   signal  DAQ_irq                  : std_logic;
   signal  CTL_irq                  : std_logic;
   signal  DLM_irq                  : std_logic;

   -- Fabric side: Common signals
   signal  protocol_link_act        : std_logic_vector(2-1 downto 0);
   signal  protocol_rst             : std_logic;


   -- Pseudo link module, to be replaced by the real optical link
   COMPONENT pseudo_protocol_module
   PORT (
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

         -- dummy pin input
         dummy_pin_in             : IN    std_logic_vector(3-1 downto 0);

         -- Common interface
         link_tx_clk              : OUT   std_logic;
         link_rx_clk              : OUT   std_logic;
         link_active              : OUT   std_logic_vector(2-1 downto 0);
         clk                      : IN    std_logic;
         res_n                    : IN    std_logic
    );
   END COMPONENT;


   signal  Link_Buf_full             : std_logic;


------------- COMPONENT Declaration: tlpControl   ------
-- 
 component tlpControl 
   port (
        --  Test pin, emulating DDR data flow discontinuity
        mbuf_UserFull                : IN  std_logic;
        trn_Blinker                  : OUT std_logic;

        -- DCB protocol interface
        protocol_link_act            : IN  std_logic_vector(2-1 downto 0);
        protocol_rst                 : OUT std_logic;

        -- Interrupter triggers
        DAQ_irq                      : IN  std_logic;
        CTL_irq                      : IN  std_logic;
        DLM_irq                      : IN  std_logic;

        -- Fabric side: CTL Rx
        ctl_rv                       : OUT std_logic;
        ctl_rd                       : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- Fabric side: CTL Tx
        ctl_ttake                    : OUT std_logic;
        ctl_tv                       : IN  std_logic;
        ctl_td                       : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
        ctl_tstop                    : OUT std_logic;

        ctl_reset                    : OUT std_logic;
        ctl_status                   : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- Fabric side: DLM Rx
        dlm_rv                       : OUT std_logic;
        dlm_rd                       : OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        -- Fabric side: DLM Tx
        dlm_tv                       : IN  std_logic;
        dlm_td                       : IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);

        Link_Buf_full                : IN  std_logic;

        -- Event Buffer FIFO interface
        eb_FIFO_we                   : OUT std_logic; 
        eb_FIFO_wsof                 : OUT std_logic; 
        eb_FIFO_weof                 : OUT std_logic; 
        eb_FIFO_din                  : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        eb_FIFO_re                   : OUT std_logic; 
        eb_FIFO_empty                : IN  std_logic; 
        eb_FIFO_qout                 : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        eb_FIFO_data_count           : IN  std_logic_vector(C_FIFO_DC_WIDTH downto 0);

        eb_FIFO_ow                   : IN  std_logic;

        pio_reading_status           : OUT std_logic; 
        eb_FIFO_Status               : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        eb_FIFO_Rst                  : OUT std_logic;

        -- Debugging signals
        DMA_us_Done                  : OUT std_logic;
        DMA_us_Busy                  : OUT std_logic;
        DMA_us_Busy_LED              : OUT std_logic;
        DMA_ds_Done                  : OUT std_logic;
        DMA_ds_Busy                  : OUT std_logic;
        DMA_ds_Busy_LED              : OUT std_logic;

        -- DDR control interface
        DDR_Ready                    : IN    std_logic;

        DDR_wr_sof                   : OUT   std_logic;
        DDR_wr_eof                   : OUT   std_logic;
        DDR_wr_v                     : OUT   std_logic;
        DDR_wr_FA                    : OUT   std_logic;
        DDR_wr_Shift                 : OUT   std_logic;
        DDR_wr_Mask                  : OUT   std_logic_vector(2-1 downto 0);
        DDR_wr_din                   : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        DDR_wr_full                  : IN    std_logic;

        DDR_rdc_sof                  : OUT   std_logic;
        DDR_rdc_eof                  : OUT   std_logic;
        DDR_rdc_v                    : OUT   std_logic;
        DDR_rdc_FA                   : OUT   std_logic;
        DDR_rdc_Shift                : OUT   std_logic;
        DDR_rdc_din                  : OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
        DDR_rdc_full                 : IN    std_logic;

--        DDR_rdD_sof                  : IN    std_logic;
--        DDR_rdD_eof                  : IN    std_logic;
--        DDR_rdDout_V                 : IN    std_logic;
--        DDR_rdDout                   : IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        -- DDR payload FIFO Read Port
        DDR_FIFO_RdEn                : OUT std_logic; 
        DDR_FIFO_Empty               : IN  std_logic;
        DDR_FIFO_RdQout              : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        -- Data generator table write
        tab_we                       : OUT std_logic_vector(2-1 downto 0);
        tab_wa                       : OUT std_logic_vector(12-1 downto 0);
        tab_wd                       : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        -- Data generator control
        DG_is_Running                : IN  std_logic;
        DG_Reset                     : OUT std_logic;
        DG_Mask                      : OUT std_logic;

        -- Transaction layer interface
        trn_lnk_up_n                 : IN  std_logic;
        trn_rsrc_dsc_n               : IN  std_logic;
        trn_rnp_ok_n                 : OUT std_logic;
        trn_tsrc_dsc_n               : OUT std_logic;
        trn_tdst_dsc_n               : IN  std_logic;
        trn_tbuf_av                  : IN  std_logic_vector(C_TBUF_AWIDTH-1 downto 0);
        trn_terrfwd_n                : OUT std_logic;

        trn_clk                      : IN  std_logic;
        trn_reset_n                  : IN  std_logic;
        trn_rsrc_rdy_n               : IN  std_logic;
        trn_tdst_rdy_n               : IN  std_logic;
        trn_rsof_n                   : IN  std_logic;
        trn_reof_n                   : IN  std_logic;
        trn_rerrfwd_n                : IN  std_logic;
        trn_rrem_n                   : IN  std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
        trn_rd                       : IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

        cfg_dcommand                 : IN  std_logic_vector(15 downto 0);
        pcie_link_width              : IN  std_logic_vector( 5 downto 0);
        localId                      : IN  std_logic_vector(15 downto 0);

        cfg_interrupt_n              : OUT std_logic;
        cfg_interrupt_rdy_n          : IN  std_logic;
        cfg_interrupt_mmenable       : IN  std_logic_vector(2 downto 0);
        cfg_interrupt_msienable      : IN  std_logic;
        cfg_interrupt_di             : OUT std_logic_vector(7 downto 0);
        cfg_interrupt_do             : IN  std_logic_vector(7 downto 0);
        cfg_interrupt_assert_n       : OUT std_logic;

        Format_Shower                : OUT   std_logic;

        trn_rbar_hit_n               : IN  std_logic_vector(6 downto 0);
        trn_tsrc_rdy_n               : OUT std_logic;
        trn_rdst_rdy_n               : OUT std_logic;
        trn_tsof_n                   : OUT std_logic;
        trn_teof_n                   : OUT std_logic;
        trn_trem_n                   : OUT std_logic_vector(C_DBUS_WIDTH/8-1 downto 0);
        trn_td                       : OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0)
        );
 end component;

 signal   Format_Shower              : std_logic;

-- component BUFG is
--   port(
--        I : IN  std_logic;
--        O : OUT std_logic
--        );
-- end component;
--
-- component IBUF is
--   port(
--        i : IN  std_logic;
--        o : OUT std_logic
--        );
-- end component;
--
-- component IBUFDS is
--   port(
--        i  : IN  std_logic;
--        ib : IN  std_logic;
--        o  : OUT std_logic
--        );
-- end component;
--
-- component GT11CLK_MGT is
--   port(   
--        mgtclkp     : IN  std_logic;
--        mgtclkn     : IN  std_logic;
--        synclk1out  : OUT std_logic;
--        synclk2out  : OUT std_logic
--        );
-- end component;


  -- TRN Layer signals

  signal trn_terr_drop_n                 : std_logic;
  signal trn_tcfg_gnt_n                  : std_logic;
  signal trn_tstr_n                      : std_logic;
  signal trn_fc_cpld                     : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_cplh                     : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_npd                      : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_nph                      : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_pd                       : STD_LOGIC_vector (12-1 downto 0); 
  signal trn_fc_ph                       : STD_LOGIC_vector (8-1 downto 0); 
  signal trn_fc_sel                      : STD_LOGIC_vector (3-1 downto 0); 
                                    
  signal cfg_interrupt_msixenable        : std_logic;
  signal cfg_interrupt_msixfm            : std_logic;
  signal cfg_dcommand2                   : std_logic_vector (16-1 downto 0);
  signal trn_tcfg_req_n                  : std_logic;
                                  

  signal  pl_initial_link_width          : STD_LOGIC_vector (3-1 downto 0);
  signal  pl_lane_reversal_mode          : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_link_gen2_capable           : STD_LOGIC;
  signal  pl_link_partner_gen2_supported : STD_LOGIC;
  signal  pl_link_upcfg_capable          : STD_LOGIC;
  signal  pl_ltssm_state                 : STD_LOGIC_vector (6-1 downto 0);
  signal  pl_received_hot_rst            : STD_LOGIC;
  signal  pl_sel_link_rate               : STD_LOGIC;
  signal  pl_sel_link_width              : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_directed_link_auton         : STD_LOGIC;
  signal  pl_directed_link_change        : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_directed_link_speed         : STD_LOGIC;
  signal  pl_directed_link_width         : STD_LOGIC_vector (2-1 downto 0);
  signal  pl_upstream_prefer_deemph      : STD_LOGIC;

  signal  trn_reset_n_int1       : STD_LOGIC;
  signal  trn_lnk_up_n_int1      : STD_LOGIC;



  signal trn_clk                     : std_logic;
  signal trn_reset_n                 : std_logic;
  signal trn_lnk_up_n                : std_logic;
  signal trn_td                      : std_logic_vector(63 downto 0);
  signal trn_trem_n                  : std_logic_vector(7 downto 0);
  signal trn_tsof_n                  : std_logic;
  signal trn_teof_n                  : std_logic;
  signal trn_tsrc_rdy_n              : std_logic;
  signal trn_tdst_rdy_n              : std_logic;
  signal trn_tdst_dsc_n              : std_logic;
  signal trn_tsrc_dsc_n              : std_logic;
  signal trn_terrfwd_n               : std_logic;
  signal trn_tbuf_av                 : std_logic_vector(5 downto 0);
  signal trn_rd                      : std_logic_vector(63 downto 0);
  signal trn_rrem_n                  : std_logic_vector(7 downto 0);
  signal trn_rsof_n                  : std_logic;
  signal trn_reof_n                  : std_logic;
  signal trn_rsrc_rdy_n              : std_logic;
  signal trn_rsrc_dsc_n              : std_logic;
  signal trn_rdst_rdy_n              : std_logic;
  signal trn_rerrfwd_n               : std_logic;
  signal trn_rnp_ok_n                : std_logic;
  signal trn_rbar_hit_n              : std_logic_vector(6 downto 0);
  signal trn_rfc_nph_av              : std_logic_vector(7 downto 0);
  signal trn_rfc_npd_av              : std_logic_vector(11 downto 0);
  signal trn_rfc_ph_av               : std_logic_vector(7 downto 0);
  signal trn_rfc_pd_av               : std_logic_vector(11 downto 0);
  signal trn_rfc_cplh_av             : std_logic_vector(7 downto 0);
  signal trn_rfc_cpld_av             : std_logic_vector(11 downto 0);
  signal trn_rcpl_streaming_n        : std_logic;
  signal cfg_do                      : std_logic_vector(31 downto 0);
  signal cfg_rd_wr_done_n            : std_logic;
  signal cfg_di                      : std_logic_vector(31 downto 0);
  signal cfg_byte_en_n               : std_logic_vector(3 downto 0);
  signal cfg_dwaddr                  : std_logic_vector(9 downto 0);
  signal cfg_wr_en_n                 : std_logic;
  signal cfg_rd_en_n                 : std_logic;
  signal cfg_err_cor_n               : std_logic;
  signal cfg_err_ur_n                : std_logic;
  signal cfg_err_cpl_rdy_n           : std_logic;
  signal cfg_err_ecrc_n              : std_logic;
  signal cfg_err_cpl_timeout_n       : std_logic;
  signal cfg_err_cpl_abort_n         : std_logic;
  signal cfg_err_cpl_unexpect_n      : std_logic;
  signal cfg_err_posted_n            : std_logic;
  signal cfg_err_locked_n            : std_logic;
  signal cfg_err_tlp_cpl_header      : std_logic_vector(47 downto 0);
  signal cfg_interrupt_n             : std_logic;
  signal cfg_interrupt_rdy_n         : std_logic;
  signal cfg_interrupt_mmenable      : std_logic_vector(2 downto 0);
  signal cfg_interrupt_msienable     : std_logic;
  signal cfg_interrupt_di            : std_logic_vector(7 downto 0);
  signal cfg_interrupt_do            : std_logic_vector(7 downto 0);
  signal cfg_interrupt_assert_n      : std_logic;
  signal cfg_turnoff_ok_n            : std_logic;
  signal cfg_to_turnoff_n            : std_logic;
  signal cfg_pm_wake_n               : std_logic;
  signal cfg_pcie_link_state_n       : std_logic_vector(2 downto 0);
  signal cfg_trn_pending_n           : std_logic;
  signal cfg_bus_number              : std_logic_vector(7 downto 0);
  signal cfg_device_number           : std_logic_vector(4 downto 0);
  signal cfg_function_number         : std_logic_vector(2 downto 0);
  signal cfg_dsn                     : std_logic_vector(63 downto 0);
  signal cfg_status                  : std_logic_vector(15 downto 0);
  signal cfg_command                 : std_logic_vector(15 downto 0);
  signal cfg_dstatus                 : std_logic_vector(15 downto 0);
  signal cfg_dcommand                : std_logic_vector(15 downto 0);
  signal cfg_lstatus                 : std_logic_vector(15 downto 0);
  signal cfg_lcommand                : std_logic_vector(15 downto 0);
  signal fast_train_simulation_only  : std_logic;
  signal two_plm_auto_config         : std_logic_vector(1 downto 0);
  signal sys_clk_c                   : std_logic;
  signal sys_reset_n_c               : std_logic;
  signal reset_n                     : std_logic;

  signal localId                     : std_logic_vector(15 downto 0);
  signal pcie_link_width             : std_logic_vector( 5 downto 0);

  signal synclk2out                  : std_logic;


  --
  signal   trn_Blinker          : std_logic;


begin


   sys_reset_n_ibuf : IBUF
      port map (
                 O      =>  sys_reset_n_c,
                 I      =>  sys_reset_n
                );

   refclk_ibuf : IBUFDS_GTXE1
      port map (
                 O      =>  sys_clk_c,
                 ODIV2  =>  open,
                 I      =>  sys_clk_p,
                 IB     =>  sys_clk_n,
                 CEB    =>  '0'
                );

--   refclk_ibuf : IBUFDS 
--      port map (
--                 O  => sys_clk,
--                 I  => sys_clk_p,
--                 IB => sys_clk_n
--                );

--   ddr_sys_clk_bufg : BUFG
--      PORT MAP ( I  => ddr2_sys_clk,
--                 O  => ddr2_sys_clk_i
--                );


--
--
   cfg_err_cor_n              <= '1';
   cfg_err_ur_n               <= '1';
   cfg_err_ecrc_n             <= '1';
   cfg_err_cpl_timeout_n      <= '1';
   cfg_err_cpl_abort_n        <= '1';
   cfg_err_cpl_unexpect_n     <= '1';
   cfg_err_posted_n           <= '0';
   cfg_err_locked_n           <= '0';
   cfg_err_tlp_cpl_header     <= (OTHERS=>'0');
   cfg_trn_pending_n          <= '1';
   cfg_pm_wake_n              <= '1';
                           

-- 
   trn_fc_sel                 <= (OTHERS=>'0');

   pl_directed_link_auton     <= '0';
   pl_directed_link_change    <= (OTHERS=>'0');
   pl_directed_link_speed     <= '0';
   pl_directed_link_width     <= (OTHERS=>'0');
   pl_upstream_prefer_deemph  <= '0';

   trn_tcfg_gnt_n             <= '0';
   trn_tstr_n                 <= '0';  -- '1';
                       
-- 

   trn_tdst_dsc_n             <= '1';

--
   cfg_di                     <= (OTHERS=>'0');
   cfg_dwaddr                 <= (OTHERS=>'1');
   cfg_byte_en_n              <= (OTHERS=>'1');
   cfg_wr_en_n                <= '1';
   cfg_rd_en_n                <= '1';
   cfg_dsn      <= X"00000001" &  X"01" & X"000A35";   -- //this is taken from GUI -

   cfg_turnoff_ok_n           <= '0';


   localId                    <= cfg_bus_number & cfg_device_number & cfg_function_number;

   pcie_link_width            <= cfg_lstatus(9 downto 4);



   trn_lnk_up_n_int_i: FDCP
     generic map (
                 INIT  => '1'
             )
     port map (
               Q     =>  trn_lnk_up_n,
               D     =>  trn_lnk_up_n_int1,
               C     =>  trn_clk,
               CLR   =>  '0',
               PRE   =>  '0'
              );


   trn_reset_n_i: FDCP
     generic map (
                 INIT  => '1'
              )
     port map (
               Q     =>  trn_reset_n,
               D     =>  trn_reset_n_int1,
               C     =>  trn_clk,
               CLR   =>  '0',
               PRE   =>  '0'
              );


-- --------------------------------------------------------------
-- --------------------------------------------------------------

make4Lanes: if pcieLanes = 4 generate
  pcieCore : v6_pcie_v1_3
    generic map (
                 PL_FAST_TRAIN  => FALSE
             )
    port map (

      ---------------------------------------------------------
      -- 1. PCI Express (pci_exp) Interface
      ---------------------------------------------------------

      -- Tx
      pci_exp_txp       =>     pci_exp_txp           ,
      pci_exp_txn       =>     pci_exp_txn           ,

      -- Rx
      pci_exp_rxp       =>     pci_exp_rxp           ,
      pci_exp_rxn       =>     pci_exp_rxn           ,
                                             
      ---------------------------------------------------------
      -- 2. Transaction (TRN) Interface
      ---------------------------------------------------------

      -- Common
      trn_clk           =>     trn_clk               ,
      trn_reset_n       =>     trn_reset_n_int1      ,
      trn_lnk_up_n      =>     trn_lnk_up_n_int1     ,

      -- Tx
      trn_tbuf_av       =>     trn_tbuf_av           ,
      trn_tcfg_req_n    =>     trn_tcfg_req_n        ,
      trn_terr_drop_n   =>     trn_terr_drop_n       ,
      trn_tdst_rdy_n    =>     trn_tdst_rdy_n        ,
      trn_td            =>     trn_td                ,
      trn_trem_n        =>     trn_trem_n(0)         ,
      trn_tsof_n        =>     trn_tsof_n            ,
      trn_teof_n        =>     trn_teof_n            ,
      trn_tsrc_rdy_n    =>     trn_tsrc_rdy_n        ,
      trn_tsrc_dsc_n    =>     trn_tsrc_dsc_n        ,
      trn_terrfwd_n     =>     trn_terrfwd_n         ,
      trn_tcfg_gnt_n    =>     trn_tcfg_gnt_n        ,
      trn_tstr_n        =>     trn_tstr_n            ,

      -- Rx
      trn_rd            =>     trn_rd                ,
      trn_rrem_n        =>     trn_rrem_n(0)         ,
      trn_rsof_n        =>     trn_rsof_n            ,
      trn_reof_n        =>     trn_reof_n            ,
      trn_rsrc_rdy_n    =>     trn_rsrc_rdy_n        ,
      trn_rsrc_dsc_n    =>     trn_rsrc_dsc_n        ,
      trn_rerrfwd_n     =>     trn_rerrfwd_n         ,
      trn_rbar_hit_n    =>     trn_rbar_hit_n        ,
      trn_rdst_rdy_n    =>     trn_rdst_rdy_n        ,
      trn_rnp_ok_n      =>     trn_rnp_ok_n          ,

      -- Flow Control
      trn_fc_cpld       =>     trn_fc_cpld           ,
      trn_fc_cplh       =>     trn_fc_cplh           ,
      trn_fc_npd        =>     trn_fc_npd            ,
      trn_fc_nph        =>     trn_fc_nph            ,
      trn_fc_pd         =>     trn_fc_pd             ,
      trn_fc_ph         =>     trn_fc_ph             ,
      trn_fc_sel        =>     trn_fc_sel            ,


      ---------------------------------------------------------
      -- 3. Configuration (CFG) Interface
      ---------------------------------------------------------

      cfg_do                   =>     cfg_do                     ,
      cfg_rd_wr_done_n         =>     cfg_rd_wr_done_n           ,
      cfg_di                   =>     cfg_di                     ,
      cfg_byte_en_n            =>     cfg_byte_en_n              ,
      cfg_dwaddr               =>     cfg_dwaddr                 ,
      cfg_wr_en_n              =>     cfg_wr_en_n                ,
      cfg_rd_en_n              =>     cfg_rd_en_n                ,

      cfg_err_cor_n            =>     cfg_err_cor_n              ,
      cfg_err_ur_n             =>     cfg_err_ur_n               ,
      cfg_err_ecrc_n           =>     cfg_err_ecrc_n             ,
      cfg_err_cpl_timeout_n    =>     cfg_err_cpl_timeout_n      ,
      cfg_err_cpl_abort_n      =>     cfg_err_cpl_abort_n        ,
      cfg_err_cpl_unexpect_n   =>     cfg_err_cpl_unexpect_n     ,
      cfg_err_posted_n         =>     cfg_err_posted_n           ,
      cfg_err_locked_n         =>     cfg_err_locked_n           ,
      cfg_err_tlp_cpl_header   =>     cfg_err_tlp_cpl_header     ,
      cfg_err_cpl_rdy_n        =>     cfg_err_cpl_rdy_n          ,
      cfg_interrupt_n          =>     cfg_interrupt_n            ,
      cfg_interrupt_rdy_n      =>     cfg_interrupt_rdy_n        ,
      cfg_interrupt_assert_n   =>     cfg_interrupt_assert_n     ,
      cfg_interrupt_di         =>     cfg_interrupt_di           ,
      cfg_interrupt_do         =>     cfg_interrupt_do           ,
      cfg_interrupt_mmenable   =>     cfg_interrupt_mmenable     ,
      cfg_interrupt_msienable  =>     cfg_interrupt_msienable    ,
      cfg_interrupt_msixenable =>     cfg_interrupt_msixenable   ,
      cfg_interrupt_msixfm     =>     cfg_interrupt_msixfm       ,
      cfg_turnoff_ok_n         =>     cfg_turnoff_ok_n           ,
      cfg_to_turnoff_n         =>     cfg_to_turnoff_n           ,
      cfg_trn_pending_n        =>     cfg_trn_pending_n          ,
      cfg_pm_wake_n            =>     cfg_pm_wake_n              ,
      cfg_bus_number           =>     cfg_bus_number             ,
      cfg_device_number        =>     cfg_device_number          ,
      cfg_function_number      =>     cfg_function_number        ,
      cfg_status               =>     cfg_status                 ,
      cfg_command              =>     cfg_command                ,
      cfg_dstatus              =>     cfg_dstatus                ,
      cfg_dcommand             =>     cfg_dcommand               ,
      cfg_lstatus              =>     cfg_lstatus                ,
      cfg_lcommand             =>     cfg_lcommand               ,
      cfg_dcommand2            =>     cfg_dcommand2              ,
      cfg_pcie_link_state_n    =>     cfg_pcie_link_state_n      ,
      cfg_dsn                  =>     cfg_dsn                    ,

      ---------------------------------------------------------
      -- 4. Physical Layer Control and Status (PL) Interface
      ---------------------------------------------------------

      pl_initial_link_width            =>     pl_initial_link_width           ,
      pl_lane_reversal_mode            =>     pl_lane_reversal_mode           ,
      pl_link_gen2_capable             =>     pl_link_gen2_capable            ,
      pl_link_partner_gen2_supported   =>     pl_link_partner_gen2_supported  ,
      pl_link_upcfg_capable            =>     pl_link_upcfg_capable           ,
      pl_ltssm_state                   =>     pl_ltssm_state                  ,
      pl_received_hot_rst              =>     pl_received_hot_rst             ,
      pl_sel_link_rate                 =>     pl_sel_link_rate                ,
      pl_sel_link_width                =>     pl_sel_link_width               ,
      pl_directed_link_auton           =>     pl_directed_link_auton          ,
      pl_directed_link_change          =>     pl_directed_link_change         ,
      pl_directed_link_speed           =>     pl_directed_link_speed          ,
      pl_directed_link_width           =>     pl_directed_link_width          ,
      pl_upstream_prefer_deemph        =>     pl_upstream_prefer_deemph       ,

      ---------------------------------------------------------
      -- 5. System  (SYS) Interface
      ---------------------------------------------------------

      sys_clk                          =>     sys_clk_c     ,
      sys_reset_n                      =>     sys_reset_n_c 
               
);

 end generate;


make8Lanes: if pcieLanes = 8 generate
  pcieCore : v6_pcie_v1_3x8
    generic map (
                 PL_FAST_TRAIN  => FALSE
             )
    port map (

      ---------------------------------------------------------
      -- 1. PCI Express (pci_exp) Interface
      ---------------------------------------------------------

      -- Tx
      pci_exp_txp       =>     pci_exp_txp           ,
      pci_exp_txn       =>     pci_exp_txn           ,

      -- Rx
      pci_exp_rxp       =>     pci_exp_rxp           ,
      pci_exp_rxn       =>     pci_exp_rxn           ,
                                             
      ---------------------------------------------------------
      -- 2. Transaction (TRN) Interface
      ---------------------------------------------------------

      -- Common
      trn_clk           =>     trn_clk               ,
      trn_reset_n       =>     trn_reset_n_int1      ,
      trn_lnk_up_n      =>     trn_lnk_up_n_int1     ,

      -- Tx
      trn_tbuf_av       =>     trn_tbuf_av           ,
      trn_tcfg_req_n    =>     trn_tcfg_req_n        ,
      trn_terr_drop_n   =>     trn_terr_drop_n       ,
      trn_tdst_rdy_n    =>     trn_tdst_rdy_n        ,
      trn_td            =>     trn_td                ,
      trn_trem_n        =>     trn_trem_n(0)         ,
      trn_tsof_n        =>     trn_tsof_n            ,
      trn_teof_n        =>     trn_teof_n            ,
      trn_tsrc_rdy_n    =>     trn_tsrc_rdy_n        ,
      trn_tsrc_dsc_n    =>     trn_tsrc_dsc_n        ,
      trn_terrfwd_n     =>     trn_terrfwd_n         ,
      trn_tcfg_gnt_n    =>     trn_tcfg_gnt_n        ,
      trn_tstr_n        =>     trn_tstr_n            ,

      -- Rx
      trn_rd            =>     trn_rd                ,
      trn_rrem_n        =>     trn_rrem_n(0)         ,
      trn_rsof_n        =>     trn_rsof_n            ,
      trn_reof_n        =>     trn_reof_n            ,
      trn_rsrc_rdy_n    =>     trn_rsrc_rdy_n        ,
      trn_rsrc_dsc_n    =>     trn_rsrc_dsc_n        ,
      trn_rerrfwd_n     =>     trn_rerrfwd_n         ,
      trn_rbar_hit_n    =>     trn_rbar_hit_n        ,
      trn_rdst_rdy_n    =>     trn_rdst_rdy_n        ,
      trn_rnp_ok_n      =>     trn_rnp_ok_n          ,

      -- Flow Control
      trn_fc_cpld       =>     trn_fc_cpld           ,
      trn_fc_cplh       =>     trn_fc_cplh           ,
      trn_fc_npd        =>     trn_fc_npd            ,
      trn_fc_nph        =>     trn_fc_nph            ,
      trn_fc_pd         =>     trn_fc_pd             ,
      trn_fc_ph         =>     trn_fc_ph             ,
      trn_fc_sel        =>     trn_fc_sel            ,


      ---------------------------------------------------------
      -- 3. Configuration (CFG) Interface
      ---------------------------------------------------------

      cfg_do                   =>     cfg_do                     ,
      cfg_rd_wr_done_n         =>     cfg_rd_wr_done_n           ,
      cfg_di                   =>     cfg_di                     ,
      cfg_byte_en_n            =>     cfg_byte_en_n              ,
      cfg_dwaddr               =>     cfg_dwaddr                 ,
      cfg_wr_en_n              =>     cfg_wr_en_n                ,
      cfg_rd_en_n              =>     cfg_rd_en_n                ,

      cfg_err_cor_n            =>     cfg_err_cor_n              ,
      cfg_err_ur_n             =>     cfg_err_ur_n               ,
      cfg_err_ecrc_n           =>     cfg_err_ecrc_n             ,
      cfg_err_cpl_timeout_n    =>     cfg_err_cpl_timeout_n      ,
      cfg_err_cpl_abort_n      =>     cfg_err_cpl_abort_n        ,
      cfg_err_cpl_unexpect_n   =>     cfg_err_cpl_unexpect_n     ,
      cfg_err_posted_n         =>     cfg_err_posted_n           ,
      cfg_err_locked_n         =>     cfg_err_locked_n           ,
      cfg_err_tlp_cpl_header   =>     cfg_err_tlp_cpl_header     ,
      cfg_err_cpl_rdy_n        =>     cfg_err_cpl_rdy_n          ,
      cfg_interrupt_n          =>     cfg_interrupt_n            ,
      cfg_interrupt_rdy_n      =>     cfg_interrupt_rdy_n        ,
      cfg_interrupt_assert_n   =>     cfg_interrupt_assert_n     ,
      cfg_interrupt_di         =>     cfg_interrupt_di           ,
      cfg_interrupt_do         =>     cfg_interrupt_do           ,
      cfg_interrupt_mmenable   =>     cfg_interrupt_mmenable     ,
      cfg_interrupt_msienable  =>     cfg_interrupt_msienable    ,
      cfg_interrupt_msixenable =>     cfg_interrupt_msixenable   ,
      cfg_interrupt_msixfm     =>     cfg_interrupt_msixfm       ,
      cfg_turnoff_ok_n         =>     cfg_turnoff_ok_n           ,
      cfg_to_turnoff_n         =>     cfg_to_turnoff_n           ,
      cfg_trn_pending_n        =>     cfg_trn_pending_n          ,
      cfg_pm_wake_n            =>     cfg_pm_wake_n              ,
      cfg_bus_number           =>     cfg_bus_number             ,
      cfg_device_number        =>     cfg_device_number          ,
      cfg_function_number      =>     cfg_function_number        ,
      cfg_status               =>     cfg_status                 ,
      cfg_command              =>     cfg_command                ,
      cfg_dstatus              =>     cfg_dstatus                ,
      cfg_dcommand             =>     cfg_dcommand               ,
      cfg_lstatus              =>     cfg_lstatus                ,
      cfg_lcommand             =>     cfg_lcommand               ,
      cfg_dcommand2            =>     cfg_dcommand2              ,
      cfg_pcie_link_state_n    =>     cfg_pcie_link_state_n      ,
      cfg_dsn                  =>     cfg_dsn                    ,

      ---------------------------------------------------------
      -- 4. Physical Layer Control and Status (PL) Interface
      ---------------------------------------------------------

      pl_initial_link_width            =>     pl_initial_link_width           ,
      pl_lane_reversal_mode            =>     pl_lane_reversal_mode           ,
      pl_link_gen2_capable             =>     pl_link_gen2_capable            ,
      pl_link_partner_gen2_supported   =>     pl_link_partner_gen2_supported  ,
      pl_link_upcfg_capable            =>     pl_link_upcfg_capable           ,
      pl_ltssm_state                   =>     pl_ltssm_state                  ,
      pl_received_hot_rst              =>     pl_received_hot_rst             ,
      pl_sel_link_rate                 =>     pl_sel_link_rate                ,
      pl_sel_link_width                =>     pl_sel_link_width               ,
      pl_directed_link_auton           =>     pl_directed_link_auton          ,
      pl_directed_link_change          =>     pl_directed_link_change         ,
      pl_directed_link_speed           =>     pl_directed_link_speed          ,
      pl_directed_link_width           =>     pl_directed_link_width          ,
      pl_upstream_prefer_deemph        =>     pl_upstream_prefer_deemph       ,

      ---------------------------------------------------------
      -- 5. System  (SYS) Interface
      ---------------------------------------------------------

      sys_clk                          =>     sys_clk_c     ,
      sys_reset_n                      =>     sys_reset_n_c 
               
);

 end generate;


   DAQ_irq              <= eb_empty;


-- ---------------------------------------------------------------
-- tlp control module
-- 
   trn_rrem_n(7 downto 1) <= X"0" & trn_rrem_n(0) & trn_rrem_n(0) & trn_rrem_n(0);

   theTlpControl:
   tlpControl 
   port map (

           mbuf_UserFull               => '0'                 ,
           trn_Blinker                 => trn_Blinker         ,

           -- DCB protocol interface
           protocol_link_act           =>  protocol_link_act  ,  -- IN  std_logic_vector(2-1 downto 0);
           protocol_rst                =>  protocol_rst       ,  -- OUT std_logic;
                            
           Link_Buf_Full               =>  daq_rstop          ,  -- IN  std_logic;

           -- Interrupter triggers
           DAQ_irq                     =>  DAQ_irq            ,  -- IN  std_logic;
           CTL_irq                     =>  CTL_irq            ,  -- IN  std_logic;
           DLM_irq                     =>  DLM_irq            ,  -- IN  std_logic;

           -- Fabric side: CTL Rx
           ctl_rv                      =>  ctl_rv             ,  -- OUT std_logic;
           ctl_rd                      =>  ctl_rd             ,  -- OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
                            
           -- Fabric side: CTL Tx
           ctl_ttake                   =>  ctl_ttake          ,  -- OUT std_logic;
           ctl_tv                      =>  ctl_tv             ,  -- IN  std_logic;
           ctl_td                      =>  ctl_td             ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
           ctl_tstop                   =>  ctl_tstop          ,  -- OUT std_logic;
                            
           ctl_reset                   =>  ctl_reset          ,  -- OUT std_logic;
           ctl_status                  =>  ctl_status         ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
                            
           -- Fabric side: DLM Rx
           dlm_rv                      =>  dlm_rv             ,  -- OUT std_logic;
           dlm_rd                      =>  dlm_rd             ,  -- OUT std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
                            
           -- Fabric side: DLM Tx
           dlm_tv                      =>  dlm_tv             ,  -- IN  std_logic;
           dlm_td                      =>  dlm_td             ,  -- IN  std_logic_vector(C_DBUS_WIDTH/2-1 downto 0);
                            
           -- Event Buffer FIFO interface
           eb_FIFO_we                  => eb_we               , --  OUT std_logic; 
           eb_FIFO_wsof                => eb_wsof             , --  OUT std_logic; 
           eb_FIFO_weof                => eb_weof             , --  OUT std_logic; 
           eb_FIFO_din                 => eb_din(C_DBUS_WIDTH-1 downto 0) , --  OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);

           eb_FIFO_re                  => eb_re               , --  OUT std_logic; 
           eb_FIFO_empty               => eb_empty            , --  IN  std_logic; 
           eb_FIFO_qout                => eb_dout(C_DBUS_WIDTH-1 downto 0) , --  IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           eb_FIFO_data_count          => eb_data_count       , --  IN  std_logic_vector(C_FIFO_DC_WIDTH downto 0);

           eb_FIFO_ow                  => eb_FIFO_ow          , --  IN  std_logic;

           pio_reading_status          => pio_reading_status  , --  OUT std_logic; 

           eb_FIFO_Status              => eb_FIFO_Status      , --  IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           eb_FIFO_Rst                 => eb_rst              , --  OUT std_logic;

           -- Debugging signals
           DMA_us_Done                 => LEDs_IO_pin(7)      , -- OUT std_logic;
           DMA_us_Busy                 => open                , -- OUT std_logic;
           DMA_us_Busy_LED             => LEDs_IO_pin(6)      , -- OUT std_logic;
           DMA_ds_Done                 => LEDs_IO_pin(5)      , -- OUT std_logic;
           DMA_ds_Busy                 => open                , -- OUT std_logic;
           DMA_ds_Busy_LED             => LEDs_IO_pin(4)      , -- OUT std_logic;
                                                        
           -------------------
           -- DDR Interface
           DDR_Ready                   => DDR_Ready           , --  IN    std_logic;

           DDR_wr_sof                  => DDR_wr_sof          , --  OUT   std_logic;
           DDR_wr_eof                  => DDR_wr_eof          , --  OUT   std_logic;
           DDR_wr_v                    => DDR_wr_v            , --  OUT   std_logic;
           DDR_wr_FA                   => DDR_wr_FA           , --  OUT   std_logic;
           DDR_wr_Shift                => DDR_wr_Shift        , --  OUT   std_logic;
           DDR_wr_Mask                 => DDR_wr_Mask         , --  OUT   std_logic_vector(2-1 downto 0);
           DDR_wr_din                  => DDR_wr_din          , --  OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           DDR_wr_full                 => DDR_wr_full         , --  IN    std_logic;

           DDR_rdc_sof                 => DDR_rdc_sof         , --  OUT   std_logic;
           DDR_rdc_eof                 => DDR_rdc_eof         , --  OUT   std_logic;
           DDR_rdc_v                   => DDR_rdc_v           , --  OUT   std_logic;
           DDR_rdc_FA                  => DDR_rdc_FA          , --  OUT   std_logic;
           DDR_rdc_Shift               => DDR_rdc_Shift       , --  OUT   std_logic;
           DDR_rdc_din                 => DDR_rdc_din         , --  OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);
           DDR_rdc_full                => DDR_rdc_full        , --  IN    std_logic;

--           DDR_rdD_sof                 => DDR_rdD_sof         , --  IN    std_logic;
--           DDR_rdD_eof                 => DDR_rdD_eof         , --  IN    std_logic;
--           DDR_rdDout_V                => DDR_rdDout_V        , --  IN    std_logic;
--           DDR_rdDout                  => DDR_rdDout          , --  IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);

           -- DDR payload FIFO Read Port
           DDR_FIFO_RdEn               => DDR_FIFO_RdEn      ,  -- OUT std_logic; 
           DDR_FIFO_Empty              => DDR_FIFO_Empty     ,  -- IN  std_logic;
           DDR_FIFO_RdQout             => DDR_FIFO_RdQout    ,  -- IN  std_logic_vector(C_DBUS_WIDTH-1 downto 0);

           -- Data generator table write
           tab_we                      =>  tab_we            ,  -- OUT std_logic_vector(2-1 downto 0);
           tab_wa                      =>  tab_wa            ,  -- OUT std_logic_vector(12-1 downto 0);
           tab_wd                      =>  tab_wd            ,  -- OUT std_logic_vector(C_DBUS_WIDTH-1 downto 0);
                                                      
           DG_is_Running               =>  dg_running        ,  -- IN  std_logic;
           DG_Reset                    =>  dg_rst            ,  -- OUT   STD_LOGIC;
           DG_Mask                     =>  dg_mask           ,  -- OUT   STD_LOGIC
                                                      
           -------------------
           -- Transaction Interface
           trn_lnk_up_n                => trn_lnk_up_n            ,
           trn_rsrc_dsc_n              => trn_rsrc_dsc_n          ,
           trn_rnp_ok_n                => trn_rnp_ok_n            ,
           trn_tsrc_dsc_n              => trn_tsrc_dsc_n          ,
           trn_tdst_dsc_n              => trn_tdst_dsc_n          ,
           trn_tbuf_av                 => trn_tbuf_av             ,
           trn_terrfwd_n               => trn_terrfwd_n           ,

           trn_clk                     => trn_clk                 ,
           trn_reset_n                 => trn_reset_n             ,
           trn_rsrc_rdy_n              => trn_rsrc_rdy_n          ,
           trn_tdst_rdy_n              => trn_tdst_rdy_n          ,
           trn_rsof_n                  => trn_rsof_n              ,
           trn_reof_n                  => trn_reof_n              ,
           trn_rerrfwd_n               => trn_rerrfwd_n           ,
           trn_rrem_n                  => trn_rrem_n              ,
           trn_rd                      => trn_rd                  ,
                                                        
           cfg_interrupt_n             => cfg_interrupt_n         ,
           cfg_interrupt_rdy_n         => cfg_interrupt_rdy_n     ,
           cfg_interrupt_mmenable      => cfg_interrupt_mmenable  ,
           cfg_interrupt_msienable     => cfg_interrupt_msienable ,
           cfg_interrupt_di            => cfg_interrupt_di        ,
           cfg_interrupt_do            => cfg_interrupt_do        ,
           cfg_interrupt_assert_n      => cfg_interrupt_assert_n  ,

           trn_rbar_hit_n              => trn_rbar_hit_n          ,
           trn_tsrc_rdy_n              => trn_tsrc_rdy_n          ,
           trn_rdst_rdy_n              => trn_rdst_rdy_n          ,
           trn_tsof_n                  => trn_tsof_n              ,
           trn_teof_n                  => trn_teof_n              ,
           trn_trem_n                  => trn_trem_n              ,
           trn_td                      => trn_td                  ,

           Format_Shower               => Format_Shower           ,

           cfg_dcommand                => cfg_dcommand            ,
           pcie_link_width             => pcie_link_width         ,
           localId                     => localId
           );
	

  -- -----------------------------------------------------------------------
  --  DDR SDRAM control module
  --
   DDRs_ctrl_module:
   bram_DDRs_Control
   GENERIC MAP (
                C_ASYNFIFO_WIDTH    => 72 ,
                P_SIMULATION        => FALSE
               )
   PORT MAP(

      -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
      DDR_wr_sof               => DDR_wr_sof          , --  IN    std_logic;
      DDR_wr_eof               => DDR_wr_eof          , --  IN    std_logic;
      DDR_wr_v                 => DDR_wr_v            , --  IN    std_logic;
      DDR_wr_FA                => DDR_wr_FA           , --  IN    std_logic;
      DDR_wr_Shift             => DDR_wr_Shift        , --  IN    std_logic;
      DDR_wr_Mask              => DDR_wr_Mask         , --  IN    std_logic_vector(2-1 downto 0);
      DDR_wr_din               => DDR_wr_din          , --  IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_wr_full              => DDR_wr_full         , --  OUT   std_logic;

      DDR_rdc_sof              => DDR_rdc_sof         , --  IN    std_logic;
      DDR_rdc_eof              => DDR_rdc_eof         , --  IN    std_logic;
      DDR_rdc_v                => DDR_rdc_v           , --  IN    std_logic;
      DDR_rdc_FA               => DDR_rdc_FA          , --  IN    std_logic;
      DDR_rdc_Shift            => DDR_rdc_Shift       , --  IN    std_logic;
      DDR_rdc_din              => DDR_rdc_din         , --  IN    std_logic_vector(C_DBUS_WIDTH-1 downto 0);
      DDR_rdc_full             => DDR_rdc_full        , --  OUT   std_logic;

--      DDR_rdD_sof              => DDR_rdD_sof         , --  OUT   std_logic;
--      DDR_rdD_eof              => DDR_rdD_eof         , --  OUT   std_logic;
--      DDR_rdDout_V             => DDR_rdDout_V        , --  OUT   std_logic;
--      DDR_rdDout               => DDR_rdDout          , --  OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      -- DDR payload FIFO Read Port
      DDR_FIFO_RdEn            => DDR_FIFO_RdEn       ,  -- IN    std_logic; 
      DDR_FIFO_Empty           => DDR_FIFO_Empty      ,  -- OUT   std_logic;
      DDR_FIFO_RdQout          => DDR_FIFO_RdQout     ,  -- OUT   std_logic_vector(C_DBUS_WIDTH-1 downto 0);

      -- Common interface
      DDR_Ready                => DDR_Ready           , --  OUT   std_logic;
      DDR_Blinker              => DDR_Blinker         , --  OUT   std_logic;
      mem_clk                  => trn_clk,   -- mem_clk             , --  IN
      trn_clk                  => trn_clk             , --  IN    std_logic;
      trn_reset_n              => trn_reset_n           --  IN    std_logic
    );



    -- 
    -- Event Buffer wrapper
    -- 
    Pseudo_EB: if not USE_DDR2_MODULE generate


    LEDs_IO_pin(0)    <= trn_reset_n xor Format_Shower;
    LEDs_IO_pin(1)    <= trn_lnk_up_n;
    LEDs_IO_pin(2)    <= link_active(0);
    LEDs_IO_pin(3)    <= trn_Blinker   ;  -- link_active(1);   -- dg_debug_led;


    event_buffer0:
    eb_wrapper
      port map (
         wr_clk     => trn_clk   ,  -- eb_wclk   ,
         wr_en      => eb_we_up  ,
         din        => eb_din_up ,
         pfull      => eb_pfull  ,
         full       => eb_full   ,

         rd_clk     => trn_clk   ,  -- eb_rclk   ,
         rd_en      => eb_re     ,
         dout       => eb_dout   ,
         pempty     => eb_pempty ,
         empty      => eb_empty  ,

         data_count => eb_data_count(C_EMU_FIFO_DC_WIDTH-1+1 downto 1) ,
         rst        => eb_rst    
         );

--      eb_FIFO_Status(C_FIFO_DC_WIDTH+2)  <= '0';
      eb_data_count(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1)
                      <= C_ALL_ZEROS(C_FIFO_DC_WIDTH downto C_EMU_FIFO_DC_WIDTH+1);
      eb_data_count(0)        -- 64 bits to 32 bits transformation
                      <= '0';
      fifo_reset_done <= not eb_rst;

    end generate;



--    eb_wclk            <= trn_clk;
--    eb_rclk            <= trn_clk;
    eb_din(72-1 downto C_DBUS_WIDTH)       <= (OTHERS=>'0');
    eb_FIFO_Status(C_DBUS_WIDTH-1 downto C_FIFO_DC_WIDTH+3)
                         <= (OTHERS=>'0');
    eb_FIFO_Status(C_FIFO_DC_WIDTH+2 downto 3)
                         <= eb_data_count(C_FIFO_DC_WIDTH downto 1);
    eb_FIFO_Status(2)    <= '0';      -- daq_rstop;
    eb_FIFO_Status(1)    <= eb_pfull;
    eb_FIFO_Status(0)    <= eb_empty and fifo_reset_done;
    eb_FIFO_ow           <= eb_we_up and eb_full;


    -- 
    --   .......................
    -- 
    
    daq_rv              <=  eb_we;
    daq_rsof            <=  eb_wsof;
    daq_reof            <=  eb_weof;
    daq_rd              <=  eb_din(C_DBUS_WIDTH-1 downto 0);

    eb_we_up            <=  daq_tv;
    eb_din_up           <=  C_ALL_ZEROS(72-1 downto C_DBUS_WIDTH+2) & daq_tsof & daq_teof & daq_td;
    daq_tstop           <=  eb_pfull;


    -- 
    --     Protocol Interface
    -- 
    ABB_DCB_Interface0:
    protocol_IF
      port map (
           -- DAQ Tx
           data2send_start          => data2send_start      ,   -- OUT   std_logic;
           data2send_end            => data2send_end        ,   -- OUT   std_logic;
           data2send                => data2send            ,   -- OUT   std_logic_vector(16-1 downto 0);
           crc_error_send           => crc_error_send       ,   -- OUT   std_logic;
           data2send_stop           => data2send_stop       ,   -- IN    std_logic;

           -- DAQ Rx
           data_rec_start           => data_rec_start       ,   -- IN    std_logic;
           data_rec_end             => data_rec_end         ,   -- IN    std_logic;
           data_rec                 => data_rec             ,   -- IN    std_logic_vector(16-1 downto 0);
           crc_error_rec            => crc_error_rec        ,   -- IN    std_logic;
           data_rec_stop            => data_rec_stop        ,   -- OUT   std_logic;

           -- CTL Tx
           ctrl2send_start          => ctrl2send_start      ,   -- OUT   std_logic;
           ctrl2send_end            => ctrl2send_end        ,   -- OUT   std_logic;
           ctrl2send                => ctrl2send            ,   -- OUT   std_logic_vector(16-1 downto 0);
           ctrl2send_stop           => ctrl2send_stop       ,   -- IN    std_logic;

           -- CTL Rx
           ctrl_rec_start           => ctrl_rec_start       ,   -- IN    std_logic;
           ctrl_rec_end             => ctrl_rec_end         ,   -- IN    std_logic;
           ctrl_rec                 => ctrl_rec             ,   -- IN    std_logic_vector(16-1 downto 0);
           ctrl_rec_stop            => ctrl_rec_stop        ,   -- OUT   std_logic;

           -- DLM Tx
           dlm2send_va              => dlm2send_va          ,   -- OUT   std_logic;
           dlm2send_type            => dlm2send_type        ,   -- OUT   std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               => dlm_rec_va           ,   -- IN    std_logic;
           dlm_rec_type             => dlm_rec_type         ,   -- IN    std_logic_vector(4-1 downto 0);

           -- Common signals
           link_tx_clk              => link_tx_clk          ,   -- IN    std_logic;
           link_rx_clk              => link_rx_clk          ,   -- IN    std_logic;
           link_active              => link_active          ,   -- IN    std_logic_vector(2-1 downto 0);
           protocol_clk             => protocol_clk         ,   -- OUT   std_logic;
           protocol_res_n           => protocol_res_n       ,   -- OUT   std_logic;


           -- Fabric side: DAQ Rx
           daq_rv                   => daq_rv               ,   -- IN    std_logic;
           daq_rsof                 => daq_rsof             ,   -- IN    std_logic;
           daq_reof                 => daq_reof             ,   -- IN    std_logic;
           daq_rd                   => daq_rd               ,   -- IN    std_logic_vector(64-1 downto 0);
           daq_rstop                => daq_rstop            ,   -- OUT   std_logic;

           -- Fabric side: DAQ Tx
           daq_tv                   => daq_tv               ,   -- OUT   std_logic;
           daq_tsof                 => daq_tsof             ,   -- OUT   std_logic;
           daq_teof                 => daq_teof             ,   -- OUT   std_logic;
           daq_td                   => daq_td               ,   -- OUT   std_logic_vector(64-1 downto 0);
           daq_tstop                => daq_tstop            ,   -- IN    std_logic;

           -- Fabric side: CTL Rx
           ctl_rv                   => ctl_rv               ,   -- IN    std_logic;
           ctl_rd                   => ctl_rd               ,   -- IN    std_logic_vector(32-1 downto 0);
           ctl_rstop                => ctl_rstop            ,   -- OUT   std_logic;

           -- Fabric side: CTL Tx
           ctl_ttake                => ctl_ttake            ,   -- IN    std_logic;
           ctl_tv                   => ctl_tv               ,   -- OUT   std_logic;
           ctl_td                   => ctl_td               ,   -- OUT   std_logic_vector(32-1 downto 0);
           ctl_tstop                => ctl_tstop            ,   -- IN    std_logic;

           ctl_reset                => ctl_reset            ,   -- IN    std_logic;
           ctl_status               => ctl_status           ,   -- OUT   std_logic_vector(32-1 downto 0);

           -- Fabric side: DLM Rx
           dlm_rv                   => dlm_rv               ,   -- IN    std_logic;
           dlm_rd                   => dlm_rd               ,   -- IN    std_logic_vector(4-1 downto 0);

           -- Fabric side: DLM Tx
           dlm_tv                   => dlm_tv               ,   -- OUT   std_logic;
           dlm_td                   => dlm_td               ,   -- OUT   std_logic_vector(4-1 downto 0);

           -- Interrupter triggers
           DAQ_irq                  => open,  -- DAQ_irq              ,   -- OUT   std_logic;
           CTL_irq                  => CTL_irq              ,   -- OUT   std_logic;
           DLM_irq                  => DLM_irq              ,   -- OUT   std_logic;

           -- Data generator table write port
           tab_sel                  => '1'                  , -- IN    STD_LOGIC;
           tab_we                   => tab_we               , -- IN    STD_LOGIC_VECTOR (2-1 downto 0);
           tab_wa                   => tab_wa               , -- IN    STD_LOGIC_VECTOR (12-1 downto 0);
           tab_wd                   => tab_wd               , -- IN    STD_LOGIC_VECTOR (64-1 downto 0);

           -- DG control/status signal
           dg_running               => dg_running           , -- OUT   STD_LOGIC;
           dg_mask                  => dg_mask              , -- IN    STD_LOGIC;
           dg_rst                   => dg_rst               , -- IN    STD_LOGIC

           -- DG debug signal
           daq_start_led            => dg_debug_led         , -- OUT   STD_LOGIC;

           -- Fabric side: Common signals
           trn_clk                  => trn_clk              ,   -- IN    std_logic;
           protocol_link_act        => protocol_link_act    ,   -- OUT   std_logic_vector(2-1 downto 0);
           protocol_rst             => protocol_rst             -- IN    std_logic
      );


    -- 
    --     Module emulating the link
    -- 
  Gen_EMU_Links: if not USE_OPTO_LINKS generate

    DCB_Link_module0:
    pseudo_protocol_module
      port map (
           -- DAQ Tx
           data2send_start          => data2send_start       ,   -- IN    std_logic;
           data2send_end            => data2send_end         ,   -- IN    std_logic;
           data2send                => data2send             ,   -- IN    std_logic_vector(16-1 downto 0);
           crc_error_send           => crc_error_send        ,   -- IN    std_logic;
           data2send_stop           => data2send_stop        ,   -- OUT   std_logic;

           -- DAQ Rx
           data_rec_start           => data_rec_start        ,   -- OUT   std_logic;
           data_rec_end             => data_rec_end          ,   -- OUT   std_logic;
           data_rec                 => data_rec              ,   -- OUT   std_logic_vector(16-1 downto 0);
           crc_error_rec            => crc_error_rec         ,   -- OUT   std_logic;
           data_rec_stop            => data_rec_stop         ,   -- IN    std_logic;

           -- CTL Tx
           ctrl2send_start          => ctrl2send_start       ,   -- IN    std_logic;
           ctrl2send_end            => ctrl2send_end         ,   -- IN    std_logic;
           ctrl2send                => ctrl2send             ,   -- IN    std_logic_vector(16-1 downto 0);
           ctrl2send_stop           => ctrl2send_stop        ,   -- OUT   std_logic;

           -- CTL Rx
           ctrl_rec_start           => ctrl_rec_start        ,   -- OUT   std_logic;
           ctrl_rec_end             => ctrl_rec_end          ,   -- OUT   std_logic;
           ctrl_rec                 => ctrl_rec              ,   -- OUT   std_logic_vector(16-1 downto 0);
           ctrl_rec_stop            => ctrl_rec_stop         ,   -- IN    std_logic;

           -- DLM Tx
           dlm2send_va              => dlm2send_va           ,   -- IN    std_logic;
           dlm2send_type            => dlm2send_type         ,   -- IN    std_logic_vector(4-1 downto 0);

           -- DLM Rx
           dlm_rec_va               => dlm_rec_va            ,   -- OUT   std_logic;
           dlm_rec_type             => dlm_rec_type          ,   -- OUT   std_logic_vector(4-1 downto 0);

           -- dummy pin input  !!!! not really exists
           dummy_pin_in             => "000",  -- dummy_pin_in          ,   -- IN    std_logic_vector(3-1 downto 0);
--           dummy_pin_in             => dummy_pin_in          ,   -- IN    std_logic_vector(3-1 downto 0);

           -- Common interface
           link_tx_clk              => link_tx_clk           ,   -- OUT   std_logic;
           link_rx_clk              => link_rx_clk           ,   -- OUT   std_logic;
           link_active              => link_active           ,   -- OUT   std_logic_vector(2-1 downto 0);
           clk                      => protocol_clk          ,   -- IN    std_logic;
           res_n                    => protocol_res_n            -- IN    std_logic
      );


  end generate;


end Behavioral;
