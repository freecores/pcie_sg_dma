`include "mgt_parameters.h"

module ml605_link_wrapper #
(
 parameter SIMULATION  = 0,
 parameter DATAWIDTH   = 16,
 parameter WORDS       = DATAWIDTH/8,
 parameter ALIGN_CHAR  = `K285,
 parameter READY_CHAR0 = `K284,
 parameter READY_CHAR1 = `K287
)
(
 input         TILE0_REFCLK_PAD_N_IN,
 input         TILE0_REFCLK_PAD_P_IN,
 input         RXN_IN,
 input         RXP_IN,
 output wire   TXN_OUT,
 output wire   TXP_OUT,
 input  wire   SFP_LOS,

 output wire tx_clk,
 output wire rx_clk,
 output wire link_active,
 
 output wire ctrl2send_stop,
 input wire ctrl2send_start,
 input wire ctrl2send_end,
 input wire [15:0] ctrl2send,
 
 output wire data2send_stop,
 input wire data2send_start,
 input wire data2send_end,
 input wire [15:0] data2send,
 
 input wire dlm2send_valid,
 input wire [3:0] dlm2send,
 
 output wire [3:0] dlm_rec,
 output wire dlm_rec_valid,
 
 output wire data_rec_start,
 output wire data_rec_end,
 output wire [15:0] data_rec,
 output wire crc_error_rec,
 input wire data_rec_stop,
 
 output wire ctrl_rec_start,
 output wire ctrl_rec_end,
 output wire [15:0] ctrl_rec,
 input wire ctrl_rec_stop

);

`include "cbm_lp_defines.h"

wire [1:0]  TXN_OUT_i;
wire [1:0]  TXP_OUT_i;
wire tx_ready0;
wire rx_ready0;
wire [DATAWIDTH-1:0] rx_data0;
wire [WORDS-1:0] rx_charisk0;
wire [DATAWIDTH-1:0] tx_data0;
wire [WORDS-1:0] tx_charisk0;

wire [(DATAWIDTH-1):0] rx_data2fifo0;
wire [(WORDS-1):0] rx_charisk2fifo0;

wire [(DATAWIDTH-1):0] rx_data2idlefilter0;
wire [(WORDS-1):0] rx_charisk2idlefilter0;

wire [(DATAWIDTH-1):0] rx_data2idlemux0;
wire [(WORDS-1):0] rx_charisk2idlemux0;

reg [(DATAWIDTH-1):0] rx_data2serdes_temp0;
reg [(WORDS-1):0] rx_charisk2serdes_temp0;

reg [(DATAWIDTH-1):0] rx_data2serdes0;
reg [(WORDS-1):0] rx_charisk2serdes0;

reg no_idle0;
wire rxfifo_shift_out0;
reg rxfifo_shift_out_del0;



  assign TXN_OUT = TXN_OUT_i[0];
  assign TXP_OUT = TXP_OUT_i[0];

  gtp_det_lat_wrapper_16bit #
  (
   .ALIGN_CHAR(`K285),
   .READY_CHAR0(`K284),
   .READY_CHAR1(`K287),
   .SIMULATION(SIMULATION)     //some things get adjusted for simulation
  )
  gtp_wrapper_i
  (
   .TILE0_REFCLK_PAD_N_IN (TILE0_REFCLK_PAD_N_IN),
   .TILE0_REFCLK_PAD_P_IN (TILE0_REFCLK_PAD_P_IN),
   .GTPRESET_IN           (1'b0),
   .TILE0_PLLLKDET_OUT    ( ),                      //
   .RXN_IN                ({1'b0, RXN_IN}),
   .RXP_IN                ({1'b0, RXP_IN}),
   .TXN_OUT               (TXN_OUT_i),
   .TXP_OUT               (TXP_OUT_i),
   .SFP_LOS               ({1'b0, SFP_LOS}),
           
   .TX_USRCLK             (tx_clk),
   .RX_USRCLK0            (rx_clk),
   .RX_USRCLK1            ( ),                      //
   .TX_READY0             (tx_ready0),
   .TX_READY1             ( ),                      //
   .RX_READY0             (rx_ready0),
   .RX_READY1             ( ),                      //
   .RX_DATA0              (rx_data2fifo0),
   .RX_DATA1              ( ),                      //
   .RX_CHARISK0           (rx_charisk2fifo0),
   .RX_CHARISK1           ( ),                      //
   .TX_DATA0              (tx_data0),
   .TX_DATA1              ('b0),
   .TX_CHARISK0           (tx_charisk0),
   .TX_CHARISK1           ('b0)
  );            
              

syncfifo4cbm rx0_fifo
(
  .res_n(rx_ready0),
  .w_clk(rx_clk),
  .r_clk(tx_clk),
  .data_in(rx_data2fifo0),
  .charisk_in(rx_charisk2fifo0),
  .data_out(rx_data0),
  .charisk_out(rx_charisk0)
);


lp_cbm_top lp_cbm_top_I0(
    .clk(tx_clk),
    .res_n(tx_ready0),
    .link_active(link_active),
    .link_clk(),
    
    .ctrl2send_stop(ctrl2send_stop),
    .ctrl2send_start(ctrl2send_start),
    .ctrl2send_end(ctrl2send_end),
    .ctrl2send(ctrl2send),
    .crc_error_send(1'b0),

    .data2send_stop(data2send_stop),
    .data2send_start(data2send_start),
    .data2send_end(data2send_end),
    .data2send(data2send),
    
    .dlm2send_va(dlm2send_valid),
    .dlm2send(dlm2send),

    .dlm_rec_type(dlm_rec),
    .dlm_rec_va(dlm_rec_valid),

    .data_rec(data_rec),
    .data_rec_start(data_rec_start),
    .data_rec_end(data_rec_end),
    .data_rec_stop(data_rec_stop),
    .crc_error_rec(crc_error_rec),
    
    .ctrl_rec(ctrl_rec),
    .ctrl_rec_start(ctrl_rec_start),
    .ctrl_rec_end(ctrl_rec_end),               
    .ctrl_rec_stop(ctrl_rec_stop),
    
    .clk_link(tx_clk),
    .data_from_link({rx_charisk0, rx_data0}),
    .data2link({tx_charisk0, tx_data0}),

    .cable_detected(rx_ready0),
    .dll_locked(rx_ready0)
);


endmodule