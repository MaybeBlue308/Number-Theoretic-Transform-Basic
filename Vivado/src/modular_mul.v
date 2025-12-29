module modular_sub (
    input  [11:0] a,
    input  [11:0] b,
    input  [11:0] q,        
    output [11:0] result
);

    wire [15:0] a16 = {4'b0, a};
    wire [15:0] b16 = {4'b0, b};
    wire [15:0] q16 = {4'b0, q};

    // diff = a - b = a + (~b) + 1
    wire [15:0] diff16;
    wire        cout_sub;   
    CLA_16bit cla_sub1 (
        .a  (a16),
        .b  (~b16),
        .cin(1'b1),
        .sum(diff16),
        .cout(cout_sub)
    );

    // diff + q ( a < b)
    wire [15:0] diff_plus_q16;
    wire        cout_addq;
    CLA_16bit cla_add_q (
        .a  (diff16),
        .b  (q16),
        .cin(1'b0),
        .sum(diff_plus_q16),
        .cout(cout_addq)
    );

    wire [15:0] r16 = cout_sub ? diff16 : diff_plus_q16;

    assign result = r16[11:0];

endmodule
