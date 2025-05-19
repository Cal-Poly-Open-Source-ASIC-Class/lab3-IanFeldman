`timescale 1ns/1ps
`define A_WIDTH 9
`define A_WIDTH_RAM 8

module wishbone
(
    input clk,
    input pA_wb_cyc_i, pA_wb_stb_i,
    input pB_wb_cyc_i, pB_wb_stb_i,
    input [3:0] pA_wb_we_i, pB_wb_we_i,
    input [(`A_WIDTH - 1):0] pA_wb_addr_i, pB_wb_addr_i,
    input [31:0] pA_wb_data_i, pB_wb_data_i,
    output logic pA_wb_ack_o, pA_wb_stall_o,
    output logic pB_wb_ack_o, pB_wb_stall_o,
    output logic [31:0] pA_wb_data_o, pB_wb_data_o
);

/* ram signals */
logic [3:0] we_0, we_1;
logic en_0, en_1;
logic [31:0] di_0, di_1, do_0, do_1;
logic [(`A_WIDTH_RAM - 1):0] a_0, a_1; /* 8 bits */

/* temp signals */
logic pA_ack, pB_ack;

logic pA_ram, pB_ram, pA_en, pB_en;
assign pA_ram = {pA_wb_addr_i >> (`A_WIDTH - 1)}[0];
assign pB_ram = {pB_wb_addr_i >> (`A_WIDTH - 1)}[0];
assign pA_en = pA_wb_cyc_i & pA_wb_stb_i;
assign pB_en = pB_wb_cyc_i & pB_wb_stb_i;

DFFRAM256x32 ram_0
(
    .CLK(clk),
    .WE0(we_0),
    .EN0(en_0),
    .Di0(di_0),
    .Do0(do_0),
    .A0(a_0)
);

DFFRAM256x32 ram_1
(
    .CLK(clk),
    .WE0(we_1),
    .EN0(en_1),
    .Di0(di_1),
    .Do0(do_1),
    .A0(a_1)
);

always_comb begin
    /* both ports active */
    if (pA_en & pB_en) begin
        /* TEMP */
        we_0 = 4'b0;
        en_0 = 1'b0;
        di_0 = 32'b0;
        a_0  = `A_WIDTH_RAM'b0;
        we_1 = 4'b0;
        en_1 = 1'b0;
        di_1 = 32'b0;
        a_1  = `A_WIDTH_RAM'b0;
        pA_ack = 1'b0;
        pB_ack = 1'b0;
        pA_wb_data_o = 32'b0;
        pB_wb_data_o = 32'b0;
    end
    /* only port a */
    else if (pA_en) begin
        if (pA_ram == 1'b0) begin
            /* enable ram0 signals */
            we_0 = pA_wb_we_i;
            en_0 = pA_en;
            di_0 = pA_wb_data_i;
            a_0  = pA_wb_addr_i[(`A_WIDTH_RAM - 1):0];
            pA_wb_data_o = do_0;
            /* set ram1 signals low */
            we_1 = 4'b0;
            en_1 = 1'b0;
            di_1 = 32'b0;
            a_1  = `A_WIDTH_RAM'b0;
        end
        else begin
            /* enable ram1 signals */
            we_1 = pA_wb_we_i;
            en_1 = pA_en;
            di_1 = pA_wb_data_i;
            a_1  = pA_wb_addr_i[(`A_WIDTH_RAM - 1):0];
            pA_wb_data_o = do_1;
            /* set ram0 signals low */
            we_0 = 4'b0;
            en_0 = 1'b0;
            di_0 = 32'b0;
            a_0  = `A_WIDTH_RAM'b0;
        end
        /* set ack high */
        pA_ack = 1'b1;
        pB_ack = 1'b0;
        pB_wb_data_o = 32'b0;
    end
    /* only port b */
    else if (pB_en) begin
        if (pB_ram == 1'b0) begin
            /* enable ram0 signals */
            we_0 = pB_wb_we_i;
            en_0 = pB_en;
            di_0 = pB_wb_data_i;
            a_0  = pB_wb_addr_i[(`A_WIDTH_RAM - 1):0];
            pB_wb_data_o = do_0;
            /* set ram1 signals low */
            we_1 = 4'b0;
            en_1 = 1'b0;
            di_1 = 32'b0;
            a_1  = `A_WIDTH_RAM'b0;
        end
        else begin
            /* enable ram1 signals */
            we_1 = pB_wb_we_i;
            en_1 = pB_en;
            di_1 = pB_wb_data_i;
            a_1  = pB_wb_addr_i[(`A_WIDTH_RAM - 1):0];
            pB_wb_data_o = do_1;
            /* set ram0 signals low */
            we_0 = 4'b0;
            en_0 = 1'b0;
            di_0 = 32'b0;
            a_0  = `A_WIDTH_RAM'b0;
        end
        /* set ack high */
        pB_ack = 1'b1;
        pA_ack = 1'b0;
        pA_wb_data_o = 32'b0;
    end
    else begin
        /* set ram0 signals low */
        we_0 = 4'b0;
        en_0 = 1'b0;
        di_0 = 32'b0;
        a_0  = `A_WIDTH_RAM'b0;
        /* set ram1 signals low */
        we_1 = 4'b0;
        en_1 = 1'b0;
        di_1 = 32'b0;
        a_1  = `A_WIDTH_RAM'b0;
        /* set acks low */
        pA_ack = 1'b0;
        pB_ack = 1'b0;
        /* set data out to zero */
        pA_wb_data_o = 32'b0;
        pB_wb_data_o = 32'b0;
    end
end

always_ff@(negedge clk) begin
    /* enable ack for one clock */
    if (pA_ack == 1'b1)
        pA_wb_ack_o <= 1'b1;
    if (pB_ack == 1'b1)
        pB_wb_ack_o <= 1'b1;
    if (pA_wb_ack_o == 1'b1)
        pA_wb_ack_o <= 1'b0;
    if (pB_wb_ack_o == 1'b1)
        pB_wb_ack_o <= 1'b0;
end

endmodule

