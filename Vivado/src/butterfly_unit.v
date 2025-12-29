// butterfly_unit for both NTT and INTT
// Sel: NTT/ INTT
// input a, b, twf
// output o_up = a+b and o_dn = (b - a)*twf for INTT 
// output o_up = a + b*twf and o_dn = a - b*twf for NTT
// clk, rst
// Q = 3329
// 2 stages
// stage 1: modular_mul for b*twf, modular_sub for b-a, modular_add for a+b
// stage 2: modular_sub for a - b*twf, modular_add for a + b*twf, modular_mul for (b-a)*twf
// outputs: o_up = a+b*twf, o_dn = a - b*twf for NTT
//          o_up = a+b, o_dn = (b-a)*twf for INTT

module butterfly_unit #(
    parameter [11:0] Q = 12'd3329
)(
    input  wire         clk,
    input  wire         rst,
    input  wire [11:0]  a,
    input  wire [11:0]  b,
    input  wire [11:0]  twf,
    input  wire         Sel,     // 0 for NTT, 1 for INTT
    // outputs
    output reg  [11:0]  o_up,
    output reg  [11:0]  o_dn
);
    //  stage 1 
    wire [11:0] b_twf;       // b*twf
    wire [11:0] b_minus_a;   // b - a
    wire [11:0] a_plus_b;    // a + b

    modular_mul mul1 (
        .clk(clk),
        .rst(rst),
        .a(b),
        .b(twf),
        .result(b_twf)
    );

    modular_sub sub1 (
        .a(b),
        .b(a),
        .q(Q),
        .result(b_minus_a)
    );

    modular_add add1 (
        .a(a),
        .b(b),
        .q(Q),
        .result(a_plus_b)
    );

    // align
    reg [11:0] a_d1,   a_d2,   a_d3,   a_d4;
    reg [11:0] sum_d1, sum_d2, sum_d3, sum_d4;
    reg        sel_d1, sel_d2, sel_d3, sel_d4;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            a_d1   <= 12'd0; a_d2   <= 12'd0; a_d3   <= 12'd0; a_d4   <= 12'd0;
            sum_d1 <= 12'd0; sum_d2 <= 12'd0; sum_d3 <= 12'd0; sum_d4 <= 12'd0;
            sel_d1 <= 1'b0;  sel_d2 <= 1'b0;  sel_d3 <= 1'b0;  sel_d4 <= 1'b0;
        end else begin
            a_d1   <= a;
            a_d2   <= a_d1;
            a_d3   <= a_d2;
            a_d4   <= a_d3;

            sum_d1 <= a_plus_b;
            sum_d2 <= sum_d1;
            sum_d3 <= sum_d2;
            sum_d4 <= sum_d3;
            
            sel_d1 <= Sel;          
            sel_d2 <= sel_d1;       
            sel_d3 <= sel_d2;       
            sel_d4 <= sel_d3;
        end
    end

    wire [11:0] a_aligned        = a_d4;     // align w b_twf
    wire [11:0] a_plus_b_aligned = sum_d4;   // align w (b-a)*twf
    wire        sel_aligned      = sel_d4;   

    //  stage 2 
    // (b-a)*twf
    wire [11:0] a_minus_b_twf;
    modular_mul mul2 (
        .clk(clk),
        .rst(rst),
        .a(b_minus_a),
        .b(twf),
        .result(a_minus_b_twf)
    );

    // a - b*twf
    wire [11:0] a_minus_btwf;
    modular_sub sub2 (
        .a(a_aligned),
        .b(b_twf),
        .q(Q),
        .result(a_minus_btwf)
    );

    // a + b*twf
    wire [11:0] a_plus_btwf;
    modular_add add2 (
        .a(a_aligned),
        .b(b_twf),
        .q(Q),
        .result(a_plus_btwf)
    );

    //  outputs 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            o_up <= 12'd0;
            o_dn <= 12'd0;
        end else begin
            if (sel_aligned == 1'b0) begin // NTT
                o_up <= a_plus_btwf;      // a + b*twf
                o_dn <= a_minus_btwf;     // a - b*twf
            end else begin // INTT
                o_up <= a_plus_b_aligned; // a + b
                o_dn <= a_minus_b_twf;    // (b - a)*twf
            end
        end
    end
endmodule
