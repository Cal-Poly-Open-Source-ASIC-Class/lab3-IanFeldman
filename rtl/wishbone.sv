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

/* various signals */
logic pA_ack, pB_ack;
logic pA_stall, pB_stall;
logic pA_turn, pB_turn;
logic pA_ram, pB_ram, pA_en, pB_en;
logic contention, temp_ack_a, temp_ack_b;
logic pA_set_signals, pB_set_signals;
logic [(`A_WIDTH - 1):0] pA_addr_shifted, pB_addr_shifted;
logic [(`A_WIDTH_RAM - 1):0] pA_addr_ram, pB_addr_ram;

/* get ram selection */
assign pA_addr_shifted = {pA_wb_addr_i >> (`A_WIDTH - 1)};
assign pB_addr_shifted = {pB_wb_addr_i >> (`A_WIDTH - 1)};
assign pA_ram = pA_addr_shifted[0];
assign pB_ram = pB_addr_shifted[0];

/* get lower bits of addresses */
assign pA_addr_ram = pA_wb_addr_i[(`A_WIDTH_RAM - 1):0];
assign pB_addr_ram = pA_wb_addr_i[(`A_WIDTH_RAM - 1):0];

assign pA_en = pA_wb_cyc_i & pA_wb_stb_i;
assign pB_en = pB_wb_cyc_i & pB_wb_stb_i;
assign pB_turn = ~pA_turn;
assign contention = pA_en & pB_en & ~(pA_ram ^ pB_ram);
assign pA_set_signals = (pA_en & ~contention) | (contention & pA_turn);
assign pB_set_signals = (pB_en & ~contention) | (contention & pB_turn);

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
    /* defaults */
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
    /* set stall to 0 */
    pA_stall = 1'b0;
    pB_stall = 1'b0;

    /* both ports active */
    if (contention) begin
        /* Port A's turn */
        if (pA_turn == 1'b1) begin
            pA_stall = 1'b0;
            pB_stall = 1'b1;
        end
        /* Port B's turn */
        else begin
            pA_stall = 1'b1;
            pB_stall = 1'b0;
        end
    end
    /* port a */
    if (pA_set_signals) begin
        /* set stall again to suppress latch warning */
        if (contention) begin
            pA_stall = 1'b0;
            pB_stall = 1'b1;
        end
        if (pA_ram == 1'b0) begin
            /* enable ram0 signals */
            we_0 = pA_wb_we_i;
            en_0 = pA_en & ~pA_stall;
            di_0 = pA_wb_data_i;
            a_0  = pA_addr_ram;
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
            en_1 = pA_en & ~pA_stall;
            di_1 = pA_wb_data_i;
            a_1  = pA_addr_ram;
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
    /* port b */
    if (pB_set_signals) begin
        if (contention) begin
            pA_stall = 1'b1;
            pB_stall = 1'b0;
        end
        if (pB_ram == 1'b0) begin
            /* enable ram0 signals */
            we_0 = pB_wb_we_i;
            en_0 = pB_en & ~pB_stall;
            di_0 = pB_wb_data_i;
            a_0  = pB_addr_ram;
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
            en_1 = pB_en & ~pB_stall;
            di_1 = pB_wb_data_i;
            a_1  = pB_addr_ram;
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
end

always_ff@(negedge clk) begin
    /* clock in ack */
    temp_ack_a <= pA_ack;
    temp_ack_b <= pB_ack;
    pA_wb_ack_o <= temp_ack_a;
    pB_wb_ack_o <= temp_ack_b;
    /* clock in stall */
    pA_wb_stall_o <= pA_stall;
    pB_wb_stall_o <= pB_stall;
    /* update turns */
    if (pA_en & pB_en) begin
        pA_turn <= ~pA_turn;
    end
    /* default turn to port a */
    else if (~pA_en & ~pB_en) begin
        pA_turn <= 1'b1;
    end
end

endmodule

