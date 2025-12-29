`timescale 1ns / 1ps
module tb_ntt_bram_wrapper;

    reg clk, rst, start, mode;
    wire done;
    integer i;

    // ------------------- Instance of DUT -------------------
    ntt_bram_wrapper uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .done(done)
    );

    // Clock: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ------------------- Main Test -------------------
    initial begin
        rst = 1; start = 0; mode = 0;
        #50;
        rst = 0;
        #20;

        // ------------------- Test 1: NTT -------------------
        $display("===== Running NTT =====");
        run_ntt("E:/VDT2025Vivado/Test Modular/Test Modular.srcs/sim_1/new/inputntttest.hex");

        // ------------------- Test 2: INTT -------------------
        $display("===== Running INTT =====");
        run_intt("E:/VDT2025Vivado/INTT/INTT.srcs/sim_1/new/input_intt_test.hex");

        $display("Simulation finished!");
        $finish;
    end

    // ------------------- Pulse start -------------------
    task pulse_start;
    begin
        start = 1;
        @(posedge clk);
        @(posedge clk);
        start = 0;
    end
    endtask

    // ------------------- Run NTT -------------------
    task run_ntt(input [1023:0] fname);
    begin
        // Load file into BRAM
        $readmemh(fname, uut.u_bram.blockram);
        $display("BRAM preloaded with NTT input from %s", fname);

        // Show first 8 BRAM values
        $display("First 8 BRAM values before NTT:");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.u_bram.blockram[i]);

        // Start NTT
        mode = 0;
        pulse_start();

        // Wait done
        $display("Waiting for NTT to complete...");
        wait(done == 1);
        $display("NTT completed at t=%0t", $time);
        wait(done == 0);
        #50;

        // Dump first 8 BRAM values after processing
        $display("------ First 8 BRAM after NTT ------");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.u_bram.blockram[i]);
    end
    endtask

    // ------------------- Run INTT -------------------
    task run_intt(input [1023:0] fname);
    begin
        // Clear BRAM
        for(i=0;i<256;i=i+1) uut.u_bram.blockram[i] = 16'd0;

        // Load input file into BRAM
        $readmemh(fname, uut.u_bram.blockram);
        $display("BRAM preloaded with INTT input from %s", fname);

        // Show first 8 BRAM values
        $display("First 8 BRAM values before INTT:");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.u_bram.blockram[i]);

        // Start INTT
        mode = 1;
        pulse_start();

        // Wait done
        $display("Waiting for INTT to complete...");
        wait(done == 1);
        $display("INTT completed at t=%0t", $time);
        wait(done == 0);
        #50;

        // Dump first 8 BRAM values after processing
        $display("------ First 8 BRAM after INTT ------");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.u_bram.blockram[i]);
    end
    endtask

    // ------------------- Monitor -------------------
    initial begin
        $monitor("Time=%0t rst=%b start=%b mode=%b done=%b", 
                 $time, rst, start, mode, done);
    end

endmodule
