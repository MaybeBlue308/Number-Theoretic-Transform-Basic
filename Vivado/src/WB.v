module WB_dualport #(
    parameter [11:0] INV128 = 12'd3303,
    parameter integer MUL_LATENCY = 4 
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        i_e,
    input  wire        i_last_e,
    input  wire        i_sel,          // 0 = NTT, 1 = INTT
    input  wire [7:0]  i_addr_up_e,
    input  wire [7:0]  i_addr_dn_e,
    input  wire [11:0] i_bu_out_up_e,
    input  wire [11:0] i_bu_out_dn_e,
    //  Regfile 
    output reg         rf_we_a,
    output reg [7:0]   rf_addr_a,
    output reg [11:0]  rf_din_a,
    output reg         rf_we_b,
    output reg [7:0]   rf_addr_b,
    output reg [11:0]  rf_din_b,
    //  BRAM 
    output reg         bram_we_a,
    output reg [7:0]   bram_addr_a,
    output reg [15:0]  bram_din_a,
    output reg         bram_we_b,
    output reg [7:0]   bram_addr_b,
    output reg [15:0]  bram_din_b
);

    //  Modular mul cho INTT last stage 
    wire [11:0] scaled_up, scaled_dn;
    modular_mul mul_up (
        .clk(clk),
        .rst(rst),
        .a(i_bu_out_up_e),
        .b(INV128),
        .result(scaled_up)
    );
    modular_mul mul_dn (
        .clk(clk),
        .rst(rst),
        .a(i_bu_out_dn_e),
        .b(INV128),
        .result(scaled_dn)
    );

    //  Delay pipeline cho control + addr 
    reg [MUL_LATENCY-1:0] v_pipe, last_pipe, sel_pipe;
    reg [7:0] addr_up_pipe [0:MUL_LATENCY-1];
    reg [7:0] addr_dn_pipe [0:MUL_LATENCY-1];

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            v_pipe    <= {MUL_LATENCY{1'b0}};
            last_pipe <= {MUL_LATENCY{1'b0}};
            sel_pipe  <= {MUL_LATENCY{1'b0}};
            for (i=0; i<MUL_LATENCY; i=i+1) begin
                addr_up_pipe[i] <= 8'd0;
                addr_dn_pipe[i] <= 8'd0;
            end
        end else begin
            v_pipe    <= {v_pipe[MUL_LATENCY-2:0], i_e};
            last_pipe <= {last_pipe[MUL_LATENCY-2:0], i_last_e};
            sel_pipe  <= {sel_pipe[MUL_LATENCY-2:0], i_sel};
            addr_up_pipe[0] <= i_addr_up_e;
            addr_dn_pipe[0] <= i_addr_dn_e;
            for (i=1; i<MUL_LATENCY; i=i+1) begin
                addr_up_pipe[i] <= addr_up_pipe[i-1];
                addr_dn_pipe[i] <= addr_dn_pipe[i-1];
            end
        end
    end

    //  Writeback 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rf_we_a     <= 0;
            rf_we_b     <= 0;
            rf_addr_a   <= 0;
            rf_addr_b   <= 0;
            rf_din_a    <= 0;
            rf_din_b    <= 0;
            bram_we_a   <= 0;
            bram_we_b   <= 0;
            bram_addr_a <= 0;
            bram_addr_b <= 0;
            bram_din_a  <= 0;
            bram_din_b  <= 0;
        end else begin
            rf_we_a   <= 0;
            rf_we_b   <= 0;
            bram_we_a <= 0;
            bram_we_b <= 0;
            //  NTT path 
            if (i_e && !i_sel) begin
                // write to RF
                rf_we_a   <= 1;
                rf_we_b   <= 1;
                rf_addr_a <= i_addr_up_e;
                rf_addr_b <= i_addr_dn_e;
                rf_din_a  <= i_bu_out_up_e;
                rf_din_b  <= i_bu_out_dn_e;
                // last stage write to BRAM (dual-port)
                if (i_last_e) begin
                    bram_we_a   <= 1;
                    bram_we_b   <= 1;
                    bram_addr_a <= i_addr_up_e;
                    bram_addr_b <= i_addr_dn_e;
                    bram_din_a  <= {4'd0, i_bu_out_up_e};
                    bram_din_b  <= {4'd0, i_bu_out_dn_e};
                end
            end

            // INTT path 
            // last stage: delay theo MUL_LATENCY
            else if (v_pipe[MUL_LATENCY-1] && last_pipe[MUL_LATENCY-1] && sel_pipe[MUL_LATENCY-1]) begin
                rf_we_a   <= 1;
                rf_we_b   <= 1;
                rf_addr_a <= addr_up_pipe[MUL_LATENCY-1];
                rf_addr_b <= addr_dn_pipe[MUL_LATENCY-1];
                rf_din_a  <= scaled_up;
                rf_din_b  <= scaled_dn;
                // write to BRAM (dual-port)
                bram_we_a   <= 1;
                bram_we_b   <= 1;
                bram_addr_a <= addr_up_pipe[MUL_LATENCY-1];
                bram_addr_b <= addr_dn_pipe[MUL_LATENCY-1];
                bram_din_a  <= {4'd0, scaled_up};
                bram_din_b  <= {4'd0, scaled_dn};
            end
            // write to RF
            else if (i_e && i_sel && !i_last_e) begin
                rf_we_a   <= 1;
                rf_we_b   <= 1;
                rf_addr_a <= i_addr_up_e;
                rf_addr_b <= i_addr_dn_e;
                rf_din_a  <= i_bu_out_up_e;
                rf_din_b  <= i_bu_out_dn_e;
            end
        end
    end

endmodule
