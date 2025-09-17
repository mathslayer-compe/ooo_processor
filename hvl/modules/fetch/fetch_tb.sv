module fetch_tb;
    //---------------------------------------------------------------------------------
    // Time unit setup.
    //---------------------------------------------------------------------------------
    timeunit 1ps;
    timeprecision 1ps;

    //---------------------------------------------------------------------------------
    // Waveform generation.
    //---------------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //---------------------------------------------------------------------------------
    // TODO: Declare queue port signals:
    //---------------------------------------------------------------------------------


    //---------------------------------------------------------------------------------
    // TODO: Generate a clock:
    //---------------------------------------------------------------------------------
    int clock_half_period_ps = 5;
    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    //---------------------------------------------------------------------------------
    // TODO: Write a task to generate reset:
    //---------------------------------------------------------------------------------
    bit rst;
    task gen_reset();
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    endtask

    //---------------------------------------------------------------------------------
    // TODO: Instantiate the DUT and golden model hvl queue:
    //---------------------------------------------------------------------------------
    cpu dut(
        .clk            (clk),
        .rst            (rst),
        // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
        .imem_addr      (mem_itf_i.addr),
        .imem_rmask     (mem_itf_i.rmask),
        .imem_rdata     (mem_itf_i.rdata),
        .imem_resp      (mem_itf_i.resp),

        .dmem_addr      (mem_itf_d.addr),
        .dmem_rmask     (mem_itf_d.rmask),
        .dmem_wmask     (mem_itf_d.wmask),
        .dmem_rdata     (mem_itf_d.rdata),
        .dmem_wdata     (mem_itf_d.wdata),
        .dmem_resp      (mem_itf_d.resp)
    );

    mem_itf mem_itf_i(.*);
    mem_itf mem_itf_d(.*);
   // magic_dual_port mem(.itf_i(mem_itf_i), .itf_d(mem_itf_d));
   ordinary_dual_port mem(.itf_i(mem_itf_i), .itf_d(mem_itf_d));

    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------



    //---------------------------------------------------------------------------------
    // TODO: Main initial block that calls your tasks, then calls $finish
    //---------------------------------------------------------------------------------
    initial begin
        gen_reset();

        $display(dut.queue_top);
        repeat (5000) @(posedge clk);
        $finish;
    end

endmodule : fetch_tb