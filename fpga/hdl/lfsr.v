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

*************************************************************************/


`default_nettype none
`timescale 1ns / 1ns

module lfsr (
   input  wire         clk,
   input  wire         rst,
   input  wire [31:0]  I_seed_data,
   input  wire         I_lfsr_reset,
   input  wire         I_lfsr_load,
   input  wire         I_next,
   input  wire [1:0]   I_noise_valid,
   input  wire [7:0]   I_noise_period,
   output wire         out,
   output wire         out_valid,
   output wire [31:0]  O_state
);

   reg [31:0] state;
   reg [31:0] shift;
   reg [4:0] count;
   reg seeded;
   reg running;
   wire out_valid_gate;
   wire valid;

   assign O_state = state;

   always @ (posedge clk) begin
       if (rst) begin
           count <= 0;
           state <= 0;
           shift <= 0;
           seeded <= 0;
           running <= 0;
       end
       else begin
           if (I_lfsr_reset) begin
               count <= 0;
               state <= 0;
               shift <= 0;
               seeded <= 0;
               running <= 0;
           end
           //else if (I_lfsr_load && ~running) begin
           else if (I_lfsr_load) begin
               count <= 0;
               state <= I_seed_data;
               shift <= I_seed_data;
               seeded <= 1'b1;
               running <= 1'b1;
           end
           else if (running) begin
               count <= count + 1;
               if (I_next) begin
                   state <= {state[30:0], state[31] ^ state[21] ^ state[1] ^ state[0]};
                   shift <= state;
               end
               else
                   shift <= {shift[30:0], 1'b0};
           end
       end
   end

   assign out = shift[31];

   assign out_valid_gate = 1'b1;
   /*
   assign out_valid_gate = (I_noise_valid == `NOISE_VALID_ALWAYS_OFF)?     1'b0 :
                           (I_noise_valid == `NOISE_VALID_ALWAYS_ON)?      1'b1 :
                           (I_noise_valid == `NOISE_VALID_ON_AFTER_SEED)?  seeded :
                           (I_noise_valid == `NOISE_VALID_ON_AFTER_COUNTER)? I_timed_noise_valid : 1'b0;
   */

   assign valid = (I_noise_period == 0)? 1'b1 :
                  (I_noise_period == 1)? count[0] :
                  (I_noise_period == 2)? (count[1:0] == 2'b10) :
                  (I_noise_period == 4)? (count[2:0] == 3'b100) :
                  (I_noise_period == 8)? (count[3:0] == 4'b1000) :
                  (I_noise_period == 16)? (count[4:0] == 5'b10000) : 1'b0;

   assign out_valid = out_valid_gate & valid;


endmodule

`default_nettype wire

