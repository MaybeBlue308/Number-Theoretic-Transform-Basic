module ntt_bram_wrapper (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,
    input  wire        mode,    // 0 = NTT, 1 = INTT
    output wire        done
);

    //  BRAM 
    wire        bram_we_a, bram_we_b;
    wire [7:0]  bram_addr_a, bram_addr_b;
    wire [15:0] bram_din_a, bram_din_b;
    wire [15:0] bram_dout_a, bram_dout_b;

    bram_256_16_true_dual u_bram (
        .clk(clk),
        .we_a(bram_we_a),
        .addr_a(bram_addr_a),
        .din_a(bram_din_a),
        .dout_a(bram_dout_a),
        .we_b(bram_we_b),
        .addr_b(bram_addr_b),
        .din_b(bram_din_b),
        .dout_b(bram_dout_b)
    );

    // Core
    ntt_intt_top_reg u_top (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .done(done),
        //  BRAM port A: FSM copy 
        .bram_addr_a(bram_addr_a),
        .bram_dout_a(bram_dout_a),
        .bram_we_a(bram_we_a),
        .bram_din_a(bram_din_a),
        // BRAM port B: WB  
        .bram_addr_b(bram_addr_b),
        .bram_dout_b(bram_dout_b),
        .bram_we_b(bram_we_b),
        .bram_din_b(bram_din_b)
    );

endmodule
