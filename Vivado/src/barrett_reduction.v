// -----------------------------------------------------------------------------
// Barrett reduction modulo q = 3329 using k = 24 
// r = x mod q, with:
//   M = floor(2^24 / q) = 5039
//   t = floor( (x * M) / 2^24 )
//   r0 = x - t*q   (guaranteed 0 <= r0 < 2q if x < q^2)
//   r  = (r0 >= q) ? (r0 - q) : r0
//
// Notes:
// - Assumes x is typically the product of two values already reduced mod q
//   (so x < q^2). Under this condition, a single conditional subtraction is enough.
// - Both multipliers are unsigned.
// - Using vedic_mult_32bit (32x32 -> 64), zero-extend M, Q, t to 32 bits.
// -----------------------------------------------------------------------------
/*
module barrett_reduction (
    input  [31:0] x,        // product of 16x16 multiplier (unsigned)
    output [15:0] r         // x reduced modulo q
);
    // (0) Constants
    localparam [15:0] Q = 16'd3329; // modulus q (Kyber)
    localparam [15:0] M = 16'd5039; // floor(2^24 / q)

    // (1) x*M -> 64-bit, then t = floor((x*M)>>24)
    wire [63:0] xM;
    // positional mapping to match your style
    vedic_mult_32bit u_xM (x, {16'b0, M}, xM);

    // Use [47:24] to avoid width warnings (upper [63:48] are zeros)
    wire [23:0] t = xM[47:24];

    // (2) t*Q -> 64-bit
    wire [63:0] tQ;
    vedic_mult_32bit u_tQ ({8'b0, t}, {16'b0, Q}, tQ);

    // (3) r0_64 = x64 - tQ using CLA_64bit (two's complement: x64 + ~tQ + 1)
    wire [63:0] x64  = {32'b0, x};
    wire [63:0] tQ_n = ~tQ;
    wire [63:0] r0_64;
    wire        sub64_cout; // =1 => no borrow (x64 >= tQ)

    CLA_64bit cla_sub_64 (x64, tQ_n, 1'b1, r0_64, sub64_cout);

    // (4) Keep only lower 16 bits (r0 < 2q < 2^13 when x < q^2)
    wire [15:0] r0 = r0_64[15:0];

    // (5) Final correction with CLA_16bit:
    //     diff = r0 - Q = r0 + (~Q) + 1
    wire [15:0] diff16;
    wire        ge_no_borrow; // =1 => r0 >= Q

    CLA_16bit cla_final (r0, ~Q, 1'b1, diff16, ge_no_borrow);

    wire [15:0] r1 = ge_no_borrow ? diff16 : r0;

    // (6) Output
    assign r = r1;
endmodule
*/

// -----------------------------------------------------------------------------
// Barrett reduction modulo q = 3329 (k = 24) - only add registers at multipliers
// Latency: 2 clock cycles from x to r
// -----------------------------------------------------------------------------
module barrett_reduction (
    input         clk,
    input         rst,        // synchronous reset
    input  [31:0] x,          // product of 16x16 multiplier (unsigned)
    output [15:0] r           // x reduced modulo q
);
    // (0) Constants
    localparam [15:0] Q = 16'd3329; // modulus q (Kyber)
    localparam [15:0] M = 16'd5039; // floor(2^24 / q)

    // S1: x*M (combinational) -> register xM_r

    wire [63:0] xM_w;
    vedic_mult_32bit u_xM (.a(x), .b({16'b0, M}), .out(xM_w));

    reg  [63:0] xM_r;   // reg for x*M
    reg  [31:0] x_r1;   // pipeline x alongside for alignment
    always @(posedge clk) begin
        if (rst) begin
            xM_r <= 64'd0;
            x_r1 <= 32'd0;
        end else begin
            xM_r <= xM_w;
            x_r1 <= x;
        end
    end

    // t = floor((x*M)>>24) from registered xM_r
    wire [23:0] t_w = xM_r[47:24];

    // S2: t*Q (combinational) -> register tQ_r
    wire [63:0] tQ_w;
    vedic_mult_32bit u_tQ (.a({8'b0, t_w}), .b({16'b0, Q}), .out(tQ_w));

    reg  [63:0] tQ_r;   // reg for t*Q
    reg  [31:0] x_r2;   // pipeline x one more stage
    always @(posedge clk) begin
        if (rst) begin
            tQ_r <= 64'd0;
            x_r2 <= 32'd0;
        end else begin
            tQ_r <= tQ_w;
            x_r2 <= x_r1;
        end
    end
    // S3: (combinational) r0 = x - t*Q, then one conditional subtract by Q
    wire [63:0] x64  = {32'b0, x_r2};
    wire [63:0] r0_64;
    wire        sub64_cout; // unused; indicates no borrow
    // r0_64 = x64 - tQ_r  via two's complement add
    CLA_64bit cla_sub_64 (
        .a   (x64),
        .b   (~tQ_r),
        .cin (1'b1),
        .sum (r0_64),
        .cout(sub64_cout)
    );
    // Keep only lower 16 bits (r0 < 2q when x < q^2)
    wire [15:0] r0_16 = r0_64[15:0];
    // Final correction: if r0 >= Q then r0 - Q else r0
    wire [15:0] diff16;
    wire        ge_no_borrow;

    CLA_16bit cla_final (
        .a   (r0_16),
        .b   (~Q),
        .cin (1'b1),
        .sum (diff16),
        .cout(ge_no_borrow)
    );
    assign r = ge_no_borrow ? diff16 : r0_16;
endmodule
