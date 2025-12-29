
/*
module bram_256_16_true_dual (
    // Port A
    input  wire        clk_a,    // clock for port A
    input  wire        we_a,     // write enable for port A
    input  wire [7:0]  addr_a,   // address for port A
    input  wire [15:0] din_a,    // data in for port A
    output reg  [15:0] dout_a,   // data out for port A

    // Port B
    input  wire        clk_b,    // clock for port B
    input  wire        we_b,     // write enable for port B
    input  wire [7:0]  addr_b,   // address for port B
    input  wire [15:0] din_b,    // data in for port B
    output reg  [15:0] dout_b    // data out for port B
);

    (* ram_style = "block" *) reg [15:0] blockram [0:255];

    // Port A: sync read/write, WRITE-FIRST mode
    always @(posedge clk_a) begin
        if (we_a) begin
            blockram[addr_a] <= din_a;
            dout_a           <= din_a;          
        end else begin
            dout_a           <= blockram[addr_a];
        end
    end

    // Port B: sync read/write, WRITE-FIRST mode
    always @(posedge clk_b) begin
        if (we_b) begin
            blockram[addr_b] <= din_b;
            dout_b           <= din_b;          
        end else begin
            dout_b           <= blockram[addr_b];
        end
    end

endmodule
*/

// True-dual-port BRAM 16-bit x90 256 (sync read)
module  bram_256_16_true_dual #(
    parameter INIT_FILE = ""
)(
    input             clk,
    // Port A
    input             we_a,
    input      [7:0]  addr_a,
    input      [15:0] din_a,
    output reg [15:0] dout_a,
    // Port B
    input             we_b,
    input      [7:0]  addr_b,
    input      [15:0] din_b,
    output reg [15:0] dout_b
);
    (* ram_style="block" *) reg [15:0] blockram [0:255];


    initial begin
      if (INIT_FILE != "") begin
        $display("Loading memory init file %s", INIT_FILE);
        $readmemh(INIT_FILE, blockram);
      end
    end
    
    always @(posedge clk) begin
        if (we_a) blockram[addr_a] <= din_a;
        dout_a <= blockram[addr_a];
    end

    always @(posedge clk) begin
        if (we_b) blockram[addr_b] <= din_b;
        dout_b <= blockram[addr_b];
    end
endmodule
