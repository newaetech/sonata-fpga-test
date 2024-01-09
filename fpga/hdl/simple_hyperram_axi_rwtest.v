/* 
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


module simple_hyperram_axi_rwtest (
    input wire                          clk,
    input wire                          reset,
    input wire                          active_usb,
    input wire                          clear_fail,
    input wire                          lfsr_mode,
    output reg                          pass,
    output reg                          fail,
    output reg  [15:0]                  iteration,
    output wire [31:0]                  current_addr,
    output reg  [31:0]                  total_errors,
    output reg  [31:0]                  error_addr,
    input  wire [31:0]                  addr_start,
    input  wire [31:0]                  addr_stop,
    output reg                          read_error,

    // write address:
    output wire [31 : 0]                awaddr,
    output reg                          awvalid,
    input  wire                         awready,

    // write data:
    output wire [31 : 0]                wdata,
    output reg                          wvalid,
    input  wire                         wready,

    // write response:
    input  wire [1 : 0]                 bresp,
    input  wire                         bvalid,
    output wire                         bready,

    // read address:
    output wire [31 : 0]                araddr,
    output reg                          arvalid,
    input wire                          arready,

    // read data:
    input  wire [31 : 0]                rdata,
    input  wire [1 : 0]                 rresp,
    input  wire                         rvalid,
    output wire                         rready

);

localparam pS_IDLE            = 3'd0;
localparam pS_WRITE           = 3'd1;
localparam pS_WAIT_WRITE      = 3'd2;
localparam pS_READ            = 3'd3;
localparam pS_WAIT_READ       = 3'd4;
localparam pS_WAIT_WRITE_RESP = 3'd5;
localparam pS_WAIT_READ_RESP  = 3'd6;
reg [2:0] state;

reg load_lfsr;
reg [31:0] lfsr;

wire [31:0] expected_data = (lfsr_mode)? lfsr ^ haddr : lfsr;

reg writing;

assign current_addr = haddr;
assign awaddr = haddr;
assign araddr = haddr;
assign wdata = expected_data;
assign bready = 1'b1;
assign rready = 1'b1;

// since "active" controls FSM states, let's sync it properly:
(* ASYNC_REG = "TRUE" *) reg[2:0] active_pipe;
reg active;
always @ (posedge clk) begin
    if (reset) begin
        active_pipe <= 0;
        active <= 0;
    end 
    else begin
        {active, active_pipe} <= {active_pipe, active_usb};
    end 
end


reg [31:0] haddr = 32'b0;

// FSM issues write command + data, read command:
always @(posedge clk) begin
    if (reset) begin
        iteration <= 0;
        load_lfsr <= 0;
        writing <= 0;
        total_errors <= 0;
        pass <= 0;
        fail <= 0;

        awvalid <= 0;
        wvalid <= 0;
        arvalid <= 0;

        state <= pS_IDLE;
    end
    else begin
        case (state)

            pS_IDLE: begin
                if (active) begin
                    haddr <= addr_start;
                    load_lfsr <= 1'b1;
                    writing <= 1'b1;
                    state = pS_WRITE;
                end
                else begin
                    iteration <= 0;
                    pass <= 0;
                    fail <= 0;
                    error_addr <= 0;
                    read_error <= 0;
                end
                if (clear_fail)
                    total_errors <= 0;
            end

            pS_WRITE: begin
                load_lfsr <= 1'b0;
                awvalid <= 1;
                wvalid <= 1;
                state <= pS_WAIT_WRITE;
            end

            pS_WAIT_WRITE: begin
                if (awready)
                    awvalid <= 0;
                if (wready)
                    wvalid <= 0;
                if ((~wvalid || wready) && (~awvalid || awready))
                    state <= pS_WAIT_WRITE_RESP;
            end

            pS_WAIT_WRITE_RESP: begin
                if (bvalid)
                    if (~active)
                        state <= pS_IDLE;
                    else if (haddr == addr_stop) begin
                        haddr <= addr_start;
                        writing <= 1'b0;
                        load_lfsr <= 1'b1;
                        state <= pS_READ;
                    end
                    else begin
                        haddr <= haddr + 4;
                        state <= pS_WRITE;
                    end
            end


            pS_READ: begin
                load_lfsr <= 1'b0;
                arvalid <= 1;
                state <= pS_WAIT_READ;
            end

            pS_WAIT_READ: begin
                if (arready) begin
                    arvalid <= 0;
                    state <= pS_WAIT_READ_RESP;
                end
            end

            pS_WAIT_READ_RESP: begin
                if (rvalid) begin
                    if (rresp != 0)
                        read_error <= 1'b1;
                    if (rdata != expected_data) begin
                        total_errors <= total_errors + 1;
                        if (total_errors == 0)
                            error_addr <= haddr;
                    end
                    if (~active)
                        state <= pS_IDLE;
                    else if (haddr == addr_stop) begin
                        haddr <= addr_start;
                        writing <= 1'b1;
                        load_lfsr <= 1'b1;
                        iteration <= iteration + 1;
                        if (total_errors > 0)
                            fail <= 1'b1;
                        else
                            pass <= 1'b1;
                        state <= pS_WRITE;
                    end
                    else begin
                        haddr <= haddr + 4;
                        state <= pS_READ;
                    end
                end
            end


        endcase

    end
end


always @ (posedge clk) begin
    if (reset) begin
        lfsr <= 0;
    end
    else begin
        if (load_lfsr)
            lfsr <= {iteration, ~iteration};
        else if ((state == pS_WRITE) || (state == pS_READ))
            if (lfsr_mode)
                lfsr <= {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
            else
                lfsr <= lfsr + 1;
    end
end


`ifdef ILA_HYPERRAM_AXI_TEST
ila_hyperram_axi_test U_ila_hyperram_test (
	.clk            (clk                ),
	.probe0         (active             ),
	.probe1         (pass               ),
	.probe2         (fail               ),
	.probe3         (state              ), // 2:0
	.probe4         (iteration          ), // 15:0
	.probe5         (read_error         ),
	.probe6         (total_errors       ), // 31:0
	.probe7         (expected_data      ), // 31:0
	.probe8         (writing            ),
        .probe9         (lfsr               ), // 31:0

        .probe10        (awaddr         ), // 31:0
        .probe11        (awvalid        ),
        .probe12        (awready        ),
        .probe13        (wdata          ), // 31:0
        .probe14        (wvalid         ),
        .probe15        (wready         ),
        .probe16        (bresp          ), // 1:0
        .probe17        (bvalid         ),
        .probe18        (bready         ),
        .probe19        (araddr         ), // 31:0
        .probe20        (arvalid        ),
        .probe21        (arready        ),
        .probe22        (rdata          ), // 31:0
        .probe23        (rresp          ), // 1:0
        .probe24        (rvalid         ),
        .probe25        (rready         )
);
`endif

endmodule

`default_nettype wire

