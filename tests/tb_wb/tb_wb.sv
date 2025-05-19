`timescale 1ns/1ps
`define A_WIDTH 9

module tb_wb;

// Declare test variables
logic clk;
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
    $dumpvars(0);
end

initial begin
    // Test Goes Here
    clk = 0;

    #CLK_PERIOD

    /* try reading from A */
    pA_wb_cyc_i = 1'b1;
    pA_wb_stb_i = 1'b1;
    pA_wb_we_i = 4'b0;
    pA_wb_addr_i = `A_WIDTH'b0;

    #CLK_PERIOD
    pA_wb_cyc_i = 1'b0;

    #1000000

    // Make sure to call finish so test exits
    $finish();
end

endmodule

