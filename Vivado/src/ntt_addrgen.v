module ntt_addrgen256 (
  input  wire        clk,
  input  wire        rst,
  input  wire        i_start,
  output reg  [7:0]  o_addr_up,
  output reg  [7:0]  o_addr_dn,
  output reg  [6:0]  o_zeta_idx,
  output reg         o_done,
  output reg         o_last_stage,
  output reg         o_ntt_active
);

  reg [7:0] len, start, j;
  reg [6:0] i7; // zeta index (1..127)
  wire [8:0] stride     = {len,1'b0}; // 2*len
  wire [7:0] j_plus_len = j + len;

  reg warmup;

  (* fsm_encoding = "sequential" *)
  reg [1:0] st;
  localparam IDLE = 2'd0,
             RUN  = 2'd1,
             DONE = 2'd2;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      st           <= IDLE;
      o_done       <= 1'b0;
      o_last_stage <= 1'b0;
      o_ntt_active <= 1'b0;
      len          <= 8'd0;
      start        <= 8'd0;
      j            <= 8'd0;
      i7           <= 7'd1;
      o_addr_up    <= 8'd0;
      o_addr_dn    <= 8'd0;
      o_zeta_idx   <= 7'd0;
      warmup       <= 1'b0;
    end else begin
      case (st)
        IDLE: begin
          o_done       <= 1'b0;
          o_last_stage <= 1'b0;
          if (i_start) begin
            len          <= 8'd128;
            start        <= 8'd0;
            j            <= 8'd0;
            i7           <= 7'd1;
            o_ntt_active <= 1'b0;   
            warmup       <= 1'b1;   
            st           <= RUN;
          end
        end

        RUN: begin
          o_zeta_idx   <= i7;
          o_last_stage <= (len == 8'd2);

          if (warmup) begin
            o_ntt_active <= 1'b0;
            warmup       <= 1'b0; 
          end else begin
            o_ntt_active <= 1'b1;
            o_addr_up <= j;
            o_addr_dn <= j_plus_len;
            if (j == (start + len - 1)) begin
              if (start + stride >= 9'd256) begin
                if (len == 8'd2) begin
                  o_done <= 1'b1;
                  st     <= DONE;
                end else begin
                  len   <= (len >> 1);
                  start <= 8'd0;
                  j     <= 8'd0;
                  i7    <= i7 + 7'd1;
                end
              end else begin
                start <= start + stride[7:0];
                j     <= start + stride[7:0];
                i7    <= i7 + 7'd1;
              end
            end else begin
              j <= j + 8'd1; 
            end
          end
        end

        DONE: begin
          o_last_stage  <= 1'b0;
          o_ntt_active  <= 1'b0;
          len          <= 8'd0;
          start        <= 8'd0;
          j            <= 8'd0;
          i7           <= 7'd1;
          o_addr_up    <= 8'd0;
          o_addr_dn    <= 8'd0;
          o_zeta_idx   <= 7'd0;  
          if (!i_start) st <= IDLE;
        end
        default: st <= IDLE;
      endcase
    end
  end
endmodule
