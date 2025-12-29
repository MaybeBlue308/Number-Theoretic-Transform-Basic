
module modular_mul (
    input         clk,
    input         rst,
    input  [11:0] a,       // 12-bit
    input  [11:0] b,       // 12-bit
    output [11:0] result   // 12-bit
);
    //  Stage 1: vedic multiplier (unsigned) 
    // Zero-extend 12 -> 16
    wire [15:0] a16 = {4'b0000, a};
    wire [15:0] b16 = {4'b0000, b};

    wire [31:0] mult_raw;
    vedic_mult_16bit u_vm16 (
        .a  (a16),
        .b  (b16),
        .out(mult_raw)
    );

    reg [31:0] mult_r;
    always @(posedge clk or posedge rst) begin
        if (rst) mult_r <= 32'd0;
        else     mult_r <= mult_raw;
    end

    //  Stage 2: Barrett reduction 
    wire [15:0] r_barrett;
    barrett_reduction u_barrett (   
        .clk (clk),
        .rst (rst),
        .x   (mult_r),
        .r   (r_barrett)
    );

    //  Stage 3: out 12-bit 
    reg [11:0] result_r;
    always @(posedge clk or posedge rst) begin
        if (rst) result_r <= 12'd0;
        else     result_r <= r_barrett[11:0];  
    end

    assign result = result_r;

endmodule
