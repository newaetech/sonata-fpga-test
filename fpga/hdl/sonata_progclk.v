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
`timescale 1ns / 1ns
`include "sonata_defines.v"

module sonata_progclk #(
   parameter pBYTECNT_SIZE = 7
)(
    input  wire                         reset_i,
    input  wire                         clk_usb,
    output wire                         progclk,
    output wire                         progclk_hr,
    input  wire                         shutdown,
    output wire                         mmcm_locked,
    output wire                         mmcm_hr_locked,
    input  wire [7:0]                   reg_address,
    input  wire [pBYTECNT_SIZE-1:0]     reg_bytecnt,
    output wire [7:0]                   reg_datao,
    output wire [7:0]                   reg_datao_hr,
    input  wire [7:0]                   reg_datai,
    input  wire                         reg_read,
    input  wire                         reg_write
);

   wire [6:0] drp_addr;
   wire [15:0] drp_din;
   wire [15:0] drp_dout;
   wire drp_den;
   wire drp_dwe;
   wire drp_reset;

   wire [6:0] drp_hr_addr;
   wire [15:0] drp_hr_din;
   wire [15:0] drp_hr_dout;
   wire drp_hr_den;
   wire drp_hr_dwe;
   wire drp_hr_reset;


   reg_mmcm_drp #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE),
      .pDRP_ADDR        (`REG_MMCM_DRP_ADDR),
      .pDRP_DATA        (`REG_MMCM_DRP_DATA),
      .pDRP_RESET       (`REG_MMCM_DRP_RESET)
   ) U_mmcm_drp (
      .reset_i          (reset_i),
      .clk_usb          (clk_usb),
      .selected         (1'b1),
      .reg_address      (reg_address), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (reg_datao), 
      .reg_datai        (reg_datai), 
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .drp_addr         (drp_addr ),
      .drp_den          (drp_den  ),
      .drp_din          (drp_din  ),
      .drp_dout         (drp_dout ),
      .drp_dwe          (drp_dwe  ),
      .drp_reset        (drp_reset)
   ); 

   reg_mmcm_drp #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE),
      .pDRP_ADDR        (`REG_MMCM_HR_DRP_ADDR),
      .pDRP_DATA        (`REG_MMCM_HR_DRP_DATA),
      .pDRP_RESET       (`REG_MMCM_HR_DRP_RESET)
   ) U_mmcm_hr_drp (
      .reset_i          (reset_i),
      .clk_usb          (clk_usb),
      .selected         (1'b1),
      .reg_address      (reg_address), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (reg_datao_hr), 
      .reg_datai        (reg_datai), 
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .drp_addr         (drp_hr_addr ),
      .drp_den          (drp_hr_den  ),
      .drp_din          (drp_hr_din  ),
      .drp_dout         (drp_hr_dout ),
      .drp_dwe          (drp_hr_dwe  ),
      .drp_reset        (drp_hr_reset)
   ); 



`ifndef __ICARUS__
   wire mmcm_clkfb;
   wire mmcm_hr_clkfb;

   // Set to 100 MHz default for Vivado timing closure. Input clock is 25 MHz:
   MMCME2_ADV #(
      .BANDWIDTH                    ("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F              (48.0), // Multiply value for all CLKOUT (2.000-64.000)
      .CLKOUT0_DIVIDE_F             (12.0),
      .CLKFBOUT_PHASE               (0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD                (40.0), // 25 MHz
      .CLKOUT0_DUTY_CYCLE           (0.5),
      .CLKOUT0_PHASE                (0.0),  // Phase offset for CLKOUT outputs (-360.000-360.000).
      .CLKOUT4_CASCADE              ("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .COMPENSATION                 ("INTERNAL"), // ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      .DIVCLK_DIVIDE                (1), // Master division value (1-106)
      .STARTUP_WAIT                 ("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
      .CLKFBOUT_USE_FINE_PS         ("FALSE"),
      .CLKOUT0_USE_FINE_PS          ("TRUE")
   ) U_mmcm (
      // Clock Outputs:
      .CLKOUT0                      (progclk), 
      .CLKOUT0B                     (), // WARNING: Vivado doesn't let you cascade MMCMs from CLKOUT0B, and the error is cryptic if you do!
      .CLKOUT1                      (),
      .CLKOUT1B                     (),
      .CLKOUT2                      (),
      .CLKOUT2B                     (),
      .CLKOUT3                      (),
      .CLKOUT3B                     (),
      .CLKOUT4                      (),
      .CLKOUT5                      (),
      .CLKOUT6                      (),
      // Feedback Clocks:
      .CLKFBOUT                     (mmcm_clkfb),
      .CLKFBOUTB                    (),
      // Status Ports: 1-bit (each) output: MMCM status ports
      .CLKFBSTOPPED                 (),
      .CLKINSTOPPED                 (),
      .LOCKED                       (mmcm_locked),
      // Clock Inputs:
      .CLKIN1                       (clk_usb),
      .CLKIN2                       (1'b0),
      // Control Ports: 1-bit (each) input: MMCM control ports
      .CLKINSEL                     (1'b1),
      .PWRDWN                       (shutdown),
      .RST                          (drp_reset),
      // DRP Ports:
      .DADDR                        (drp_addr),
      .DCLK                         (clk_usb),
      .DEN                          (drp_den),
      .DI                           (drp_din),
      .DWE                          (drp_dwe),
      .DO                           (drp_dout),
      .DRDY                         (),
      // Dynamic Phase Shift Ports:
      .PSCLK                        (clk_usb),
      .PSEN                         (1'b0),
      .PSINCDEC                     (1'b0),
      .PSDONE                       (),
      // Feedback Clocks
      .CLKFBIN                      (mmcm_clkfb) // 1-bit input: Feedback clock
   );

   // Set to 200 MHz default for Vivado timing closure. Input clock is 25 MHz:
   MMCME2_ADV #(
      .BANDWIDTH                    ("OPTIMIZED"), // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F              (48.0), // Multiply value for all CLKOUT (2.000-64.000)
      //.CLKOUT0_DIVIDE_F             (6.0), // 200 MHz
      //.CLKOUT0_DIVIDE_F             (7.0), // 170 MHz
      .CLKOUT0_DIVIDE_F             (8.0), // 150 MHz
      //.CLKFBOUT_MULT_F              (60.0),
      //.CLKOUT0_DIVIDE_F             (9.0), // 166 MHz
      .CLKFBOUT_PHASE               (0.0), // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD                (40.0), // 25 MHz
      .CLKOUT0_DUTY_CYCLE           (0.5),
      .CLKOUT0_PHASE                (0.0),  // Phase offset for CLKOUT outputs (-360.000-360.000).
      .CLKOUT4_CASCADE              ("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .COMPENSATION                 ("INTERNAL"), // ZHOLD, BUF_IN, EXTERNAL, INTERNAL
      .DIVCLK_DIVIDE                (1), // Master division value (1-106)
      .STARTUP_WAIT                 ("FALSE"), // Delays DONE until MMCM is locked (FALSE, TRUE)
      .CLKFBOUT_USE_FINE_PS         ("FALSE"),
      .CLKOUT0_USE_FINE_PS          ("TRUE")
   ) U_mmcm_hr (
      // Clock Outputs:
      .CLKOUT0                      (progclk_hr), 
      .CLKOUT0B                     (), // WARNING: Vivado doesn't let you cascade MMCMs from CLKOUT0B, and the error is cryptic if you do!
      .CLKOUT1                      (),
      .CLKOUT1B                     (),
      .CLKOUT2                      (),
      .CLKOUT2B                     (),
      .CLKOUT3                      (),
      .CLKOUT3B                     (),
      .CLKOUT4                      (),
      .CLKOUT5                      (),
      .CLKOUT6                      (),
      // Feedback Clocks:
      .CLKFBOUT                     (mmcm_hr_clkfb),
      .CLKFBOUTB                    (),
      // Status Ports: 1-bit (each) output: MMCM status ports
      .CLKFBSTOPPED                 (),
      .CLKINSTOPPED                 (),
      .LOCKED                       (mmcm_hr_locked),
      // Clock Inputs:
      .CLKIN1                       (clk_usb),
      .CLKIN2                       (1'b0),
      // Control Ports: 1-bit (each) input: MMCM control ports
      .CLKINSEL                     (1'b1),
      .PWRDWN                       (shutdown),
      .RST                          (drp_hr_reset),
      // DRP Ports:
      .DADDR                        (drp_hr_addr),
      .DCLK                         (clk_usb),
      .DEN                          (drp_hr_den),
      .DI                           (drp_hr_din),
      .DWE                          (drp_hr_dwe),
      .DO                           (drp_hr_dout),
      .DRDY                         (),
      // Dynamic Phase Shift Ports:
      .PSCLK                        (clk_usb),
      .PSEN                         (1'b0),
      .PSINCDEC                     (1'b0),
      .PSDONE                       (),
      // Feedback Clocks
      .CLKFBIN                      (mmcm_hr_clkfb) // 1-bit input: Feedback clock
   );


`else
    assign progclk = clk_usb;
    assign mmcm_locked = 1'b1;
    assign progclk_hr = clk_usb;
    assign mmcm_hr_locked = 1'b1;

`endif

endmodule

`default_nettype wire
