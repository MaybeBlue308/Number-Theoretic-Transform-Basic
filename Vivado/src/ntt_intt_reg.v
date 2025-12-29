/*

module ntt_intt_top_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,     // b?t ??u 1 phép tính
    input  wire        mode,      // 0 = NTT, 1 = INTT
    output wire        done       // xong
);

    // ---------------------- State Machine ----------------------
    localparam IDLE        = 3'b000;
    localparam COPY_REG    = 3'b001;  
    localparam PROCESSING  = 3'b010;  
    localparam WAIT_DONE   = 3'b011;  

    reg [2:0] state;
    reg [7:0] copy_addr;
    reg       pipeline_start;

    wire pipeline_done;

    // ---------------------- Copy BRAM -> RegFile ----------------------
    reg [15:0] blockram [0:255];

    // Tín hi?u copy tr?c ti?p
    wire copy_rf_we = (state == COPY_REG);
    wire [7:0] copy_rf_addr_a = copy_addr;
    wire [7:0] copy_rf_addr_b = copy_addr + 1;
    wire [11:0] copy_rf_din_a = blockram[copy_addr][11:0];
    wire [11:0] copy_rf_din_b = blockram[copy_addr+1][11:0];

    // ---------------------- State Machine ----------------------
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state <= IDLE;
            copy_addr <= 0;
            pipeline_start <= 0;
        end else begin
            case(state)
                IDLE: begin
                    pipeline_start <= 0;
                    if(start) begin
                        copy_addr <= 0;
                        state <= COPY_REG;
                    end
                end
                COPY_REG: begin
                    copy_addr <= copy_addr + 2;
                    if(copy_addr >= 254) begin
                        state <= PROCESSING;
                        pipeline_start <= 1;
                    end
                end
                PROCESSING: begin
                    pipeline_start <= 0;
                    state <= WAIT_DONE;
                end
                WAIT_DONE: begin
                    if(pipeline_done) state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    // ---------------------- Pipeline Wires ----------------------
    wire        ad_v, ad_last, ad_done;
    wire [7:0]  ad_addr_up, ad_addr_dn;
    wire [6:0]  ad_addr_zeta;

    wire [7:0]  va_addr_up, va_addr_dn, rf_addr_up, rf_addr_dn;
    wire [11:0] va_bu_in_up, va_bu_in_dn, va_zeta;
    wire        va_v, va_last, va_done, va_sel;
    wire [11:0] rf_out_up, rf_out_dn;
    
    wire [7:0]  ex_addr_up, ex_addr_dn;
    wire [11:0] ex_data_up, ex_data_dn;
    wire        ex_v, ex_last, ex_done;

    // ---------------------- WB Dualport ----------------------
    wire        wb_rf_we;
    wire [7:0]  wb_rf_addr_a, wb_rf_addr_b;
    wire [11:0] wb_rf_din_a, wb_rf_din_b;

    // ---------------------- RegFile ki?u dRAM ----------------------
    wire [7:0] rf_addrw_a = copy_rf_we ? copy_rf_addr_a : wb_rf_addr_a;
    wire [7:0] rf_addrw_b = copy_rf_we ? copy_rf_addr_b : wb_rf_addr_b;
    wire [11:0] rf_din_a   = copy_rf_we ? copy_rf_din_a   : wb_rf_din_a;
    wire [11:0] rf_din_b   = copy_rf_we ? copy_rf_din_b   : wb_rf_din_b;
    wire        rf_we      = copy_rf_we | wb_rf_we;

    Regfile_dual u_regfile (
        .clk(clk),
        .we(rf_we),
        .addrw_a(rf_addrw_a),
        .addrr_a(ad_addr_up),
        .din_a(rf_din_a),
        .dout_a(rf_out_up),
        .addrw_b(rf_addrw_b),
        .addrr_b(ad_addr_dn),
        .din_b(rf_din_b),
        .dout_b(rf_out_dn)
    );


    // ---------------------- AD ----------------------
    AD u_ad (
        .clk(clk),
        .rst(rst),
        .i_start(pipeline_start),
        .Sel(mode),
        .addr_up_a(ad_addr_up),
        .addr_dn_a(ad_addr_dn),
        .addr_zeta_a(ad_addr_zeta),
        .Sel_a(),
        .o_a(ad_v),
        .o_last_a(ad_last),
        .o_done_a(ad_done)
    );

    // ---------------------- VA ----------------------
    VA u_va (
        .clk(clk),
        .rst(rst),
        .i_a(ad_v),
        .i_last_a(ad_last),
        .i_done_a(ad_done),
        .i_addr_up_a(ad_addr_up),
        .i_addr_dn_a(ad_addr_dn),
        .i_addr_zeta_a(ad_addr_zeta),
        .i_sel_a(mode),
        .i_dRAM_dout_up(rf_out_up),
        .i_dRAM_dout_dn(rf_out_dn),
        .o_dRAM_addr_up(rf_addr_up),
        .o_dRAM_addr_dn(rf_addr_dn),
        .o_v(va_v),
        .o_last_v(va_last),
        .o_done_v(va_done),
        .o_sel_v(va_sel),
        .addr_up_v(va_addr_up),
        .addr_dn_v(va_addr_dn),
        .bu_in_up_v(va_bu_in_up),
        .bu_in_dn_v(va_bu_in_dn),
        .zeta_val_v(va_zeta)
    );

    // ---------------------- EX ----------------------
    EX u_ex (
        .clk(clk),
        .rst(rst),
        .i_v(va_v),
        .i_last_v(va_last),
        .i_done_v(va_done),
        .i_sel_v(va_sel),
        .i_addr_up_v(va_addr_up),
        .i_addr_dn_v(va_addr_dn),
        .i_bu_in_up_v(va_bu_in_up),
        .i_bu_in_dn_v(va_bu_in_dn),
        .i_zeta_val_v(va_zeta),
        .o_e(ex_v),
        .o_last_e(ex_last),
        .o_done_e(ex_done),
        .addr_up_e(ex_addr_up),
        .addr_dn_e(ex_addr_dn),
        .bu_out_up_e(ex_data_up),
        .bu_out_dn_e(ex_data_dn)
    );

    // ---------------------- WB Dualport ----------------------

    // ---------------------- WB Dualport ----------------------
    WB_dualport u_wb (
        .clk(clk),
        .rst(rst),
        .i_e(ex_v),
        .i_last_e(ex_last),
        .i_sel(mode),
        .i_addr_up_e(ex_addr_up),
        .i_addr_dn_e(ex_addr_dn),
        .i_bu_out_up_e(ex_data_up),
        .i_bu_out_dn_e(ex_data_dn),

        // ---- Regfile ----
        .rf_we_a(wb_rf_we),
        .rf_addr_a(wb_rf_addr_a),
        .rf_din_a(wb_rf_din_a),
        .rf_we_b(wb_rf_we),            // dùng chung enable
        .rf_addr_b(wb_rf_addr_b),
        .rf_din_b(wb_rf_din_b),

        // ---- BRAM ----
        .bram_we_a(),                  // ch?a dùng -> ?? tr?ng
        .bram_addr_a(),
        .bram_din_a(),
        .bram_we_b(),
        .bram_addr_b(),
        .bram_din_b()
    );

    // ---------------------- Control Logic ----------------------
    assign pipeline_done = ex_done;
    assign done = (state == WAIT_DONE) && pipeline_done;

endmodule
*/


module ntt_intt_top_reg (
    input  wire        clk,
    input  wire        rst,
    input  wire        start,     
    input  wire        mode,      // 0 = NTT, 1 = INTT
    output wire        done,      // xong

    // ---- BRAM port A (COPY into RegFile) ----
    output wire [7:0]  bram_addr_a,
    output wire        bram_we_a,   // when 1 => write; during COPY it's 0 (read)
    output wire [15:0] bram_din_a,  // data to BRAM port A 
    input  wire [15:0] bram_dout_a, // data from BRAM port A

    // ---- BRAM port B (for WB / pipeline) ----
    output wire [7:0]  bram_addr_b,
    output wire        bram_we_b,
    output wire [15:0] bram_din_b,
    input  wire [15:0] bram_dout_b
);

    // ---------------------- State Machine ----------------------
    localparam IDLE        = 3'b000;
    localparam COPY_REG    = 3'b001;  
    localparam PROCESSING  = 3'b010;  
    localparam WAIT_DONE   = 3'b011;  

    reg [2:0] state;

    // ---------------------- copy FSM internals ----------------------
    // copy works in 2-phase per pair (ISSUE address -> CAPTURE data & write RegFile)
    reg        copy_subphase;        // 0 = ISSUE addresses, 1 = CAPTURE data & write
    reg [7:0]  copy_addr;            // current pair base address (0,2,4,...,254)

    // pulse to AD to start pipeline (assert 1 cycle when copy finished)
    reg        pipeline_start;

    wire pipeline_done; // driven by ex_done later

    // ---------------------- Signals previously used ----------------------
    // Pipeline wires
    wire        ad_v, ad_last, ad_done;
    wire [7:0]  ad_addr_up, ad_addr_dn;
    wire [6:0]  ad_addr_zeta;

    wire [7:0]  va_addr_up, va_addr_dn, rf_addr_up, rf_addr_dn;
    wire [11:0] va_bu_in_up, va_bu_in_dn, va_zeta;
    wire        va_v, va_last, va_done, va_sel;
    wire [11:0] rf_out_up, rf_out_dn;
    
    wire [7:0]  ex_addr_up, ex_addr_dn;
    wire [11:0] ex_data_up, ex_data_dn;
    wire        ex_v, ex_last, ex_done;

    // ---------------------- WB Dualport ? top (internal wires) ----------
    // RegFile writeback signals from WB
    wire        wb_rf_we_a;
    wire [7:0]  wb_rf_addr_a;
    wire [11:0] wb_rf_din_a;
    wire        wb_rf_we_b;
    wire [7:0]  wb_rf_addr_b;
    wire [11:0] wb_rf_din_b;

    // BRAM signals produced by WB (top will multiplex between these and COPY)
    wire        wb_bram_we_a;
    wire [7:0]  wb_bram_addr_a;
    wire [15:0] wb_bram_din_a;
    wire        wb_bram_we_b;
    wire [7:0]  wb_bram_addr_b;
    wire [15:0] wb_bram_din_b;

    // ---------------------- COPY -> RegFile (registers to present valid data) ----
    // These registers hold the values captured from BRAM and are pulsed into RegFile
    reg         copy_rf_we;          // pulse 1 cycle when capturing data from BRAM
    reg [7:0]   copy_rf_addr_a;
    reg [7:0]   copy_rf_addr_b;
    reg [11:0]  copy_rf_din_a;
    reg [11:0]  copy_rf_din_b;

    // ---------------------- multiplexers for RegFile write inputs -------------
    // When copy_rf_we is asserted, use copy_* as write inputs; else use WB's values.
    wire [7:0] rf_addrw_a = (copy_rf_we) ? copy_rf_addr_a : wb_rf_addr_a;
    wire [7:0] rf_addrw_b = (copy_rf_we) ? copy_rf_addr_b : wb_rf_addr_b;
    wire [11:0] rf_din_a  = (copy_rf_we) ? copy_rf_din_a  : wb_rf_din_a;
    wire [11:0] rf_din_b  = (copy_rf_we) ? copy_rf_din_b  : wb_rf_din_b;
    // single write-enable input to Regfile (original Regfile_dual uses single 'we' to write both ports)
    wire rf_we = copy_rf_we | wb_rf_we_a | wb_rf_we_b;
  
    
    // ---------------------- RegFile instance (unchanged) ---------------------
    Regfile_dual u_regfile (
        .clk(clk),
        .we(rf_we),
        .addrw_a(rf_addrw_a),
        .addrr_a(ad_addr_up),
        .din_a(rf_din_a),
        .dout_a(rf_out_up),
        .addrw_b(rf_addrw_b),
        .addrr_b(ad_addr_dn),
        .din_b(rf_din_b),
        .dout_b(rf_out_dn)
    );

    // ---------------------- AD, VA, EX instances (unchanged) -----------------
    AD u_ad (
        .clk(clk),
        .rst(rst),
        .i_start(pipeline_start),
        .Sel(mode),
        .addr_up_a(ad_addr_up),
        .addr_dn_a(ad_addr_dn),
        .addr_zeta_a(ad_addr_zeta),
        .Sel_a(),
        .o_a(ad_v),
        .o_last_a(ad_last),
        .o_done_a(ad_done)
    );

    VA u_va (
        .clk(clk),
        .rst(rst),
        .i_a(ad_v),
        .i_last_a(ad_last),
        .i_done_a(ad_done),
        .i_addr_up_a(ad_addr_up),
        .i_addr_dn_a(ad_addr_dn),
        .i_addr_zeta_a(ad_addr_zeta),
        .i_sel_a(mode),
        .i_dRAM_dout_up(rf_out_up),
        .i_dRAM_dout_dn(rf_out_dn),
        .o_dRAM_addr_up(rf_addr_up),
        .o_dRAM_addr_dn(rf_addr_dn),
        .o_v(va_v),
        .o_last_v(va_last),
        .o_done_v(va_done),
        .o_sel_v(va_sel),
        .addr_up_v(va_addr_up),
        .addr_dn_v(va_addr_dn),
        .bu_in_up_v(va_bu_in_up),
        .bu_in_dn_v(va_bu_in_dn),
        .zeta_val_v(va_zeta)
    );

    EX u_ex (
        .clk(clk),
        .rst(rst),
        .i_v(va_v),
        .i_last_v(va_last),
        .i_done_v(va_done),
        .i_sel_v(va_sel),
        .i_addr_up_v(va_addr_up),
        .i_addr_dn_v(va_addr_dn),
        .i_bu_in_up_v(va_bu_in_up),
        .i_bu_in_dn_v(va_bu_in_dn),
        .i_zeta_val_v(va_zeta),
        .o_e(ex_v),
        .o_last_e(ex_last),
        .o_done_e(ex_done),
        .addr_up_e(ex_addr_up),
        .addr_dn_e(ex_addr_dn),
        .bu_out_up_e(ex_data_up),
        .bu_out_dn_e(ex_data_dn)
    );

    // ---------------------- WB Dualport instance (produce wb_* signals) -------
    WB_dualport u_wb (
        .clk(clk),
        .rst(rst),
        .i_e(ex_v),
        .i_last_e(ex_last),
        .i_sel(mode),
        .i_addr_up_e(ex_addr_up),
        .i_addr_dn_e(ex_addr_dn),
        .i_bu_out_up_e(ex_data_up),
        .i_bu_out_dn_e(ex_data_dn),

        // RegFile outputs
        .rf_we_a(wb_rf_we_a),
        .rf_addr_a(wb_rf_addr_a),
        .rf_din_a(wb_rf_din_a),
        .rf_we_b(wb_rf_we_b),
        .rf_addr_b(wb_rf_addr_b),
        .rf_din_b(wb_rf_din_b),

        // BRAM outputs (WB wants to write these when processing)
        .bram_we_a(wb_bram_we_a),
        .bram_addr_a(wb_bram_addr_a),
        .bram_din_a(wb_bram_din_a),
        .bram_we_b(wb_bram_we_b),
        .bram_addr_b(wb_bram_addr_b),
        .bram_din_b(wb_bram_din_b)
    );

    // ---------------------- BRAM top-level multiplexing -----------------------
    // When state == COPY_REG, top will drive BRAM addresses for copy operation (read),
    // and force we = 0 (read). Otherwise forward WB's BRAM signals to external BRAM.

    // bram_addr_a / bram_addr_b are outputs of top (to external BRAM)
    assign bram_addr_a = (state == COPY_REG) ? copy_addr : wb_bram_addr_a;
    assign bram_we_a   = (state == COPY_REG) ? 1'b0 : wb_bram_we_a;
    assign bram_din_a  = wb_bram_din_a; // when copy, we don't write from top on port A

    assign bram_addr_b = (state == COPY_REG) ? (copy_addr + 8'd1) : wb_bram_addr_b;
    assign bram_we_b   = (state == COPY_REG) ? 1'b0 : wb_bram_we_b;
    assign bram_din_b  = wb_bram_din_b; // when copy, we don't write from top on port B

    // ---------------------- COPY state machine / sequencing -------------------
    // We implement a simple 2-phase per pair copy: ISSUE addresses (1 cycle) -> CAPTURE (next cycle)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            copy_subphase <= 1'b0;
            copy_addr <= 8'd0;
            copy_rf_we <= 1'b0;
            copy_rf_addr_a <= 8'd0;
            copy_rf_addr_b <= 8'd0;
            copy_rf_din_a <= 12'd0;
            copy_rf_din_b <= 12'd0;
            pipeline_start <= 1'b0;
        end else begin
            // default: clear single-cycle pulses
            copy_rf_we <= 1'b0;
            pipeline_start <= 1'b0;

            case (state)
                IDLE: begin
                    if (start) begin
                        // start copy process
                        state <= COPY_REG;
                        copy_subphase <= 1'b0;   // start with ISSUE addresses
                        copy_addr <= 8'd0;
                    end
                end

                COPY_REG: begin
                    if (copy_subphase == 1'b0) begin
                        // ISSUE addresses: bram_addr_a/bram_addr_b are driven by combinational assign
                        // wait one cycle, then capture in next branch
                        copy_subphase <= 1'b1;
                    end else begin
                        // CAPTURE: bram_dout_* contain data for addresses 'copy_addr' and 'copy_addr+1'
                        // write them into RegFile (pulse copy_rf_we for 1 cycle)
                        copy_rf_we <= 1'b1;
                        copy_rf_addr_a <= copy_addr;
                        copy_rf_addr_b <= copy_addr + 8'd1;
                        copy_rf_din_a <= bram_dout_a[11:0];
                        copy_rf_din_b <= bram_dout_b[11:0];

                        // prepare next pair
                        if (copy_addr >= 8'd254) begin
                            // finished copying whole BRAM
                            state <= PROCESSING;
                            pipeline_start <= 1'b1; // pulse start to AD to begin pipeline
                            copy_subphase <= 1'b0;
                        end else begin
                            copy_addr <= copy_addr + 8'd2;
                            copy_subphase <= 1'b0; // issue next addresses next cycle
                        end
                    end
                end

                PROCESSING: begin
                    // pipeline_start was pulsed when entering PROCESSING; go to WAIT_DONE
                    state <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    // wait until pipeline finishes
                    if (ex_done) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
    
    // ---------------------- Done / pipeline_done ------------------------------
    assign pipeline_done = ex_done;
    assign done = (state == WAIT_DONE) && pipeline_done;

endmodule
