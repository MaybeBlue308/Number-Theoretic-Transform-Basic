// -----------------------------------------------------------------------------
// AD: (pipeline) addresses, zeta index, and Sel from addrgen
// - Accepts level i_start, generates a 1-cycle start pulse
// - Selects NTT/INTT via Sel, passes Sel through pipeline
// - When addrgen is active, outputs addr_up/dn/zeta and Sel_aligned with valid
// -----------------------------------------------------------------------------
module AD (
  input  wire        clk,
  input  wire        rst,
  input  wire        i_start,       // start level from controller
  input  wire        Sel,           // 0 = NTT, 1 = INTT

  output reg  [7:0]  addr_up_a,     // latched addr_up
  output reg  [7:0]  addr_dn_a,     // latched addr_dn
  output reg  [6:0]  addr_zeta_a,   // latched zeta index

  output reg         Sel_a,         // Sel pipelined (aligned with outputs)
  output reg         o_a,           // valid pulse
  output reg         o_last_a,      // last stage
  output reg         o_done_a       // done
);
  wire [7:0] ag_addr_up, ag_addr_dn;
  wire [6:0] ag_zeta_idx;
  wire       ag_done, ag_last_stage, ag_active;
  reg i_start_d;
  wire start_pulse = i_start & ~i_start_d;

  always @(posedge clk or posedge rst) begin
    if (rst) i_start_d <= 1'b0;
    else     i_start_d <= i_start;
  end

  addrgen u_addrgen (
    .clk       (clk),
    .rst       (rst),
    .i_start   (start_pulse),
    .Sel       (Sel),
    .addr_up   (ag_addr_up),
    .addr_dn   (ag_addr_dn),
    .zeta_idx  (ag_zeta_idx),
    .done      (ag_done),
    .last_stage(ag_last_stage),
    .active    (ag_active)
  );

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      addr_up_a   <= 8'd0;
      addr_dn_a   <= 8'd0;
      addr_zeta_a <= 7'd0;
      Sel_a       <= 1'b0;
      o_a         <= 1'b0;
      o_last_a    <= 1'b0;
      o_done_a    <= 1'b0;
    end else begin
      o_a      <= 1'b0;
      o_last_a <= 1'b0;
      o_done_a <= 1'b0;

      if (ag_active) begin
        addr_up_a   <= ag_addr_up;
        addr_dn_a   <= ag_addr_dn;
        addr_zeta_a <= ag_zeta_idx;
        Sel_a       <= Sel;          
        o_a         <= 1'b1;
        o_last_a    <= ag_last_stage;
        o_done_a    <= ag_done;
      end
    end
  end

endmodule
