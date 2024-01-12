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

`timescale 1 ns / 1 ps
`default_nettype none

module hr_model (
    input wire                          reset,
    input wire                          clk,

    // register interface:
    input  wire                         lb_wr,
    input  wire                         lb_rd,
    input  wire [31:0]                  lb_addr,
    input  wire [31:0]                  lb_wr_d,
    output reg  [31:0]                  lb_rd_d,
    output reg                          lb_rd_rdy,
    output reg                          hyperram_busy
);

reg [31:0] memory [0:1023];
reg [31:0] read_data;
reg [31:0] mem_addr;
reg [31:0] mem_wdata;
reg hr_busy_start;
reg reading;

always @(posedge clk) begin
    if (reset) begin
        hr_busy_start <= 1'b1;
        reading <= 1'b0;
    end

    else begin
        if (lb_wr) begin
            if ((lb_addr == 32'h1c) && (lb_wr_d == 32'h01)) begin
                memory[mem_addr] <= mem_wdata;
                $display("%0t Writing %0h to %0h", $time, mem_wdata, mem_addr);
                hr_busy_start <= 1'b1;
                reading <= 1'b0;
            end
            else if ((lb_addr == 32'h1c) && (lb_wr_d == 32'h04)) begin
                read_data <= memory[mem_addr];
                $display("%0t Reading %0h from %0h", $time, memory[mem_addr], mem_addr);
                hr_busy_start <= 1'b1;
                reading <= 1'b1;
            end
            else if (lb_addr == 32'h10) begin
                hr_busy_start <= 1'b0;
                mem_addr <= lb_wr_d;
            end
            else if (lb_addr == 32'h14) begin
                hr_busy_start <= 1'b0;
                mem_wdata <= lb_wr_d;
            end
        end
        else if (lb_rd) begin
            hr_busy_start <= 1'b1;
            reading <= 1'b1;
        end
        else
            hr_busy_start <= 1'b0;
    end

end

initial begin
    lb_rd_rdy = 0;
    while (1) begin
        wait(hr_busy_start);
        hyperram_busy = 1'b1;
        repeat ($urandom_range(2,10)) @(posedge clk);
        //repeat (2) @(posedge clk);
        hyperram_busy = 1'b0;
        if (reading) begin
            lb_rd_rdy = 1'b1;
            lb_rd_d = read_data;
            repeat (2) @(posedge clk);
            lb_rd_rdy = 1'b0;
        end
        @(posedge clk);
    end
end


endmodule
`default_nettype wire

