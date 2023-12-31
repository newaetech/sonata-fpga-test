/* 
Test project for Sonata board.

Copyright (c) 2023, NewAE Technology Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted without restriction. Note that modules within
the project may have additional restrictions, please carefully inspect
additional licenses.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those
of the authors and should not be interpreted as representing official policies,
either expressed or implied, of NewAE Technology Inc.
*/

`timescale 1ns / 1ps
`default_nettype none 

module sonata_top #(
    parameter pBIT_RATE = 109  // number of clocks per UART bit; 230400 bps @ 25 MHz
)(
    // convention: uppercase indicate same name as on schematic; lowercase different
    input wire                          MAINCLK,
    input wire                          NRST,

    // UART (SS2) Interface:
    input wire                          ss2_rx,
    output wire                         ss2_tx,

    // LEDs:
    output reg  [7:0]                   USRLED,
    output reg  [8:0]                   CHERIERR,
    output reg                          LED_LEGACY,
    output reg                          LED_CHERI,
    output reg                          LED_HALTED,
    output reg                          LED_BOOTOK,

    // switches:
    input wire  [7:0]                   USRSW,
    input wire  [4:0]                   NAVSW,
    input wire  [2:0]                   SELSW,

    // Hyperram:
    inout  wire [7:0]                   HYPERRAM_DQ,
    inout  wire                         HYPERRAM_RWDS,
    output wire                         HYPERRAM_CKP,
    output wire                         HYPERRAM_CKN,
    output wire                         HYPERRAM_nRST,
    output wire                         HYPERRAM_CS,


    // XADC:
    input  wire [5:0]                   ANALOG_DIGITAL,
    input  wire [5:0]                   ANALOG_P,
    input  wire [5:0]                   ANALOG_N,

    // misc:
    output wire                         FPGAIO_TURBO

    // all the other interface signals that we're not using but still need to be driven:
    // TODO

);

    localparam pBYTECNT_SIZE = 8; // property of ss2 module
    localparam pADDR_WIDTH = 32; // property of ss2 module
    localparam pPT_WIDTH = 128;
    localparam pCT_WIDTH = 128;
    localparam pKEY_WIDTH = 128;


    wire [7:0] dut_datai;
    wire [7:0] dut_datao;
    wire [31:0] dut_address;
    wire dut_rdn;
    wire dut_wrn;
    wire dut_cen;
    wire ss2_error;
    wire reset = !NRST;

    wire [7:0] dut_dout;
    wire isout;
    wire [pADDR_WIDTH-pBYTECNT_SIZE-1:0] reg_address;
    wire [pBYTECNT_SIZE-1:0] reg_bytecnt;
    wire [7:0] write_data;
    wire [7:0] read_data;
    wire [7:0] read_data_main;
    wire [7:0] read_data_xadc;
    wire [7:0] read_data_mmcm_drp;
    wire reg_read;
    wire reg_write;
    wire mmcm_locked;
    wire xadc_error_flag;
    wire progclk;


`ifdef __ICARUS__
    wire mainclk_buf = MAINCLK;

`else
    wire mainclk_bufg;
    wire mainclk_buf;
    IBUFG clkibuf (
        .O(mainclk_bufg),
        .I(MAINCLK) 
    );
    BUFG clkbuf(
        .O(mainclk_buf),
        .I(mainclk_bufg)
    );

`endif

    ss2 #(
        .pBIT_RATE              (pBIT_RATE),
        .pDATA_BITS             (8),
        .pSTOP_BITS             (1),
        .pPARITY_BITS           (0),
        .pPARITY_ENABLED        (0)
    ) U_ss2 (
        .clk                    (mainclk_buf ),
        .resetn                 (NRST        ),
        .rxd                    (ss2_rx      ),
        .txd                    (ss2_tx      ),
        .dut_data               (dut_datai   ),
        .dut_wdata              (dut_datao   ),
        .dut_address            (dut_address ),
        .dut_rdn                (dut_rdn     ),
        .dut_wrn                (dut_wrn     ),
        .dut_cen                (dut_cen     ),
        .error                  (ss2_error   )
    );

    sonata_usb_reg_fe #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE),
       .pADDR_WIDTH             (pADDR_WIDTH)
    ) U_usb_reg_fe (
       .rst                     (reset),
       .usb_clk                 (mainclk_buf), 
       .usb_din                 (dut_datao), 
       .usb_dout                (dut_datai), 
       .usb_rdn                 (dut_rdn), 
       .usb_wrn                 (dut_wrn),
       .usb_cen                 (dut_cen),
       .usb_addr                (dut_address),
       .usb_isout               (isout), 
       .reg_address             (reg_address), 
       .reg_bytecnt             (reg_bytecnt), 
       .reg_datao               (write_data), 
       .reg_datai               (read_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write) 
    );

    `ifdef ILA_FE
       ila_fe U_ila_fe (
           .clk         (mainclk_buf ),
           .probe0      (ss2_rx      ),
           .probe1      (ss2_tx      ),
           .probe2      (dut_dout    ),         // 7:0
           .probe3      (dut_address ),         // 31:0
           .probe4      (dut_rdn     ),
           .probe5      (dut_wrn     ),
           .probe6      (dut_cen     ),
           .probe7      (ss2_error   ),

           .probe8      (reg_address ),         // 23:0
           .probe9      (reg_bytecnt ),         // 7:0
           .probe10     (write_data  ),         // 7:0
           .probe11     (read_data   ),         // 7:0
           .probe12     (reg_read    ),
           .probe13     (reg_write   )
       );
    `endif


    wire [pKEY_WIDTH-1:0] crypt_key;
    wire [pPT_WIDTH-1:0] crypt_textout;
    wire [pCT_WIDTH-1:0] crypt_cipherin;
    wire crypt_ready;
    wire crypt_start;
    wire crypt_done;
    wire crypt_busy;


    wire        lb1_wr;
    wire        lb1_rd;
    wire [31:0] lb1_addr;
    wire [31:0] lb1_wr_d;
    wire [31:0] lb1_rd_d;
    wire        lb1_rd_rdy;

    wire        manual_lb1_wr;
    wire        manual_lb1_rd;
    wire [31:0] manual_lb1_addr;
    wire [31:0] manual_lb1_wr_d;
    wire        auto_lb1_wr;
    wire        auto_lb1_rd;
    wire [31:0] auto_lb1_addr;
    wire [31:0] auto_lb1_wr_d;

    wire        hreset;
    wire        memtest_error;
    wire        clk_90p_locked;
    wire        hypr_busy;
    wire        hypr_busy_stuck;

    wire        lb_manual;
    wire        auto_clear_fail;
    wire        auto_check1;
    wire        auto_lfsr_mode;
    wire        auto_pass;
    wire        auto_fail;
    wire [15:0] auto_iterations;
    wire [31:0] auto_current_addr;
    wire [31:0] auto_errors;
    wire [31:0] auto_error_addr;
    wire [31:0] auto_addr_start;
    wire [31:0] auto_addr_stop;

    wire [7:0]  wait_value;

    wire led_test_mode;
    wire led_flash_all;
    wire [20:0] test_leds;
    wire usrled;

    // MAINCLK Heartbeat
    reg [24:0] mainclk_heartbeat;
    always @(posedge mainclk_buf) mainclk_heartbeat <= mainclk_heartbeat +  25'd1;

    // programmable clock Heartbeat
    reg [24:0] progclk_heartbeat;
    always @(posedge progclk) progclk_heartbeat <= progclk_heartbeat +  23'd1;

    always @(*) begin
        if (led_test_mode) begin
            if (led_flash_all) begin
                USRLED = {8{mainclk_heartbeat[23]}};
                CHERIERR = {9{mainclk_heartbeat[23]}};
                LED_LEGACY = mainclk_heartbeat[23];
                LED_CHERI = mainclk_heartbeat[23];
                LED_HALTED = mainclk_heartbeat[23];
                LED_BOOTOK = mainclk_heartbeat[23];
            end
            else begin
                USRLED = test_leds[7:0];
                CHERIERR = test_leds[16:8];
                LED_LEGACY = test_leds[17];
                LED_CHERI = test_leds[18];
                LED_HALTED = test_leds[19];
                LED_BOOTOK = test_leds[20];
            end
        end
        else begin
            USRLED[0] = mainclk_heartbeat[24];
            USRLED[1] = progclk_heartbeat[24];
            USRLED[2] = usrled;
            USRLED[3] = hypr_busy_stuck;
            USRLED[4] = ~clk_90p_locked;
            USRLED[5] = reset;
            USRLED[6] = mmcm_locked;
            USRLED[7] = ss2_error;
            CHERIERR[0] = xadc_error_flag;
            CHERIERR[8:1] = 8'b0;
            LED_LEGACY = 1'b0;
            LED_CHERI = 1'b0;
            LED_HALTED = 1'b0;
            LED_BOOTOK = 1'b0;
        end
    end

    assign read_data = read_data_main | read_data_xadc | read_data_mmcm_drp;

    wire [15:0] all_switches = {USRSW, NAVSW, SELSW};

    wire [63:0] cores_en;
    wire [7:0] core_sel;

    sonata_reg #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE),
       .pPT_WIDTH               (pPT_WIDTH),
       .pCT_WIDTH               (pCT_WIDTH),
       .pKEY_WIDTH              (pKEY_WIDTH)
    ) U_sonata_reg (
       .reset_i                 (reset),
       .crypto_clk              (progclk),
       .usb_clk                 (mainclk_buf), 
       .hclk                    (progclk),
       .reg_address             (reg_address[7:0]),
       .reg_bytecnt             (reg_bytecnt), 
       .read_data               (read_data_main), 
       .write_data              (write_data),
       .reg_read                (reg_read), 
       .reg_write               (reg_write), 
       .reg_addrvalid           (1'b1),

       .mmcm_locked             (mmcm_locked),

       .I_textout               (128'b0),               // unused
       .I_cipherout             (crypt_cipherin),
       .I_ready                 (crypt_ready),
       .I_done                  (crypt_done),
       .I_busy                  (crypt_busy),

       .O_user_led              (usrled),
       .O_key                   (crypt_key),
       .O_textin                (crypt_textout),
       .O_cipherin              (),                     // unused
       .O_start                 (crypt_start),
       .cores_en                (cores_en),
       .core_sel                (core_sel),

       .reg_hreset              (hreset         ),
       .hypr1_busy              (hypr_busy_stuck),
       .hypr2_busy              (0),
       .clk_90p_locked          (clk_90p_locked ),

       .O_lb_manual             (lb_manual       ),
       .O_auto_clear_fail       (auto_clear_fail ),
       .O_auto_check1           (auto_check1 ),
       .O_auto_check2           (),
       .O_auto_lfsr_mode        (auto_lfsr_mode ),
       .I_auto_pass             (auto_pass       ),
       .I_auto_fail             (auto_fail       ),
       .I_auto_iterations       (auto_iterations ),
       .I_auto_current_addr     (auto_current_addr ),
       .I_auto_errors           (auto_errors     ),
       .I_auto_error_addr       (auto_error_addr ),
       .O_auto_start_addr       (auto_addr_start ),
       .O_auto_stop_addr        (auto_addr_stop  ),
       .O_wait_value            (wait_value  ),

       .lb1_wr                  (manual_lb1_wr         ),
       .lb1_rd                  (manual_lb1_rd         ),
       .lb1_addr                (manual_lb1_addr       ),
       .lb1_wr_d                (manual_lb1_wr_d       ),
       .lb1_rd_d                (lb1_rd_d       ),
       .lb1_rd_rdy              (lb1_rd_rdy     ),

       .lb2_wr                  (),
       .lb2_rd                  (),
       .lb2_addr                (),
       .lb2_wr_d                (),
       .lb2_rd_d                (0),
       .lb2_rd_rdy              (0),

       .O_turbo                 (FPGAIO_TURBO),
       .I_analog_digital        (ANALOG_DIGITAL),
       .I_dips                  (all_switches),
       .O_led_test_mode         (led_test_mode),
       .O_led_flash_all         (led_flash_all),
       .O_test_leds             (test_leds)
    );


    sonata_progclk #(
       .pBYTECNT_SIZE           (pBYTECNT_SIZE)
    ) U_progclk (
       .reset_i          (reset),
       .clk_usb          (mainclk_buf),
       .progclk          (progclk),
       .shutdown         (xadc_error_flag),
       .mmcm_locked      (mmcm_locked),
       .reg_address      (reg_address[7:0]), 
       .reg_bytecnt      (reg_bytecnt), 
       .reg_datao        (read_data_mmcm_drp),
       .reg_datai        (write_data), 
       .reg_read         (reg_read), 
       .reg_write        (reg_write)
    ); 


   wire aes_clk;
   wire [127:0] aes_key;
   wire [127:0] aes_pt;
   wire [127:0] aes_ct [0:`AES_INSTANCES-1];
   wire aes_load;
   wire [`AES_INSTANCES-1:0] aes_busy;

   assign aes_clk = progclk;
   assign aes_key = crypt_key;
   assign aes_pt = crypt_textout;
   assign crypt_cipherin = aes_ct[core_sel];
   assign aes_load = crypt_start;
   assign crypt_ready = 1'b1;
   assign crypt_done = ~aes_busy[0];
   assign crypt_busy = aes_busy[0];


   // Example AES Core
   genvar i;
   generate
       for (i = 0; i < `AES_INSTANCES; i = i + 1) begin: aes_instances
           aes_core aes_core (
               .clk             (aes_clk),
               .load_i          (aes_load & cores_en[i]),
               .key_i           ({aes_key, 128'h0}),
               .data_i          (aes_pt ^ i),
               .size_i          (2'd0), //AES128
               .dec_i           (1'b0),//enc mode
               .data_o          (aes_ct[i]),
               .busy_o          (aes_busy[i])
           );
       end

   endgenerate


   assign lb1_wr        = (lb_manual)? manual_lb1_wr : auto_lb1_wr;
   assign lb1_rd        = (lb_manual)? manual_lb1_rd : auto_lb1_rd;
   assign lb1_addr      = (lb_manual)? manual_lb1_addr : auto_lb1_addr;
   assign lb1_wr_d      = (lb_manual)? manual_lb1_wr_d : auto_lb1_wr_d;


    hyperram_wrapper U_hyperram_wrapper (
        .hreset                         (hreset),
        .hclk                           (progclk),
        .error                          (),
        .clk_90p_locked                 (clk_90p_locked),

        .lb1_wr                         (lb1_wr         ),
        .lb1_rd                         (lb1_rd         ),
        .lb1_addr                       (lb1_addr       ),
        .lb1_wr_d                       (lb1_wr_d       ),
        .lb1_rd_d                       (lb1_rd_d       ),
        .lb1_rd_rdy                     (lb1_rd_rdy     ),

        .lb2_wr                         (0),
        .lb2_rd                         (0),
        .lb2_addr                       (0),
        .lb2_wr_d                       (0),
        .lb2_rd_d                       (),
        .lb2_rd_rdy                     (),

        .hypr1_dq                       (HYPERRAM_DQ    ),
        .hypr1_rwds                     (HYPERRAM_RWDS  ),
        .hypr1_ckp                      (HYPERRAM_CKP   ),
        .hypr1_ckn                      (HYPERRAM_CKN   ),
        .hypr1_rst_l                    (HYPERRAM_nRST  ),
        .hypr1_cs_l                     (HYPERRAM_CS    ),
        .hypr1_busy                     (hypr_busy      ),

        .hypr2_dq                       (),
        .hypr2_rwds                     (),
        .hypr2_ckp                      (),
        .hypr2_ckn                      (),
        .hypr2_rst_l                    (),
        .hypr2_cs_l                     (),
        .hypr2_busy                     (),

        .hypr1_busy_stuck               (hypr_busy_stuck ),
        .hypr2_busy_stuck               ()

    );

    simple_hyperram_rwtest U_hyperram_test(
        .clk                            (progclk        ),
        .reset                          (reset          ),
        .active_usb                     (~lb_manual     ),
        .clear_fail                     (auto_clear_fail),
        .check1                         (auto_check1 ),
        .check2                         (1'b0 ),
        .lfsr_mode                      (auto_lfsr_mode ),
        .pass                           (auto_pass      ),
        .fail                           (auto_fail      ),
        .iteration                      (auto_iterations),
        .current_addr                   (auto_current_addr),
        .total_errors                   (auto_errors    ),
        .error_addr                     (auto_error_addr),
        .addr_start                     (auto_addr_start ),
        .addr_stop                      (auto_addr_stop ),
        .wait_value                     (wait_value     ),
                                                     
        .lb1_wr                         (auto_lb1_wr    ),
        .lb1_rd                         (auto_lb1_rd    ),
        .lb1_addr                       (auto_lb1_addr  ),
        .lb1_wr_d                       (auto_lb1_wr_d  ),
        .lb1_rd_d                       (lb1_rd_d       ),
        .lb1_rd_rdy                     (lb1_rd_rdy     ),
        .hr1_busy                       (hypr_busy     ),
        .hr1_busy_stuck                 (hypr_busy_stuck),

        .lb2_wr                         (),
        .lb2_rd                         (),
        .lb2_addr                       (),
        .lb2_wr_d                       (),
        .lb2_rd_d                       (0),
        .lb2_rd_rdy                     (1'b1),
        .hr2_busy                       (0),
        .hr2_busy_stuck                 ()
    );

   xadc #(
      .pBYTECNT_SIZE    (pBYTECNT_SIZE)
   ) U_xadc (
      .reset_i          (reset),
      .clk_usb          (mainclk_buf),
      .ANALOG_P         (ANALOG_P),
      .ANALOG_N         (ANALOG_N),
      .reg_address      (reg_address[7:0]), 
      .reg_bytecnt      (reg_bytecnt), 
      .reg_datao        (read_data_xadc), 
      .reg_datai        (write_data), 
      .reg_read         (reg_read), 
      .reg_write        (reg_write), 
      .xadc_error       (xadc_error_flag)
   ); 

    /*
`ifdef ILA_RAW_HR
    wire la_clk;
    wire la_locked;
  la_clk_wiz instance_name
  (
    // Clock out ports
    .clk_out1   (la_clk),
    .reset      (reset),
    .locked     (la_locked),
    .clk_in1    (ext_clk)
  );

    ila_raw_hw U_ila_raw_hr1 (
       .clk            (la_clk),
       .probe0         (hypr1_dq),              // 7:0
       .probe1         (hypr1_rwds),
       .probe2         (hypr1_ckp),
       .probe3         (hypr1_ckn),
       .probe4         (hypr1_rst_l),
       .probe5         (hypr1_cs_l),
       .probe6         (hypr1_busy_stuck)
    );

    ila_raw_hw U_ila_raw_hr2 (
       .clk            (la_clk),
       .probe0         (hypr2_dq),              // 7:0
       .probe1         (hypr2_rwds),
       .probe2         (hypr2_ckp),
       .probe3         (hypr2_ckn),
       .probe4         (hypr2_rst_l),
       .probe5         (hypr2_cs_l),
       .probe6         (hypr2_busy_stuck)
    );

`endif
    */


endmodule

`default_nettype wire

