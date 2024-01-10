`timescale 1 ns / 1 ps
`default_nettype none

/***********************************************************************
This file is part of the ChipWhisperer Project. See www.newae.com for more
details, or the codebase at http://www.chipwhisperer.com

Copyright (c) 2024, NewAE Technology Inc. All rights reserved.
Author: Jean-Pierre Thibault <jpthibault@newae.com>

  chipwhisperer is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  chipwhisperer is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU Lesser General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with chipwhisperer.  If not, see <http://www.gnu.org/licenses/>.

*************************************************************************/

module hyperram_hbmc_wrapper (
    input wire                          hreset,
    input wire                          hclk,

    // status/debug:
    output wire                         clk_90p_locked,
    output wire                         clk_iserdes_locked,

    // AXI interface:
    input wire                          s_axi_aclk,
    input wire                          s_axi_aresetn,

    // write address:
    input wire [0 : 0]                  s_axi_awid,
    input wire [31 : 0]                 s_axi_awaddr,
    input wire [7 : 0]                  s_axi_awlen,
    input wire [2 : 0]                  s_axi_awsize,
    input wire [1 : 0]                  s_axi_awburst,
    input wire                          s_axi_awlock,
    input wire [3 : 0]                  s_axi_awregion,
    input wire [3 : 0]                  s_axi_awcache,
    input wire [3 : 0]                  s_axi_awqos,
    input wire [2 : 0]                  s_axi_awprot,
    input wire                          s_axi_awvalid,
    output wire                         s_axi_awready,

    // write data:
    input wire [31 : 0]                 s_axi_wdata,
    input wire [3 : 0]                  s_axi_wstrb,
    input wire                          s_axi_wlast,
    input wire                          s_axi_wvalid,
    output wire                         s_axi_wready,

    // write response:
    output wire [0 : 0]                 s_axi_bid,
    output wire [1 : 0]                 s_axi_bresp,
    output wire                         s_axi_bvalid,
    input wire                          s_axi_bready,

    // read address:
    input wire [0 : 0]                  s_axi_arid,
    input wire [31 : 0]                 s_axi_araddr,
    input wire [7 : 0]                  s_axi_arlen,
    input wire [2 : 0]                  s_axi_arsize,
    input wire [1 : 0]                  s_axi_arburst,
    input wire                          s_axi_arlock,
    input wire [3 : 0]                  s_axi_arregion,
    input wire [3 : 0]                  s_axi_arcache,
    input wire [3 : 0]                  s_axi_arqos,
    input wire [2 : 0]                  s_axi_arprot,
    input wire                          s_axi_arvalid,
    output wire                         s_axi_arready,

    // read data:
    output wire [0 : 0]                 s_axi_rid,
    output wire [31 : 0]                s_axi_rdata,
    output wire [1 : 0]                 s_axi_rresp,
    output wire                         s_axi_rlast,
    output wire                         s_axi_rvalid,
    input wire                          s_axi_rready,

    // Hyperram:
    inout  wire [7:0]                   hypr_dq,
    inout  wire                         hypr_rwds,
    output wire                         hypr_ckp,
    output wire                         hypr_ckn,
    output wire                         hypr_rst_l,
    output wire                         hypr_cs_l,
    output wire                         hypr_busy

);

    wire        clk_90p;
    wire        clk_iserdes;


    `ifdef __ICARUS__
        assign clk_90p = hclk;
        assign clk_90p_locked = 1'b1;
        assign clk_iserdes = hclk;
        assign clk_iserdes_locked = 1'b1;

    `else
        wire clk_90p_fb;
        wire clk_iserdes_fb;
    `ifdef ULTRASCALE
        // optimize mul/div settings for 200 MHz clock (or whatever we end up using)?
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
        // NOTE: these mul/div settings work with input clock from 100 to 200 MHz:
        PLLE2_BASE #(
            .CLKFBOUT_MULT      (8),
            .CLKFBOUT_PHASE     (0),
            .CLKIN1_PERIOD      (5),
            .DIVCLK_DIVIDE      (1),
            .CLKOUT0_DIVIDE     (8),
            .CLKOUT0_PHASE      (90)
        ) U_clk90p_pll (
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

        // NOTE: these mul/div settings work with input clock from 133 to 300 MHz:
        // generates 3x clock for SERDES:
        PLLE2_BASE #(
            .CLKFBOUT_MULT      (6),
            .CLKFBOUT_PHASE     (0),
            .CLKIN1_PERIOD      (5),
            .DIVCLK_DIVIDE      (1),
            .CLKOUT0_DIVIDE     (2),
            .CLKOUT0_PHASE      (0)
        ) U_iserdes_pll (
            .CLKIN1             (hclk),
            .LOCKED             (clk_iserdes_locked),
            .CLKOUT0            (clk_iserdes),
            .CLKOUT1            (),
            .CLKOUT2            (),
            .CLKOUT3            (),
            .CLKOUT4            (),
            .CLKOUT5            (),
            .PWRDWN             (1'b0),
            .RST                (hreset),
            .CLKFBIN            (clk_iserdes_fb),
            .CLKFBOUT           (clk_iserdes_fb)
        );

    `endif

   `endif

`ifndef __ICARUS__
    OpenHBMC U_HBMC (
      .clk_hbmc_0           (hclk           ),      // input wire clk_hbmc_0
      .clk_hbmc_90          (clk_90p        ),      // input wire clk_hbmc_90
      .clk_iserdes          (clk_iserdes    ),      // input wire clk_iserdes
      .s_axi_aclk           (s_axi_aclk     ),      // input wire s_axi_aclk
      .s_axi_aresetn        (s_axi_aresetn  ),      // input wire s_axi_aresetn
      .s_axi_awid           (s_axi_awid     ),      // input wire [0 : 0] s_axi_awid
      .s_axi_awaddr         (s_axi_awaddr   ),      // input wire [31 : 0] s_axi_awaddr
      .s_axi_awlen          (s_axi_awlen    ),      // input wire [7 : 0] s_axi_awlen
      .s_axi_awsize         (s_axi_awsize   ),      // input wire [2 : 0] s_axi_awsize
      .s_axi_awburst        (s_axi_awburst  ),      // input wire [1 : 0] s_axi_awburst
      .s_axi_awlock         (s_axi_awlock   ),      // input wire s_axi_awlock
      .s_axi_awregion       (s_axi_awregion ),      // input wire [3 : 0] s_axi_awregion
      .s_axi_awcache        (s_axi_awcache  ),      // input wire [3 : 0] s_axi_awcache
      .s_axi_awqos          (s_axi_awqos    ),      // input wire [3 : 0] s_axi_awqos
      .s_axi_awprot         (s_axi_awprot   ),      // input wire [2 : 0] s_axi_awprot
      .s_axi_awvalid        (s_axi_awvalid  ),      // input wire s_axi_awvalid
      .s_axi_awready        (s_axi_awready  ),      // output wire s_axi_awready
      .s_axi_wdata          (s_axi_wdata    ),      // input wire [31 : 0] s_axi_wdata
      .s_axi_wstrb          (s_axi_wstrb    ),      // input wire [3 : 0] s_axi_wstrb
      .s_axi_wlast          (s_axi_wlast    ),      // input wire s_axi_wlast
      .s_axi_wvalid         (s_axi_wvalid   ),      // input wire s_axi_wvalid
      .s_axi_wready         (s_axi_wready   ),      // output wire s_axi_wready
      .s_axi_bid            (s_axi_bid      ),      // output wire [0 : 0] s_axi_bid
      .s_axi_bresp          (s_axi_bresp    ),      // output wire [1 : 0] s_axi_bresp
      .s_axi_bvalid         (s_axi_bvalid   ),      // output wire s_axi_bvalid
      .s_axi_bready         (s_axi_bready   ),      // input wire s_axi_bready
      .s_axi_arid           (s_axi_arid     ),      // input wire [0 : 0] s_axi_arid
      .s_axi_araddr         (s_axi_araddr   ),      // input wire [31 : 0] s_axi_araddr
      .s_axi_arlen          (s_axi_arlen    ),      // input wire [7 : 0] s_axi_arlen
      .s_axi_arsize         (s_axi_arsize   ),      // input wire [2 : 0] s_axi_arsize
      .s_axi_arburst        (s_axi_arburst  ),      // input wire [1 : 0] s_axi_arburst
      .s_axi_arlock         (s_axi_arlock   ),      // input wire s_axi_arlock
      .s_axi_arregion       (s_axi_arregion ),      // input wire [3 : 0] s_axi_arregion
      .s_axi_arcache        (s_axi_arcache  ),      // input wire [3 : 0] s_axi_arcache
      .s_axi_arqos          (s_axi_arqos    ),      // input wire [3 : 0] s_axi_arqos
      .s_axi_arprot         (s_axi_arprot   ),      // input wire [2 : 0] s_axi_arprot
      .s_axi_arvalid        (s_axi_arvalid  ),      // input wire s_axi_arvalid
      .s_axi_arready        (s_axi_arready  ),      // output wire s_axi_arready
      .s_axi_rid            (s_axi_rid      ),      // output wire [0 : 0] s_axi_rid
      .s_axi_rdata          (s_axi_rdata    ),      // output wire [31 : 0] s_axi_rdata
      .s_axi_rresp          (s_axi_rresp    ),      // output wire [1 : 0] s_axi_rresp
      .s_axi_rlast          (s_axi_rlast    ),      // output wire s_axi_rlast
      .s_axi_rvalid         (s_axi_rvalid   ),      // output wire s_axi_rvalid
      .s_axi_rready         (s_axi_rready   ),      // input wire s_axi_rready
      .hb_dq                (hypr_dq        ),      // inout wire [7 : 0] hb_dq
      .hb_rwds              (hypr_rwds      ),      // inout wire hb_rwds
      .hb_ck_p              (hypr_ckp       ),      // output wire hb_ck_p
      .hb_ck_n              (hypr_ckn       ),      // output wire hb_ck_n
      .hb_reset_n           (hypr_rst_l     ),      // output wire hb_reset_n
      .hb_cs_n              (hypr_cs_l      )       // output wire hb_cs_n
    );
`endif


endmodule
`default_nettype wire

