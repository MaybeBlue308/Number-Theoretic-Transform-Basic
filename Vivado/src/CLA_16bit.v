module CLA_16bit(a,b,cin,sum,cout);

//declaring input and output variables
input [15:0]a,b;
input cin;
output [15:0]sum;
output cout;

//wire for intermediate carry
wire c_int;

CLA_8bit cla1(a[7:0],b[7:0],cin,sum[7:0],c_int);
CLA_8bit cla2(a[15:8],b[15:8],c_int,sum[15:8],cout);

endmodule
