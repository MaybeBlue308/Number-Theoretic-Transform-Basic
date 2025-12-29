module modular_add (
    input  [11:0] a,
    input  [11:0] b,
    input  [11:0] q,       
    output [11:0] result
);
    // Zero-extend 12 -> 16 
    wire [15:0] a16 = {4'b0, a};
    wire [15:0] b16 = {4'b0, b};
    wire [15:0] q16 = {4'b0, q};

    // sum = a + b
    wire [15:0] sum16;
    wire        cout_sum;
    CLA_16bit cla_add (
        .a  (a16),
        .b  (b16),
        .cin(1'b0),
        .sum(sum16),
        .cout(cout_sum)
    );

    // diff = sum - q  (two's complement: sum + ~q + 1)
    wire [15:0] diff16;
    wire        cout_sub;  
    CLA_16bit cla_sub (
        .a  (sum16),
        .b  (~q16),
        .cin(1'b1),
        .sum(diff16),
        .cout(cout_sub)
    );

    // if sum >= q => out diff, else out sum
    wire [15:0] r16 = cout_sub ? diff16 : sum16;

    assign result = r16[11:0];

endmodule
