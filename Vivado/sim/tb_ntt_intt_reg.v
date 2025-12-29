`timescale 1ns / 1ps
/*
module tb_ntt_intt_top_reg;

    reg clk, rst, start, mode;
    wire done;
    integer i;

    // ------------------- Instance of DUT -------------------
    ntt_intt_top_reg uut (
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
        reg [15:0] mem_data [0:255];
    begin
        // Load file into BRAM
        $readmemh(fname, uut.blockram);
        $display("BRAM preloaded with NTT input from %s", fname);

        // Show first 8 BRAM values
        $display("First 8 BRAM values before NTT:");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.blockram[i]);

        // Start NTT
        mode = 0;
        pulse_start();

        // Wait done
        $display("Waiting for NTT to complete...");
        wait(done == 1);
        $display("NTT completed at t=%0t", $time);
        wait(done == 0);
        #50;

        // Dump first 8 RegFile values after copy + processing
        $display("------ First 8 RegFile after NTT ------");
        for(i=0;i<8;i=i+1) $display("RegFile[%0d] = %h", i, uut.u_regfile.mem[i]);
    end
    endtask

    // ------------------- Run INTT -------------------
    task run_intt(input [1023:0] fname);
    begin
        // Clear BRAM
        for(i=0;i<256;i=i+1) uut.blockram[i] = 16'd0;

        // Load input file into BRAM
        $readmemh(fname, uut.blockram);
        $display("BRAM preloaded with INTT input from %s", fname);

        // Show first 8 BRAM values
        $display("First 8 BRAM values before INTT:");
        for(i=0;i<8;i=i+1) $display("BRAM[%0d] = %h", i, uut.blockram[i]);

        // Start INTT
        mode = 1;
        pulse_start();

        // Wait done
        $display("Waiting for INTT to complete...");
        wait(done == 1);
        $display("INTT completed at t=%0t", $time);
        wait(done == 0);
        #50;

        // Dump first 8 RegFile values after processing
        $display("------ First 8 RegFile after INTT ------");
        for(i=0;i<8;i=i+1) $display("RegFile[%0d] = %h", i, uut.u_regfile.mem[i]);
    end
    endtask

    // ------------------- Monitor -------------------
    initial begin
        $monitor("Time=%0t rst=%b start=%b mode=%b done=%b", 
                 $time, rst, start, mode, done);
    end

endmodule
*/

`timescale 1ns/1ps

module tb_ntt_intt_top_reg;

    reg clk, rst, start, mode;
    wire done;
    integer i;

    // ------------------- Instance of DUT -------------------
    wire        bram_we_a, bram_we_b;
    wire [7:0]  bram_addr_a, bram_addr_b;
    wire [15:0] bram_din_a, bram_din_b;
    wire [15:0] bram_dout_a, bram_dout_b;

    ntt_intt_top_reg u_top (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .done(done),

        // ---- BRAM port A: FSM copy ----
        .bram_addr_a(bram_addr_a),
        .bram_dout_a(bram_dout_a),
        .bram_we_a(bram_we_a),
        .bram_din_a(bram_din_a),

        // ---- BRAM port B: WB  ----
        .bram_addr_b(bram_addr_b),
        .bram_dout_b(bram_dout_b),
        .bram_we_b(bram_we_b),
        .bram_din_b(bram_din_b)
    );

    bram_tdp_16x256 #(
        .INIT_FILE("E:/VDT2025Vivado/Test Modular/Test Modular.srcs/sim_1/new/inputntttest.hex")
    ) bram_in1 (
        .clk(clk),
        .we_a(bram_we_a),
        .addr_a(bram_addr_a),
        .din_a(bram_din_a),
        .dout_a(bram_dout_a),

        .we_b(bram_we_b),
        .addr_b(bram_addr_b),
        .din_b(bram_din_b),
        .dout_b(bram_dout_b)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;

    task pulse_start;
    begin
        start = 1;
        @(posedge clk);
        @(posedge clk);
        start = 0;
    end
    endtask

    // ---------------- Cycle counter ----------------
    integer cycle_count;
    always @(posedge clk) begin
        if (rst) begin
            cycle_count <= 0;
        end else if (start) begin
            cycle_count <= 0;
        end else if (!done && cycle_count >= 0) begin
            cycle_count <= cycle_count + 1;
        end
    end

    always @(posedge clk) begin
        if (done) begin
            $display("[%0t] DONE after %0d cycles", $time, cycle_count);
        end
    end

    // ------------------- Main Test -------------------
    initial begin
        rst = 1; start = 0; mode = 0;
        #50;
        rst = 0;
        #20;

        // Start NTT
        mode = 0;
        pulse_start();

        // Wait done
        $display("Waiting for NTT to complete...");
        wait(done == 1);
        $display("NTT completed at t=%0t", $time);
        wait(done == 0);
        #50;
        
        // Start INTT
        mode = 1;
        pulse_start();

        // Wait done
        $display("Waiting for INTT to complete...");
        wait(done == 1);
        $display("INTT completed at t=%0t", $time);
        wait(done == 0);
        #50;   

        $finish;
    end

endmodule
