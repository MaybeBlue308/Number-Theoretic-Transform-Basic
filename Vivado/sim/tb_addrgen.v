`timescale 1ns/1ps

module tb_addrgen;

  // ---- clock/reset/start/sel ----
  reg clk = 1'b0;
  reg rst;
  reg i_start;
  reg Sel;          // 0: NTT, 1: INTT

  // ---- outputs from DUT ----
  wire [7:0] addr_up;
  wire [7:0] addr_dn;
  wire [6:0] zeta_idx;
  wire       done;
  wire       last_stage;
  wire       active;

  // clock 100 MHz
  always #5 clk = ~clk;

  // DUT
  addrgen dut (
    .clk       (clk),
    .rst       (rst),
    .i_start   (i_start),
    .Sel       (Sel),
    .addr_up   (addr_up),
    .addr_dn   (addr_dn),
    .zeta_idx  (zeta_idx),
    .done      (done),
    .last_stage(last_stage),
    .active    (active)
  );

  // ---- helper: phát xung start 1 chu k? ----
  task automatic pulse_start;
    begin
      @(posedge clk);
      i_start <= 1'b1;
      @(posedge clk);
      i_start <= 1'b0;
    end
  endtask

  // ---- Stimulus ----
  initial begin
    // init
    rst     = 1'b1;
    i_start = 1'b0;
    Sel     = 1'b0;     // m?c ??nh NTT
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // ===== Run NTT (Sel=0) =====
    Sel = 1'b0;            // ch?n NTT
    @(posedge clk);        // gi? ?n ??nh 1 nh?p
    pulse_start();         // phát start
    wait (done);           // ch? hoàn t?t
    @(posedge clk);
    repeat (3) @(posedge clk); // ngh? vài nh?p

    // ===== Run INTT (Sel=1) =====
    Sel = 1'b1;            // ch?n INTT
    @(posedge clk);        // gi? ?n ??nh 1 nh?p
    pulse_start();         // phát start
    wait (done);           // ch? hoàn t?t
    @(posedge clk);
    repeat (3) @(posedge clk);

    // k?t thúc
    $finish;
  end

endmodule
