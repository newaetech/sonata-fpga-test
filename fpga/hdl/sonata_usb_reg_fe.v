/***********************************************************************
 Copyright (c) 2020-2024, NewAE Technology Inc
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

module sonata_usb_reg_fe #(
   parameter pADDR_WIDTH = 21,
   parameter pBYTECNT_SIZE = 7,
   parameter pREG_RDDLY_LEN = 3
)(
   input  wire                          usb_clk,
   input  wire                          rst,

   // Interface to host
   input  wire [7:0]                    usb_din,
   output wire [7:0]                    usb_dout,
   output wire                          usb_isout,
   input  wire [pADDR_WIDTH-1:0]        usb_addr,
   input  wire                          usb_rdn,
   input  wire                          usb_wrn,
   input  wire                          usb_cen,

 // Interface to registers
   output wire [pADDR_WIDTH-1:pBYTECNT_SIZE] reg_address,  // Address of register
   output wire [pBYTECNT_SIZE-1:0]      reg_bytecnt,  // Current byte count
   output reg  [7:0]                    reg_datao,    // Data to write
   input  wire [7:0]                    reg_datai,    // Data to read
   output reg                           reg_read,     // Read flag. One clock cycle AFTER this flag is high
                                                      // valid data must be present on the reg_datai bus
   output wire                          reg_write     // Write flag. When high on rising edge valid data is
                                                      // present on reg_datao
);

   reg  [pADDR_WIDTH-1:0] usb_addr_r;
   reg  usb_rdn_r;
   reg  usb_wrn_r;
   reg  usb_cen_r;
   reg  [pREG_RDDLY_LEN-1:0] isoutreg;

   // register USB interface inputs:
   always @(posedge usb_clk) begin
      usb_addr_r <= usb_addr;
      usb_rdn_r <= usb_rdn;
      usb_wrn_r <= usb_wrn;
      usb_cen_r <= usb_cen;
   end

   // reg_address selects the register:
   assign reg_address = usb_addr_r[pADDR_WIDTH-1:pBYTECNT_SIZE];

   // reg_bytecnt selects the byte within the register:
   assign reg_bytecnt = usb_addr_r[pBYTECNT_SIZE-1:0];

   assign reg_write = ~usb_cen_r & ~usb_wrn_r;

   always @(posedge usb_clk) begin
      if (~usb_cen & ~usb_rdn)
         reg_read <= 1'b1;
      else if (usb_rdn)
         reg_read <= 1'b0;
   end

   // drive output data bus:
   always @(posedge usb_clk) begin
       if (rst) begin
           isoutreg <= 0;
       end
       else begin
           isoutreg[0] <= ~usb_rdn_r;
           isoutreg[pREG_RDDLY_LEN-1:1] <= isoutreg[pREG_RDDLY_LEN-2:0];
       end
   end
   assign usb_isout = (|isoutreg) | (~usb_rdn_r);


   assign usb_dout = reg_datai;

   always @(posedge usb_clk)
      reg_datao <= usb_din;


endmodule

`default_nettype wire
