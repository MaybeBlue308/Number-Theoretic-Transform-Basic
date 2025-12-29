`timescale 1ns/1ps

module tb_butterfly_unit;

  // --- c?u hình ---
  localparam integer PIPE_LAT = 5;   // giá tr? b?n bi?t (dùng ?? so sánh cu?i)
  localparam integer NTEST    = 20;
  localparam integer Q        = 3329;
  localparam integer MAX_WAIT = 500;

  // --- clock/reset ---
  reg clk = 1'b0;
  reg rst;
  always #5 clk = ~clk; // 100 MHz

  // --- kích thích ---
  reg  [11:0] a, b, twf;
  reg         sel;      // 0: NTT, 1: INTT

  // --- outputs ---
  wire [11:0] o_up, o_dn;

  // DUT
  butterfly_unit #(.Q(Q)) dut (
    .clk(clk),
    .rst(rst),
    .a(a),
    .b(b),
    .twf(twf),
    .Sel(sel),
    .o_up(o_up),
    .o_dn(o_dn)
  );

  // --- testcase và expected ---
  reg [11:0] A   [0:NTEST-1];
  reg [11:0] B   [0:NTEST-1];
  reg [11:0] TWF [0:NTEST-1];
  reg        SEL [0:NTEST-1];
  reg [11:0] EXP_UP [0:NTEST-1];
  reg [11:0] EXP_DN [0:NTEST-1];

  // --- ?o th?i gian ---
  integer sim_cycle = 0;                // counter t?ng m?i posedge
  integer apply_cycle [0:NTEST-1];      // lúc phát t?ng vector
  integer recv_cycle  [0:NTEST-1];      // lúc nh?n k?t qu? t??ng ?ng
 

  integer i, rec_ptr, wait_cnt;

  // --- t?ng counter m?i posedge ---
  always @(posedge clk) sim_cycle = sim_cycle + 1;

  // --- model tham chi?u (butterfly) ---
  function [23:0] butterfly_ref;
    input [11:0] a, b, twf;
    input        sel;
    reg [11:0] t;
    reg [23:0] ret;
    begin
      if (sel == 1'b0) begin
        // NTT: t = b * twf mod Q
        t = (b * twf) % Q;
        ret[11:0]   = (a + t) % Q;          // up
        ret[23:12]  = (a + Q - t) % Q;      // dn
      end else begin
        // INTT: (ví d? implementation nh? tr??c)
        t = (a + Q - b) % Q;
        ret[11:0]   = (t * twf) % Q;        // up
        ret[23:12]  = (a + b) % Q;          // dn
      end
      butterfly_ref = ret;
    end
  endfunction

  // --- n?p vectors và expected ---
  initial begin
    // 10 case NTT (sel=0)
    A[0]=12'd0;  B[0]=12'd0;  TWF[0]=12'd0;  SEL[0]=1'b0;
    A[1]=12'd1;  B[1]=12'd2;  TWF[1]=12'd3;  SEL[1]=1'b0;
    A[2]=12'd4;  B[2]=12'd5;  TWF[2]=12'd6;  SEL[2]=1'b0;
    A[3]=12'd7;  B[3]=12'd8;  TWF[3]=12'd9;  SEL[3]=1'b0;
    A[4]=12'd2;  B[4]=12'd9;  TWF[4]=12'd1;  SEL[4]=1'b0;
    A[5]=12'd9;  B[5]=12'd2;  TWF[5]=12'd1;  SEL[5]=1'b0;
    A[6]=12'd3;  B[6]=12'd3;  TWF[6]=12'd3;  SEL[6]=1'b0;
    A[7]=12'd5;  B[7]=12'd7;  TWF[7]=12'd2;  SEL[7]=1'b0;
    A[8]=12'd8;  B[8]=12'd1;  TWF[8]=12'd4;  SEL[8]=1'b0;
    A[9]=12'd6;  B[9]=12'd6;  TWF[9]=12'd9;  SEL[9]=1'b0;

    // 10 case INTT (sel=1)
    A[10]=12'd0; B[10]=12'd9; TWF[10]=12'd1; SEL[10]=1'b1;
    A[11]=12'd1; B[11]=12'd0; TWF[11]=12'd2; SEL[11]=1'b1;
    A[12]=12'd2; B[12]=12'd1; TWF[12]=12'd3; SEL[12]=1'b1;
    A[13]=12'd3; B[13]=12'd2; TWF[13]=12'd4; SEL[13]=1'b1;
    A[14]=12'd4; B[14]=12'd3; TWF[14]=12'd5; SEL[14]=1'b1;
    A[15]=12'd5; B[15]=12'd4; TWF[15]=12'd6; SEL[15]=1'b1;
    A[16]=12'd6; B[16]=12'd5; TWF[16]=12'd7; SEL[16]=1'b1;
    A[17]=12'd7; B[17]=12'd6; TWF[17]=12'd8; SEL[17]=1'b1;
    A[18]=12'd8; B[18]=12'd7; TWF[18]=12'd9; SEL[18]=1'b1;
    A[19]=12'd9; B[19]=12'd8; TWF[19]=12'd2; SEL[19]=1'b1;

    // gen expected
    for (i=0; i<NTEST; i=i+1) begin
      {EXP_DN[i], EXP_UP[i]} = butterfly_ref(A[i], B[i], TWF[i], SEL[i]);
      // init cycles
      apply_cycle[i] = -1;
      recv_cycle[i]  = -1;

    end
  end

  // --- phát stimulus và ghi l?i lúc phát ---
  initial begin
    // reset
    rst = 1'b1;
    a = 12'd0; b = 12'd0; twf = 12'd0; sel = 1'b0;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // reset sim_cycle counter baseline (b?t ??u ??m sau reset)
    sim_cycle = 0;
    rec_ptr = 0;

    // phát vectors (ghi l?i cycle khi phát)
    for (i=0; i<NTEST; i=i+1) begin
      @(posedge clk);
      a   <= A[i];
      b   <= B[i];
      twf <= TWF[i];
      sel <= SEL[i];
      apply_cycle[i] = sim_cycle; // l?u cycle khi stimulus ???c phát
    end

    // ??a input v? 0 sau khi phát xong
    repeat (3) @(posedge clk);
    a <= 12'd0; b <= 12'd0; twf <= 12'd0; sel <= 1'b0;

    // ch? t?t c? k?t qu? ho?c timeout


    if (rec_ptr < NTEST) begin
      $display("** TIMEOUT: ch? nh?n ???c %0d/%0d k?t qu? ", rec_ptr, NTEST);
    end 
    end

  // --- ? m?i posedge: so kh?p output k? ti?p (rec_ptr) ---
  always @(posedge clk) begin
    if (rst) begin
      // nothing
    end else begin
      if (rec_ptr < NTEST) begin
        // n?u output kh?p expected c?a rec_ptr thì ghi nh?n recv_cycle
        if (o_up === EXP_UP[rec_ptr] && o_dn === EXP_DN[rec_ptr]) begin
          recv_cycle[rec_ptr] = sim_cycle;
         
          $display("[%0t] idx=%0d sel=%0d a=%0d b=%0d twf=%0d => o_up=%0d o_dn=%0d (exp=%0d,%0d)  ",
                   $time, rec_ptr, SEL[rec_ptr], A[rec_ptr], B[rec_ptr], TWF[rec_ptr],
                   o_up, o_dn, EXP_UP[rec_ptr], EXP_DN[rec_ptr]);
          rec_ptr = rec_ptr + 1;
        end
      end
    end
  end

endmodule
