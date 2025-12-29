// ============================================================================
// NTT/INTT Execute (EX) Stage with selectable butterfly
// - Feeds a,b,twf,Sel to butterfly_unit (NTT if Sel=0, INTT if Sel=1)
// - Pipelines valid/last/done and addresses by BU_LAT to align with outputs
// - Emits o_e pulse, aligned addresses, and butterfly results
// ============================================================================
module EX #(
  parameter [11:0] Q       = 12'd3329,
  parameter integer BU_LAT = 5              // latency from butterfly inputs to outputs
)(
  input  wire        clk,
  input  wire        rst,

  // From VA stage (already aligned bundle)
  input  wire        i_v,              // valid
  input  wire        i_last_v,         // last stage flag
  input  wire        i_done_v,         // done pulse (per transform)
  input  wire [7:0]  i_addr_up_v,
  input  wire [7:0]  i_addr_dn_v,
  input  wire [11:0] i_bu_in_up_v,     // a
  input  wire [11:0] i_bu_in_dn_v,     // b
  input  wire [11:0] i_zeta_val_v,     // twiddle
  input  wire        i_sel_v,          // 0: NTT, 1: INTT (pipelined from AD/VA)

  // To next stage (WR)
  output reg         o_e,              // valid pulse aligned with results
  output reg         o_last_e,         // last stage flag (aligned)
  output reg         o_done_e,         // done pulse (aligned)
  output reg  [7:0]  addr_up_e,
  output reg  [7:0]  addr_dn_e,
  output reg  [11:0] bu_out_up_e,      // NTT: a + b*w, INTT: a + b
  output reg  [11:0] bu_out_dn_e       // NTT: a - b*w, INTT: (b - a)*w
);
  // Butterfly (sequential, does NTT or INTT based on Sel)
  wire [11:0] bu_up_w;
  wire [11:0] bu_dn_w;

  butterfly_unit #(.Q(Q)) u_bu (
    .clk (clk),
    .rst (rst),
    .a   (i_bu_in_up_v),
    .b   (i_bu_in_dn_v),
    .twf (i_zeta_val_v),
    .Sel (i_sel_v),        // 0: NTT, 1: INTT
    .o_up(bu_up_w),
    .o_dn(bu_dn_w)
  );
  // Control/address pipeline to align with butterfly latency
  integer k;
  reg [BU_LAT-1:0] v_pipe;
  reg [BU_LAT-1:0] last_pipe;
  reg [BU_LAT-1:0] done_pipe;
  reg [7:0] addr_up_pipe [0:BU_LAT-1];
  reg [7:0] addr_dn_pipe [0:BU_LAT-1];

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      v_pipe   <= {BU_LAT{1'b0}};
      last_pipe<= {BU_LAT{1'b0}};
      done_pipe<= {BU_LAT{1'b0}};
      for (k=0; k<BU_LAT; k=k+1) begin
        addr_up_pipe[k] <= 8'd0;
        addr_dn_pipe[k] <= 8'd0;
      end
    end else begin
      // shift valid/flags
      v_pipe    <= {v_pipe[BU_LAT-2:0],    i_v};
      last_pipe <= {last_pipe[BU_LAT-2:0], i_last_v};
      done_pipe <= {done_pipe[BU_LAT-2:0], i_done_v};

      // shift addresses (data carried alongside; gated by v_pipe at output)
      addr_up_pipe[0] <= i_addr_up_v;
      addr_dn_pipe[0] <= i_addr_dn_v;
      for (k=1; k<BU_LAT; k=k+1) begin
        addr_up_pipe[k] <= addr_up_pipe[k-1];
        addr_dn_pipe[k] <= addr_dn_pipe[k-1];
      end
    end
  end

  wire vld_aligned   = v_pipe   [BU_LAT-1];
  wire last_aligned  = last_pipe[BU_LAT-1];
  wire done_aligned  = done_pipe[BU_LAT-1];
  wire [7:0] addr_up_aligned = addr_up_pipe[BU_LAT-1];
  wire [7:0] addr_dn_aligned = addr_dn_pipe[BU_LAT-1];

  // Register outputs when valid
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      o_e         <= 1'b0;
      o_last_e    <= 1'b0;
      o_done_e    <= 1'b0;
      addr_up_e   <= 8'd0;
      addr_dn_e   <= 8'd0;
      bu_out_up_e <= 12'd0;
      bu_out_dn_e <= 12'd0;
    end else begin
      // default deassert pulses
      o_e      <= 1'b0;
      o_last_e <= 1'b0;
      o_done_e <= 1'b0;

      if (vld_aligned) begin
        bu_out_up_e <= bu_up_w;
        bu_out_dn_e <= bu_dn_w;
        addr_up_e   <= addr_up_aligned;
        addr_dn_e   <= addr_dn_aligned;
        o_e      <= 1'b1;
        o_last_e <= last_aligned;
        o_done_e <= done_aligned;
      end
    end
  end

endmodule
