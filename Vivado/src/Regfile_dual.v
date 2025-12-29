module Regfile_dual (
    input  wire        clk,        
    // Port A
    input  wire        we,       
    input  wire [7:0]  addrw_a,
    input  wire [7:0]  addrr_a,     
    input  wire [11:0] din_a,      
    output wire  [11:0] dout_a,     
    // Port B
   
    input  wire [7:0]  addrw_b,
    input  wire [7:0]  addrr_b,     
    input  wire [11:0] din_b,      
    output wire  [11:0] dout_b      
);
    (* ram_style = "registers" *) reg [11:0] mem [0:255];
/* 
    initial begin
        $readmemh("E:/VDT2025Vivado/INTT/INTT.srcs/sim_1/new/input_intt_test.hex", mem);
    end
*/
    always @(posedge clk) begin
        if (we) begin
        mem[addrw_a] <= din_a;
        mem[addrw_b] <= din_b;
        end
    end
       assign dout_a = mem[addrr_a];
       assign dout_b = mem[addrr_b];
endmodule
