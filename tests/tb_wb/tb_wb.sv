`timescale 1ns/1ps
`define A_WIDTH 9

module tb_wb;

/* power pins */
`ifdef USE_POWER_PINS
    wire VPWR;
    wire VGND;
    assign VPWR=1;
    assign VGND=0;
`endif

// Declare test variables
logic clk, reset;
logic pA_wb_cyc_i, pA_wb_stb_i;
logic pB_wb_cyc_i, pB_wb_stb_i;
logic [3:0] pA_wb_we_i, pB_wb_we_i;
logic [(`A_WIDTH - 1):0] pA_wb_addr_i, pB_wb_addr_i;
logic [31:0] pA_wb_data_i, pB_wb_data_i;
logic pA_wb_ack_o, pA_wb_stall_o;
logic pB_wb_ack_o, pB_wb_stall_o;
logic [31:0] pA_wb_data_o, pB_wb_data_o;

// Instantiate Design 
wishbone wb
(
    .clk(clk),
    .reset(reset),
    .pA_wb_cyc_i(pA_wb_cyc_i),
    .pA_wb_stb_i(pA_wb_stb_i),
    .pB_wb_cyc_i(pB_wb_cyc_i),
    .pB_wb_stb_i(pB_wb_stb_i),
    .pA_wb_we_i(pA_wb_we_i),
    .pB_wb_we_i(pB_wb_we_i),
    .pA_wb_addr_i(pA_wb_addr_i),
    .pB_wb_addr_i(pB_wb_addr_i),
    .pA_wb_data_i(pA_wb_data_i),
    .pB_wb_data_i(pB_wb_data_i),
    .pA_wb_ack_o(pA_wb_ack_o),
    .pA_wb_stall_o(pA_wb_stall_o),
    .pB_wb_ack_o(pB_wb_ack_o),
    .pB_wb_stall_o(pB_wb_stall_o),
    .pA_wb_data_o(pA_wb_data_o),
    .pB_wb_data_o(pB_wb_data_o)
    `ifdef USE_POWER_PINS
    .VPWR(VPWR),
    .VGND(VGND)
    `endif
);

// Sample to drive clock
localparam CLK_PERIOD = 10;
always begin
    #(CLK_PERIOD/2) 
    clk<=~clk;
end

// Necessary to create Waveform
initial begin
    // Name as needed
    $dumpfile("tb_wb.vcd");
    $dumpvars(2, tb_wb);
end

initial begin
    /* init signals */
    clk = 1;
    reset = 1'b1;
    /* port a */
    pA_wb_cyc_i = 1'b1;
    pA_wb_stb_i = 1'b0;
    pA_wb_we_i = 4'b0;
    pA_wb_addr_i = `A_WIDTH'b0;
    /* port b */
    pB_wb_cyc_i = 1'b1;
    pB_wb_stb_i = 1'b0;
    pB_wb_we_i = 4'b0;
    pB_wb_addr_i = `A_WIDTH'b0;
    #CLK_PERIOD
    reset = 1'b0;

    /* attempt writing from A to ram 0 */
    pA_wb_stb_i = 1'b1;
    pA_wb_we_i = 4'b1111;
    pA_wb_data_i = 37;
    pA_wb_addr_i = 4;
    #CLK_PERIOD
    #CLK_PERIOD
    /* attempt writing from A to ram 1 */
    pA_wb_data_i = 42;
    pA_wb_addr_i = -4;
    #CLK_PERIOD
    #CLK_PERIOD
    pA_wb_stb_i = 1'b0;
    #CLK_PERIOD

    /* attempt writing from B to ram 0 */
    pB_wb_stb_i = 1'b1;
    pB_wb_we_i = 4'b1111;
    pB_wb_data_i = 50;
    pB_wb_addr_i = 5;
    #CLK_PERIOD
    #CLK_PERIOD
    /* attempt writing from B to ram 1 */
    pB_wb_data_i = 60;
    pB_wb_addr_i = -8;
    #CLK_PERIOD
    #CLK_PERIOD
    pB_wb_stb_i = 1'b0;
    #CLK_PERIOD

    /* both attempt reading from ram 0 */
    pA_wb_we_i = 4'b0;
    pB_wb_we_i = 4'b0;
    pA_wb_addr_i = 4;
    pB_wb_addr_i = 4;
    pA_wb_data_i = 0;
    pB_wb_data_i = 0;
    pA_wb_stb_i = 1'b1;
    pB_wb_stb_i = 1'b1;
    #CLK_PERIOD
    #CLK_PERIOD
    #CLK_PERIOD

    /* both attempt reading from different rams */
    pA_wb_we_i = 4'b0;
    pB_wb_we_i = 4'b0;
    pA_wb_addr_i = 4;
    pB_wb_addr_i = -4;
    pA_wb_data_i = 0;
    pB_wb_data_i = 0;
    #CLK_PERIOD
    #CLK_PERIOD
    #CLK_PERIOD
    #CLK_PERIOD
    #CLK_PERIOD

    // Make sure to call finish so test exits
    $finish();
end

endmodule

