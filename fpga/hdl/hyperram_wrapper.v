`timescale 1 ns / 1 ps
`default_nettype none

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


Wrapper for hr_pll_example module.
Look there for full register definitions, but basically it works like this:
(reads and writes are on the lb1_* and lb2_* interfaces, "1" are for hyperram chip 1,
"2" for chip 2; that interface should be self-explanatory)

1. To configure the controller and the Hyperram:
    (a) write the control word to LB address 0x14,
    (b) write 0x05 to LB address 0x1c

2. To write:
    (a) write the hyperram address to LB address 0x10
    (b) write 32 bits data to LB address 0x14
    (c) (optionally) write the next 32 bits data to LB address 0x18
    (d) write 0x03 (to write 64 bits) or 0x01 (to write 32 bits) to LB address 0x1c

3. To read:
    (a) write the hyperram address to LB address 0x10
    (b) write 0x04 to LB address 0x1c
    (c) obtain the first 32 bits read data by reading LB address 0x14
    (d) (optionally) obtain the next 32 bits data by reading LB address 0x18

IMPORTANT NOTE: the hyperram_busy status signals have some lag (after
dispatching a job to hr_pll_example, it takes a few cycles for busy to
assert).

*************************************************************************/

module hyperram_wrapper (
    input wire                          hreset,
    input wire                          hclk,

    // status/debug:
    output wire                         error,
    output wire                         clk_90p_locked,

    // register interface:
    input  wire                         lb1_wr,
    input  wire                         lb1_rd,
    input  wire [31:0]                  lb1_addr,
    input  wire [31:0]                  lb1_wr_d,
    output wire [31:0]                  lb1_rd_d,
    output wire                         lb1_rd_rdy,

    input  wire                         lb2_wr,
    input  wire                         lb2_rd,
    input  wire [31:0]                  lb2_addr,
    input  wire [31:0]                  lb2_wr_d,
    output wire [31:0]                  lb2_rd_d,
    output wire                         lb2_rd_rdy,

    // Hyperram:
    inout  wire [7:0]                   hypr1_dq,
    inout  wire                         hypr1_rwds,
    output wire                         hypr1_ckp,
    output wire                         hypr1_ckn,
    output wire                         hypr1_rst_l,
    output wire                         hypr1_cs_l,
    output wire                         hypr1_busy,

    inout  wire [7:0]                   hypr2_dq,
    inout  wire                         hypr2_rwds,
    output wire                         hypr2_ckp,
    output wire                         hypr2_ckn,
    output wire                         hypr2_rst_l,
    output wire                         hypr2_cs_l,
    output wire                         hypr2_busy,

    input  wire                         hypr1_busy_stuck,
    input  wire                         hypr2_busy_stuck

);

    wire        clk_90p;
    wire [7:0]  hypr1_dq_in;
    wire [7:0]  hypr1_dq_out;
    wire        hypr1_dq_oe_l;
    wire        hypr1_rwds_in;
    wire        hypr1_rwds_out;
    wire        hypr1_rwds_oe_l;
    wire        hypr1_ck;

    wire [7:0]  hypr2_dq_in;
    wire [7:0]  hypr2_dq_out;
    wire        hypr2_dq_oe_l;
    wire        hypr2_rwds_in;
    wire        hypr2_rwds_out;
    wire        hypr2_rwds_oe_l;
    wire        hypr2_ck;

    assign error = hypr1_busy || hypr2_busy; // TODO- change later


    `ifdef __ICARUS__
        assign hypr1_dq = (~hypr1_dq_oe_l)? 8'bz : hypr1_dq_out;
        assign hypr1_dq_in = hypr1_dq;
        assign hypr1_rwds = (~hypr1_rwds_oe_l)? 1'bz : hypr1_rwds_out;

        assign hypr2_dq = (~hypr2_dq_oe_l)? 8'bz : hypr2_dq_out;
        assign hypr2_dq_in = hypr2_dq;
        assign hypr2_rwds = (~hypr2_rwds_oe_l)? 1'bz : hypr2_rwds_out;

    `else
        genvar i;
        generate
            for (i = 0; i < 8; i = i + 1) begin: gen_dq_iobuf
                IOBUF U_hypr1_dq_io (
                    .I          (hypr1_dq_out[i]),
                    .O          (hypr1_dq_in[i]),
                    .T          (hypr1_dq_oe_l),
                    .IO         (hypr1_dq[i])
                );
                IOBUF U_hypr2_dq_io (
                    .I          (hypr2_dq_out[i]),
                    .O          (hypr2_dq_in[i]),
                    .T          (hypr2_dq_oe_l),
                    .IO         (hypr2_dq[i])
                );

            end
        endgenerate

        IOBUF U_hypr1_rwds_io (
            .I          (hypr1_rwds_out),
            .O          (hypr1_rwds_in),
            .T          (hypr1_rwds_oe_l),
            .IO         (hypr1_rwds)
        );
        IOBUF U_hypr2_rwds_io (
            .I          (hypr2_rwds_out),
            .O          (hypr2_rwds_in),
            .T          (hypr2_rwds_oe_l),
            .IO         (hypr2_rwds)
        );

    `endif


`ifdef HYPERRAM_MODEL
    hr_model U_hyperram1 (
        .reset          (hreset         ),
        .clk            (hclk           ),
        .lb_wr          (lb1_wr         ),
        .lb_rd          (lb1_rd         ),
        .lb_addr        (lb1_addr       ),
        .lb_wr_d        (lb1_wr_d       ),
        .lb_rd_d        (lb1_rd_d       ),
        .lb_rd_rdy      (lb1_rd_rdy     ),
        .hyperram_busy  (hypr1_busy      )
    );

    hr_model U_hyperram2 (
        .reset          (hreset         ),
        .clk            (hclk           ),
        .lb_wr          (lb2_wr         ),
        .lb_rd          (lb2_rd         ),
        .lb_addr        (lb2_addr       ),
        .lb_wr_d        (lb2_wr_d       ),
        .lb_rd_d        (lb2_rd_d       ),
        .lb_rd_rdy      (lb2_rd_rdy     ),
        .hyperram_busy  (hypr2_busy      )
    );


`else
    hr_pll_example U_hyperram1 (
        .simulation_en  (1'b0           ),
        .auto_cfg_en    (1'b0           ),
        .reset          (hreset         ),
        .clk            (hclk           ),
        .clk_90p        (clk_90p        ),
        .lb_wr          (lb1_wr         ),
        .lb_rd          (lb1_rd         ),
        .lb_addr        (lb1_addr       ),
        .lb_wr_d        (lb1_wr_d       ),
        .lb_rd_d        (lb1_rd_d       ),
        .lb_rd_rdy      (lb1_rd_rdy     ),
        .sump2_events   (               ),
                                       
        .dram_dq_in     (hypr1_dq_in     ),
        .dram_dq_out    (hypr1_dq_out    ),
        .dram_dq_oe_l   (hypr1_dq_oe_l   ),
                                       
        .dram_rwds_in   (hypr1_rwds_in   ),
        .dram_rwds_out  (hypr1_rwds_out  ),
        .dram_rwds_oe_l (hypr1_rwds_oe_l ),
                                       
        .dram_ck        (hypr1_ck        ),
        .dram_rst_l     (hypr1_rst_l     ),
        .dram_cs_l      (hypr1_cs_l      ),

        .hyperram_busy  (hypr1_busy      ),
        .busy_stuck     (hypr1_busy_stuck)
    );

    hr_pll_example U_hyperram2 (
        .simulation_en  (1'b0           ),
        .auto_cfg_en    (1'b0           ),
        .reset          (hreset         ),
        .clk            (hclk           ),
        .clk_90p        (clk_90p        ),
        .lb_wr          (lb2_wr         ),
        .lb_rd          (lb2_rd         ),
        .lb_addr        (lb2_addr       ),
        .lb_wr_d        (lb2_wr_d       ),
        .lb_rd_d        (lb2_rd_d       ),
        .lb_rd_rdy      (lb2_rd_rdy     ),
        .sump2_events   (               ),
                                       
        .dram_dq_in     (hypr2_dq_in     ),
        .dram_dq_out    (hypr2_dq_out    ),
        .dram_dq_oe_l   (hypr2_dq_oe_l   ),

        .dram_rwds_in   (hypr2_rwds_in   ),
        .dram_rwds_out  (hypr2_rwds_out  ),
        .dram_rwds_oe_l (hypr2_rwds_oe_l ),

        .dram_ck        (hypr2_ck        ),
        .dram_rst_l     (hypr2_rst_l     ),
        .dram_cs_l      (hypr2_cs_l      ),

        .hyperram_busy  (hypr2_busy      ),
        .busy_stuck     (hypr2_busy_stuck)
    );
`endif


    `ifdef __ICARUS__
        assign hypr1_ckp = hypr1_ck;
        assign hypr1_ckn = hypr1_ck;
        assign hypr2_ckp = hypr2_ck;
        assign hypr2_ckn = hypr2_ck;
        assign clk_90p = hclk;
        assign clk_90p_locked = 1'b1;

    `else
        `ifdef SONATA
            // single-ended
            assign hypr1_ckp = hypr1_ck; 
            assign hypr2_ckp = hypr2_ck; 
            assign hypr1_ckn = 1'b0; 
            assign hypr2_ckn = 1'b0; 

        `else
            OBUFDS #(
               .IOSTANDARD       ("LVDS"),
               //.IOSTANDARD       ("LVCMOS18"),
               .SLEW             ("FAST")
            ) U_OBUFDS_hypr1_clk_out (
               .O                (hypr1_ckp),
               .OB               (hypr1_ckn),
               .I                (hypr1_ck)
            );

            OBUFDS #(
               .IOSTANDARD       ("LVDS"),
               //.IOSTANDARD       ("LVCMOS18"),
               .SLEW             ("FAST")
            ) U_OBUFDS_hypr2_clk_out (
               .O                (hypr2_ckp),
               .OB               (hypr2_ckn),
               .I                (hypr2_ck)
            );
        `endif

        wire clk_90p_fb;
    `ifdef ULTRASCALE
        // TODO: optimize mul/div settings for 200 MHz clock (or whatever we end up using)
        PLLE3_BASE #(
            .CLKFBOUT_MULT      (16),
            .CLKFBOUT_PHASE     (0),
            .CLKIN_PERIOD       (14),
            .DIVCLK_DIVIDE      (1),
            .CLKOUT0_DIVIDE     (16),
            .CLKOUT0_PHASE      (90)
        ) U_clk90p (
            .CLKIN              (hclk),
            .LOCKED             (clk_90p_locked),
            .CLKOUTPHY          (),
            .CLKOUT0            (clk_90p),
            .CLKOUT0B           (),
            .CLKOUT1            (),
            .CLKOUT1B           (),
            .CLKOUTPHYEN        (1'b0),
            .PWRDWN             (1'b0),
            .RST                (hreset),
            .CLKFBIN            (clk_90p_fb),
            .CLKFBOUT           (clk_90p_fb)
        );

    `else
        // TODO: assuming 100 MHz input clock; drive to max VCO (1600) so that 50 MHz input can also work:
        PLLE2_BASE #(
            .CLKFBOUT_MULT      (16),
            .CLKFBOUT_PHASE     (0),
            .CLKIN1_PERIOD      (14),
            .DIVCLK_DIVIDE      (1),
            .CLKOUT0_DIVIDE     (16),
            .CLKOUT0_PHASE      (90)
        ) U_clk90p (
            .CLKIN1             (hclk),
            .LOCKED             (clk_90p_locked),
            .CLKOUT0            (clk_90p),
            .CLKOUT1            (),
            .CLKOUT2            (),
            .CLKOUT3            (),
            .CLKOUT4            (),
            .CLKOUT5            (),
            .PWRDWN             (1'b0),
            .RST                (hreset),
            .CLKFBIN            (clk_90p_fb),
            .CLKFBOUT           (clk_90p_fb)
        );
    `endif

   `endif


endmodule
`default_nettype wire

