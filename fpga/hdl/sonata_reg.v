/***********************************************************************
 Copyright (c) 2023-2024, NewAE Technology Inc
 All rights reserved.
 Author: Jean-Pierre Thibault <jpthibault@newae.com>

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

***********************************************************************/


`default_nettype none
`timescale 1ns / 1ps
`include "sonata_defines.v"

module sonata_reg #(
   parameter pBYTECNT_SIZE = 7,
   parameter pDONE_EDGE_SENSITIVE = 1,
   parameter pPT_WIDTH = 128,
   parameter pCT_WIDTH = 128,
   parameter pKEY_WIDTH = 128,
   parameter pCRYPT_TYPE = 2,
   parameter pCRYPT_REV = 4,
   parameter pIDENTIFY = 8'h2e
)(

// Interface to cw305_usb_reg_fe:
   input  wire                                  usb_clk,
   input  wire                                  crypto_clk,
   input  wire                                  hclk,
   input  wire                                  reset_i,
   input  wire [7:0]                            reg_address,     // Address of register
   input  wire [pBYTECNT_SIZE-1:0]              reg_bytecnt,  // Current byte count
   output reg  [7:0]                            read_data,       //
   input  wire [7:0]                            write_data,      //
   input  wire                                  reg_read,        // Read flag. One clock cycle AFTER this flag is high
                                                                 // valid data must be present on the read_data bus
   input  wire                                  reg_write,       // Write flag. When high on rising edge valid data is
                                                                 // present on write_data
   input  wire                                  reg_addrvalid,   // Address valid flag

   input  wire                                  mmcm_locked,
   input  wire                                  mmcm_hr_locked,

// AES:
   input  wire [pPT_WIDTH-1:0]                  I_textout,
   input  wire [pCT_WIDTH-1:0]                  I_cipherout,
   input  wire                                  I_ready,  /* Crypto core ready. Tie to '1' if not used. */
   input  wire                                  I_done,   /* Crypto done. Can be high for one crypto_clk cycle or longer. */
   input  wire                                  I_busy,   /* Crypto busy. */

   output reg                                   O_user_led,
   output wire [pKEY_WIDTH-1:0]                 O_key,
   output wire [pPT_WIDTH-1:0]                  O_textin,
   output wire [pCT_WIDTH-1:0]                  O_cipherin,
   output wire                                  O_start,  /* High for one crypto_clk cycle, indicates text ready. */

   output reg  [7:0]                            core_sel,
   output reg  [63:0]                           cores_en,

// Hyperram:
   output reg                                   reg_hreset,

   input  wire                                  rresp_error,
   input  wire                                  bresp_error,
   input  wire                                  clk_90p_locked,
   input  wire                                  clk_iserdes_locked,

   output reg                                   O_lb_manual,
   output reg                                   O_auto_lfsr_mode,
   output reg                                   O_auto_clear_fail,
   input  wire                                  I_auto_pass,
   input  wire                                  I_auto_fail,
   input  wire [15:0]                           I_auto_iterations,
   input  wire [31:0]                           I_auto_current_addr,
   input  wire [31:0]                           I_auto_errors,
   input  wire [31:0]                           I_auto_error_addr,
   output reg  [31:0]                           O_auto_start_addr,
   output reg  [31:0]                           O_auto_stop_addr,
   output reg  [7:0]                            O_wait_value,

   output wire                                  hbmc_write,
   output wire                                  hbmc_read,
   output reg  [31:0]                           hbmc_wdata,
   input  wire [31:0]                           hbmc_rdata,
   input  wire                                  hbmc_idle,

// LED/DIP/misc:
   input  wire                                  I_turbo,
   input  wire [5:0]                            I_analog_digital,
   input  wire [15:0]                           I_dips,
   output wire [20:0]                           O_test_leds,
   output wire                                  O_led_test_mode,
   output wire                                  O_led_flash_all

);

   reg  [7:0]                   reg_read_data;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherin;
   reg  [pKEY_WIDTH-1:0]        reg_crypt_key;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textin;
   reg  [pPT_WIDTH-1:0]         reg_crypt_textout;
   reg  [pCT_WIDTH-1:0]         reg_crypt_cipherout;
   reg                          reg_crypt_go_pulse;
   wire                         reg_crypt_go_pulse_crypt;
   reg  [22:0]                  reg_test_leds;
   reg                          aes_always_on;
   reg                          aes_always_go;

   reg                          busy_usb;
   reg                          done_r;
   wire                         done_pulse;
   wire [31:0]                  buildtime;

   (* ASYNC_REG = "TRUE" *) reg  [pKEY_WIDTH-1:0] reg_crypt_key_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textin_crypt;
   (* ASYNC_REG = "TRUE" *) reg  [pPT_WIDTH-1:0] reg_crypt_textout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [pCT_WIDTH-1:0] reg_crypt_cipherout_usb;
   (* ASYNC_REG = "TRUE" *) reg  [1:0] busy_pipe;


   reg  [63:0]                  reg_lb_both_rd_d;
   reg  [3:0]                   reg_lb_action;
   reg  [31:0]                  reg_lb_both_addr;
   reg  [63:0]                  reg_lb_both_data;
   reg  [1:0]                   reg_hbmc_action;

   assign hbmc_write = reg_hbmc_action[0];
   assign hbmc_read  = reg_hbmc_action[1];

   always @(posedge crypto_clk) begin
       done_r <= I_done & pDONE_EDGE_SENSITIVE;
   end
   assign done_pulse = I_done & ~done_r;

   always @(posedge crypto_clk) begin
       if (done_pulse) begin
           reg_crypt_cipherout <= I_cipherout;
           reg_crypt_textout   <= I_textout;
       end
       reg_crypt_key_crypt <= reg_crypt_key;
       reg_crypt_textin_crypt <= reg_crypt_textin;
   end

   always @(posedge usb_clk) begin
       reg_crypt_cipherout_usb <= reg_crypt_cipherout;
       reg_crypt_textout_usb   <= reg_crypt_textout;
   end

   assign O_textin = reg_crypt_textin_crypt;
   assign O_key = reg_crypt_key_crypt;
   assign O_start = aes_always_on ? aes_always_go : reg_crypt_go_pulse_crypt;
   assign O_test_leds = reg_test_leds[20:0];
   assign O_led_test_mode = reg_test_leds[21];
   assign O_led_flash_all = reg_test_leds[22];

   always @(posedge crypto_clk) begin
       if (aes_always_go)
           aes_always_go <= 1'b0;
       else if (~I_busy)
           aes_always_go <= 1'b1;
   end


   //////////////////////////////////
   // read logic:
   //////////////////////////////////

   always @(*) begin
      if (reg_addrvalid && reg_read) begin
         case (reg_address)
             // AES / config:
            `REG_CLKSETTINGS:           reg_read_data = {6'b0, mmcm_hr_locked, mmcm_locked};
            `REG_USER_LED:              reg_read_data = {7'b0, O_user_led};
            `REG_CRYPT_TYPE:            reg_read_data = pCRYPT_TYPE;
            `REG_CRYPT_REV:             reg_read_data = pCRYPT_REV;
            `REG_IDENTIFY:              reg_read_data = pIDENTIFY;
            `REG_CRYPT_GO:              reg_read_data = {7'b0, busy_usb};
            `REG_CRYPT_KEY:             reg_read_data = reg_crypt_key[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTIN:          reg_read_data = reg_crypt_textin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHERIN:        reg_read_data = reg_crypt_cipherin[reg_bytecnt*8 +: 8];
            `REG_CRYPT_TEXTOUT:         reg_read_data = reg_crypt_textout_usb[reg_bytecnt*8 +: 8];
            `REG_CRYPT_CIPHEROUT:       reg_read_data = reg_crypt_cipherout_usb[reg_bytecnt*8 +: 8];
            `REG_BUILDTIME:             reg_read_data = buildtime[reg_bytecnt*8 +: 8];

            // Hyperram:
            `REG_LB_MANUAL:             reg_read_data = {7'b0, O_lb_manual};
            `REG_HYPER_STATUS:          reg_read_data = {2'b0, clk_iserdes_locked, I_auto_pass, I_auto_fail, bresp_error, rresp_error, clk_90p_locked};
            `REG_LB_ERRORS:             reg_read_data = I_auto_errors[reg_bytecnt*8 +: 8];
            `REG_LB_ERROR_ADDR:         reg_read_data = I_auto_error_addr[reg_bytecnt*8 +: 8];
            `REG_LB_ITERATIONS:         reg_read_data = I_auto_iterations[reg_bytecnt*8 +: 8];
            `REG_LB_CURRENT_ADDR:       reg_read_data = I_auto_current_addr[reg_bytecnt*8 +: 8];
            `REG_HBMC_SINGLE_DATA:      reg_read_data = hbmc_rdata[reg_bytecnt*8 +: 8];
            `REG_HBMC_ACTION:           reg_read_data = hbmc_idle;

            // LED/DIP/misc:
            `REG_DIPS:                  reg_read_data = I_dips[reg_bytecnt*8 +: 8];
            `REG_ANALOG_DIGITAL:        reg_read_data = I_analog_digital;
            `REG_TURBO:                 reg_read_data = I_turbo;

            default:                    reg_read_data = 0;
         endcase
      end
      else
         reg_read_data = 0;
   end

   // Register output read data to ease timing. If you need read data one clock
   // cycle earlier, simply remove this stage:
   always @(posedge usb_clk)
      read_data <= reg_read_data;

   /*
   always @(*)
      read_data = reg_read_data;
   */

   //////////////////////////////////
   // write logic (USB clock domain):
   //////////////////////////////////
   always @(posedge usb_clk) begin
      if (reset_i) begin
         O_user_led <= 0;
         reg_crypt_go_pulse <= 1'b0;
         O_lb_manual <= 1;
         O_auto_clear_fail <= 0;
         O_auto_lfsr_mode <= 1;
         reg_test_leds <= 0;
         O_wait_value <= 4;
         aes_always_on <= 0;
      end

      else begin
         if (reg_addrvalid && reg_write) begin
            case (reg_address)
                // AES/config:
               `REG_USER_LED:           O_user_led <= write_data;
               `REG_CRYPT_TEXTIN:       reg_crypt_textin[reg_bytecnt*8 +: 8] <= write_data;
               `REG_CRYPT_CIPHERIN:     reg_crypt_cipherin[reg_bytecnt*8 +: 8] <= write_data;
               `REG_CRYPT_KEY:          reg_crypt_key[reg_bytecnt*8 +: 8] <= write_data;
               `REG_AES_ALWAYS_ON:      aes_always_on <= write_data[0];

               // Hyperram:
               `REG_LB_MANUAL:          {O_auto_lfsr_mode, O_auto_clear_fail, O_lb_manual} <= write_data[2:0];
               `REG_LB_STOP_ADDR:       O_auto_stop_addr[reg_bytecnt*8 +: 8] <= write_data;
               `REG_LB_START_ADDR:      O_auto_start_addr[reg_bytecnt*8 +: 8] <= write_data;
               `REG_BUSY_WAIT:          O_wait_value <= write_data;
               `REG_HBMC_ACTION:        reg_hbmc_action <= write_data[1:0];
               `REG_HBMC_SINGLE_DATA:   hbmc_wdata[reg_bytecnt*8 +: 8] <= write_data;

               // LED/DIP test:
               `REG_LEDS:               reg_test_leds[reg_bytecnt*8 +: 8] <= write_data;

               // multiple AES cores:
               `REG_AES_CORES_EN:       cores_en[reg_bytecnt*8 +: 8] <= write_data;
               `REG_AES_CORE_SEL:       core_sel <= write_data;

            endcase
         end
         // REG_CRYPT_GO register is special: writing it creates a pulse. Reading it gives you the "busy" status.
         if ( (reg_addrvalid && reg_write && (reg_address == `REG_CRYPT_GO)) )
            reg_crypt_go_pulse <= 1'b1;
         else
            reg_crypt_go_pulse <= 1'b0;

         // Hyperram reset:
         // write 0xff to do a single cycle reset, 0x01 to set, 0x00 to clear (hedging our bets!):
         if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'hFF) && ~reg_hreset)
             reg_hreset <= 1'b1;
         else
             reg_hreset <= 1'b0;
         if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'h01) && ~reg_hreset)
             reg_hreset <= 1'b1;
         else if (reg_write && (reg_address == `REG_HYPER_RESET) && (write_data == 8'h00) && ~reg_hreset)
             reg_hreset <= 1'b0;

      end
   end

   cdc_pulse U_go_pulse (
      .reset_i       (reset_i),
      .src_clk       (usb_clk),
      .src_pulse     (reg_crypt_go_pulse),
      .dst_clk       (crypto_clk),
      .dst_pulse     (reg_crypt_go_pulse_crypt)
   );

   always @(posedge usb_clk)
      {busy_usb, busy_pipe} <= {busy_pipe, I_busy};



   `ifdef ILA_REG
       ila_reg U_reg_ila (
	.clk            (usb_clk),                      // input wire clk
	.probe0         (reg_address),                  // input wire [7:0] probe1
	.probe1         (reg_bytecnt),                  // input wire [6:0]  probe1 
	.probe2         (read_data),                    // input wire [7:0]  probe2 
	.probe3         (write_data),                   // input wire [7:0]  probe3 
	.probe4         (reg_read),                     // input wire [0:0]  probe4 
	.probe5         (reg_write),                    // input wire [0:0]  probe5 
	.probe6         (reg_addrvalid),                // input wire [0:0]  probe6 
	.probe7         (reg_read_data),                // input wire [7:0]  probe7 
	.probe8         (exttrigger_in),                // input wire [0:0]  probe8 
	.probe9         (reset_i),                      // input wire [0:0]  probe9
	.probe10        (reg_crypt_go_pulse),           // input wire [0:0]  probe10
	.probe11        (reg_crypt_textin)             // input wire [127:0]  probe11
       );
   `endif


   `ifdef ILA_CRYPTO
       ila_crypto U_reg_aes (
	.clk            (crypto_clk),                   // input wire clk
	.probe0         (O_start),                      // input wire [0:0]  probe0  
	.probe1         (I_done),                       // input wire [0:0]  probe1 
	.probe2         (I_cipherout[7:0]),             // input wire [7:0]  probe2 
	.probe3         (O_textin[7:0]),                // input wire [7:0]  probe3 
	.probe4         (done_pulse)                    // input wire [0:0]  probe4 
       );
   `endif



   `ifndef __ICARUS__
      USR_ACCESSE2 U_buildtime (
         .CFGCLK(),
         .DATA(buildtime),
         .DATAVALID()
      );
   `else
      assign buildtime = 0;
   `endif


endmodule

`default_nettype wire
