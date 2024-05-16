module fifo_tb;
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
    parameter   D_WIDTH = 32;
    parameter   DEPTH = 16; //change to be area of reservation stations

    logic r_en;
    logic [D_WIDTH-1:0] r_data;
    logic w_en;
    logic [D_WIDTH-1:0] w_data;
    logic full_sig;
    logic empty_sig;

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
    queue #(.D_WIDTH(D_WIDTH), .DEPTH(DEPTH)) hdl_q(
        .clk(clk),
        .rst(rst),
        .r_en(r_en),
        .r_data(r_data),
        .w_en(w_en),
        .w_data(w_data),
        .full_sig(full_sig),
        .empty_sig(empty_sig)
    );

    logic   [D_WIDTH-1:0] golden_q [$:DEPTH];


    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------
    task push(logic [D_WIDTH-1:0] wdata);
        @(posedge clk);
        w_en <= 1'b1;
        w_data <= wdata;
        @(posedge clk);
        golden_q.push_back(w_data);
        w_en <= 1'b0;
        w_data <= '0;
    endtask

    task pop();
        logic [D_WIDTH-1:0] golden_rdata;
        logic [D_WIDTH-1:0] dut_rdata;
        @(posedge clk);
        r_en <= 1'b1;
        @(posedge clk);
        golden_rdata = golden_q.pop_front();
        #1 dut_rdata = r_data;
        // $display("data popped off queue : %d", dut_rdata);
        pop_match: assert(dut_rdata == golden_rdata) else $error("pop test failed, \n dut_rdata: %d \n, golden_r_data: %d ", dut_rdata, golden_rdata); 
        // @(posedge clk);
        r_en <= 1'b0;
    endtask

    task isEmpty();
        @(posedge clk);
        if(empty_sig) begin
            $display("queue is empty %t",$time);
        end
        else begin
            $display("queue is not empty %t",$time);
        end
    endtask

    task isFull();
        @(posedge clk);
        if(full_sig) begin
            $display("queue is full %t",$time);
        end
        else begin
            $display("queue is not full %t",$time);
        end
    endtask

    task concurrentPushPop(logic [D_WIDTH-1:0] wdata);
        @(posedge clk);
        w_en <= 1'b1;
        w_data <= wdata;
        r_en <= 1'b1;
        @(posedge clk);
        w_en <= 1'b0;
        r_en <= 1'b0;
    endtask

    //---------------------------------------------------------------------------------
    // TODO: Main initial block that calls your tasks, then calls $finish
    //---------------------------------------------------------------------------------
    initial begin
        gen_reset();
        golden_q.delete(); //resets whole queue since pos not specified

        for( int unsigned i = 0; i < DEPTH; i++)begin
            push(i);
        end
        isFull();
        for( int unsigned i = 0; i < DEPTH; i++)begin
            pop();
        end
        isEmpty();

        for( int unsigned i = 0; i < DEPTH; i++)begin
            push(i);
        end
        isFull();
        gen_reset();
        golden_q.delete(); //resets whole queue since pos not specified
        isFull();
        isEmpty();

        for( int unsigned i = 0; i < DEPTH; i++)begin
            concurrentPushPop(i);
        end
        isFull();
        isEmpty();
        
        repeat (5) @(posedge clk);
        $finish;
    end

endmodule : fifo_tb