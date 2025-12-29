module CLA_64bit(
//declaring input and output variables
    input  [63:0] a,
    input  [63:0] b,
    input         cin,
    output [63:0] sum,
    output        cout
);
   //wire for intermediate carry
    wire c_int;

    CLA_32bit cla1(a[31:0],  b[31:0],  cin,  sum[31:0],  c_int);
    CLA_32bit cla2(a[63:32], b[63:32], c_int, sum[63:32], cout);
endmodule