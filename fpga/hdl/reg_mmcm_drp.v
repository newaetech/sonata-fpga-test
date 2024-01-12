`timescale 1 ns / 1 ps
`default_nettype none

/***********************************************************************
 Copyright (c) 2021-2024, NewAE Technology Inc
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

*************************************************************************/

module reg_mmcm_drp #(
   parameter pBYTECNT_SIZE = 7,
   parameter pDRP_ADDR = 0,
   parameter pDRP_DATA = 1,
   parameter pDRP_RESET = 2
)(
   input  wire         reset_i,
   input  wire         clk_usb,
   input  wire         selected,     // not really needed, just for compatibility with TraceWhisperer version of this module
   input  wire [7:0]   reg_address,  // Address of register
   input  wire [pBYTECNT_SIZE-1:0]  reg_bytecnt,  // Current byte count
   input  wire [7:0]   reg_datai,    // Data to write
   output reg  [7:0]   reg_datao,    // Data to read
   input  wire         reg_read,     // Read flag
   input  wire         reg_write,    // Write flag

   output reg  [6:0]   drp_addr,
   output reg          drp_den,
   output reg  [15:0]  drp_din,
   input  wire [15:0]  drp_dout,
   output reg          drp_dwe,
   output reg          drp_reset
); 


// DRP usage:
// Writes: push write data to DRP data, then write DRP_ADDR with MSB set.
// Reads: write DRP_ADDR with MSB clear, then obtain read data from DRP_DATA.


   reg [7:0] reg_datao_reg;
   //assign reg_datao = reg_datao_reg;
   always @(posedge clk_usb)
       reg_datao <= reg_datao_reg;

   always @(*) begin
      if (reg_read && selected) begin
         case (reg_address)
           pDRP_ADDR: reg_datao_reg = {1'b0, drp_addr};
           pDRP_DATA: reg_datao_reg = drp_dout[reg_bytecnt*8 +: 8];
           default: reg_datao_reg = 0;
         endcase
      end
      else
         reg_datao_reg = 0;
   end  

   always @(posedge clk_usb) begin
      if (reset_i) begin
         drp_dwe <= 1'b0;
         drp_den <= 1'b0;
         drp_reset <= 1'b0;
      end
      else begin
         if (reg_write && selected) begin
            if (reg_address == pDRP_ADDR) begin
               drp_addr <= reg_datai[6:0];
               drp_den <= 1'b1;
               // DRP write:
               if (reg_datai[7])
                  drp_dwe <= 1'b1;
               // DRP read:
               else
                  drp_dwe <= 1'b0;
            end

            else begin
               drp_dwe <= 1'b0;
               drp_den <= 1'b0;
               if (reg_address == pDRP_DATA)
                  drp_din[reg_bytecnt*8 +: 8] <= reg_datai;
               else if (reg_address == pDRP_RESET)
                  drp_reset <= reg_datai[0];
            end

         end

         else begin
            drp_dwe <= 1'b0;
            drp_den <= 1'b0;
         end

      end
   end


   `ifdef ILA_DRP
       ila_drp U_ila_drp (
	      .clk            (clk_usb),      // input wire clk
	      .probe0         (drp_addr),     // input wire [6:0]  probe0  
	      .probe1         (drp_den),      // input wire [7:0]  probe1 
	      .probe2         (drp_din),      // input wire [15:0] probe2 
	      .probe3         (drp_dout),     // input wire [15:0] probe3 
	      .probe4         (1'b0),         // input wire [0:0]  probe4 
	      .probe5         (drp_dwe)       // input wire [0:0]  probe5 
       );
   `endif


endmodule
`default_nettype wire
