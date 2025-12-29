module VA (
  input  wire        clk,
  input  wire        rst,
  // From AD (already 1-cycle aligned bundle)
  input  wire        i_a,             // valid from AD
  input  wire        i_last_a,        // last-stage flag
  input  wire        i_done_a,        // done pulse
  input  wire [7:0]  i_addr_up_a,     // dRAM address (up)
  input  wire [7:0]  i_addr_dn_a,     // dRAM address (dn)
  input  wire [6:0]  i_addr_zeta_a,   // zeta index
  input  wire        i_sel_a,         // Sel aligned from AD (0: NTT, 1: INTT)
  // To distributedRAM (read addresses)
  output wire [7:0]  o_dRAM_addr_up,
  output wire [7:0]  o_dRAM_addr_dn,
  // From RF (combinational read data, NO latency)
  input  wire [11:0] i_dRAM_dout_up,
  input  wire [11:0] i_dRAM_dout_dn,
  // To MUL stage
  output reg         o_v,             // valid
  output reg         o_last_v,        // last-stage flag
  output reg         o_done_v,        // done pulse
  output reg         o_sel_v,         // Sel pipelined to next stage
  output reg  [7:0]  addr_up_v,
  output reg  [7:0]  addr_dn_v,
  output reg  [11:0] bu_in_up_v,
  output reg  [11:0] bu_in_dn_v,
  output reg  [11:0] zeta_val_v
);
  // Drive dRAM addresses in S0 (data available immediately due to combinational read)
  assign o_dRAM_addr_up = i_addr_up_a;
  assign o_dRAM_addr_dn = i_addr_dn_a;
  
  // Twiddle ROM is synchronous (1-cycle latency)
  wire [11:0] zeta_w;
  rom_zeta u_rom_zeta (
    //.clk  (clk),
    .addr (i_addr_zeta_a),
    .data (zeta_w)               // valid in S1
  );
  
  // ---------------- S1: capture everything for timing synchronization ----------------
  reg        s1_valid, s1_last, s1_done, s1_sel;
  reg [7:0]  s1_addr_up, s1_addr_dn;
  reg [11:0] s1_dRAM_up, s1_dRAM_dn;
  reg [11:0] s1_zeta;
  
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      s1_valid   <= 1'b0;
      s1_last    <= 1'b0;
      s1_done    <= 1'b0;
      s1_sel     <= 1'b0;
      s1_addr_up <= 8'd0;
      s1_addr_dn <= 8'd0;
      s1_dRAM_up <= 12'd0;
      s1_dRAM_dn <= 12'd0;
      s1_zeta    <= 12'd0;
    end else begin
      // Metadata (arrives in S0, latch to S1)
      s1_valid   <= i_a;
      s1_last    <= i_last_a;
      s1_done    <= i_done_a;
      s1_sel     <= i_sel_a;
      s1_addr_up <= i_addr_up_a;
      s1_addr_dn <= i_addr_dn_a;
      // Data synchronization: dRAM data (immediate) + ROM data (1 cycle delay)
      s1_dRAM_up <= i_dRAM_dout_up;  // dRAM data available immediately in S0, latched for sync
      s1_dRAM_dn <= i_dRAM_dout_dn;
      s1_zeta    <= zeta_w;           // ROM data valid now (after 1 cycle from S0)
    end
  end
  
  // ---------------- S2: output to next stage ----------------
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      o_v        <= 1'b0;
      o_last_v   <= 1'b0;
      o_done_v   <= 1'b0;
      o_sel_v    <= 1'b0;
      addr_up_v  <= 8'd0;
      addr_dn_v  <= 8'd0;
      bu_in_up_v <= 12'd0;
      bu_in_dn_v <= 12'd0;
      zeta_val_v <= 12'd0;
    end else begin
      o_v        <= s1_valid;
      o_last_v   <= s1_last;
      o_done_v   <= s1_done;
      o_sel_v    <= s1_sel;
      addr_up_v  <= s1_addr_up;
      addr_dn_v  <= s1_addr_dn;
      bu_in_up_v <= s1_dRAM_up;      // use S1-registered dRAM data
      bu_in_dn_v <= s1_dRAM_dn;
      zeta_val_v <= s1_zeta;
    end
  end
endmodule