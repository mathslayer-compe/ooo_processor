module cpu
import rv32i_types::*;
import module_types::*;
(
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input   logic           clk,
    input   logic           rst,

    // output  logic   [31:0]  imem_addr,
    // output  logic   [3:0]   imem_rmask,
    // input   logic   [31:0]  imem_rdata,
    // input   logic           imem_resp,

    // output  logic   [31:0]  dmem_addr,
    // output  logic   [3:0]   dmem_rmask,
    // output  logic   [3:0]   dmem_wmask,
    // input   logic   [31:0]  dmem_rdata,
    // output  logic   [31:0]  dmem_wdata,
    // input   logic           dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    output logic   [31:0]      bmem_addr,
    output logic               bmem_read,
    output logic               bmem_write,
    output logic   [63:0]      bmem_wdata,
    input  logic               bmem_ready,

    input logic   [31:0]      bmem_raddr,               //where to use this???
    input logic   [63:0]      bmem_rdata,
    input logic               bmem_rvalid
);

    logic   [31:0]  imem_addr;
    logic   [3:0]   imem_rmask;
    logic   [31:0]  imem_rdata;
    logic           imem_resp;

    logic   [31:0]  dmem_addr;
    logic   [3:0]   dmem_rmask;
    logic   [3:0]   dmem_wmask;
    logic   [31:0]  dmem_rdata;
    logic   [31:0]  dmem_wdata;
    logic           dmem_resp;

    logic [PHYS_REG_ADDR-1:0] RRF_state[32];
    rat_entry_t RAT_output;
    logic [I_QUEUE_D_WIDTH-1:0] queue_top;
    logic full_sig, empty_sig, commit_sig;
    decoded_output_t decoded_output;
    rat_entry_t RAT_rs1_out, RAT_rs2_out;
    logic [PHYS_REG_ADDR-1:0] RRF_rdata;
    logic [PHYS_REG_ADDR-1:0] rename_phys_addr;
    logic [4:0] rename_arch_addr;
    rob_entry_t RRF_ready_reg;
    logic arithmetic_filled, mult_filled, mem_filled,  br_filled, div_filled;
    rob_entry_t rob_entry;
    cdb_output_t cdb_output, alu_cdb_info, mult_cdb_info, mem_cdb_info, br_cdb_info, div_cdb_info;
    logic [ROB_IDX_SIZE-1:0] allocated_ROB_ID, rename_ROB_ID;
    logic addr_calc_done;

    logic ROB_full;
    functional_unit_t functional_arith_unit, functional_mult_unit, functional_mem_unit, functional_br_unit, functional_div_unit;
    logic arith_dispatch, mult_dispatch, mem_dispatch, br_dispatch, div_dispatch;
    logic [31:0] pc_prev, pc_prev_next, pc_flush;
    logic br_pred;
    logic flush;

    logic free_list_empty;

    logic [PHYS_REG_ADDR-1:0] rename_rs1_addr, rename_rs2_addr;
    logic rename_rs1_valid, rename_rs2_valid;

    RVFI_signals_t rvfi_signals;

    logic mult_in_use, mem_in_use, div_in_use;
    logic [3:0] unit_stall;
    func_unit_sel_t cdb_unit_serviced;

    logic [31:0] store_addr, store_data;
    logic store_buffer_full, store_buffer_empty;

    logic ROB_commit_store;
    logic free_list_dequeue;
    logic issue_sig, fetch_stall;

    logic update_btb, update_br;
    logic [31:0] commit_pc;
    logic [31:0] commit_pc_next;
    logic br_taken;

    fetch fetch (
        .clk(clk),
        .rst(rst),
        .imem_resp (imem_resp),
        .imem_rdata(imem_rdata),
        .flush(flush),
        .pc_flush(pc_flush),
        .full_sig (full_sig),
        .imem_addr (imem_addr),
        .imem_rmask (imem_rmask),
        .pc_prev(pc_prev),
        .pc_prev_next(pc_prev_next),
        .br_pred(br_pred),
        .fetch_stall(fetch_stall),
        .update_btb(update_btb),
        .update_br(update_br),
        .commit_pc(commit_pc),
        .commit_pc_next(commit_pc_next),
        .br_taken(br_taken)
    );

    queue #(.D_WIDTH(I_QUEUE_D_WIDTH), .DEPTH(I_QUEUE_DEPTH)) i_queue (
        .clk (clk),
        .rst (rst || flush),
        .r_en (!arithmetic_filled && !mult_filled && !ROB_full && !free_list_empty && !mem_filled),
        .r_data (queue_top),
        .w_en (imem_resp && !fetch_stall),
        .w_data ({br_pred, imem_rdata, pc_prev_next, pc_prev}),
        .full_sig (full_sig),
        .empty_sig (empty_sig)
    );

    decoder instruction_decoder (
        .rst(rst || flush  || fetch_stall),
        .br_pred(queue_top[96]),
        .inst(queue_top[95:64]),
        .pc_next(queue_top[63:32]),
        .pc(queue_top[31:0]),
        .decoded_output(decoded_output)
    );

    rename rename(
        .RAT_rs1_out(RAT_rs1_out),
        .RAT_rs2_out(RAT_rs2_out),
        .is_empty(free_list_empty || empty_sig || arithmetic_filled || mult_filled || mem_filled || flush  || fetch_stall),
        .physical_reg(rename_phys_addr),
        .rd(decoded_output.rd_addr),
        .allocated_ROB_ID(allocated_ROB_ID),
        .ROB_full(ROB_full),

        .rob_entry(rob_entry),
        .rename_ROB_ID(rename_ROB_ID),
        .rs1_addr(rename_rs1_addr),
        .rs2_addr(rename_rs2_addr),
        .rs1_valid(rename_rs1_valid),
        .rs2_valid(rename_rs2_valid),
        .rename_arch_addr(rename_arch_addr),
        .rename_sig(free_list_dequeue),
        .issue_sig(issue_sig)
    );

    RAT rat(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .RRF_state(RRF_state),
        .rs1_addr(decoded_output.rs1_addr),
        .rs2_addr(decoded_output.rs2_addr),
        .rs1_data(RAT_rs1_out),
        .rs2_data(RAT_rs2_out),
        .rename_w_en(free_list_dequeue), //free list read en prev dff
        .CDB_w_en(cdb_output.valid),
        .CDB_reg_addr(cdb_output.commit_arch_rd_addr),
        .CDB_phys_addr(cdb_output.commit_phys_rd_addr),
        .rename_reg_addr(rename_arch_addr),
        .w_data(rename_phys_addr)
    );

    RRF rrf(
        .clk(clk),
        .rst(rst),
        .RRF_state(RRF_state),
        .r_addr(RRF_ready_reg.rd_addr), //register destination address
        .r_data(RRF_rdata),
        .w_en(commit_sig), //commit signal
        .w_addr(RRF_ready_reg.rd_addr),
        .w_data(RRF_ready_reg.phys_addr)
    );

    freeList freelist(
        .clk(clk),
        .rst(rst),
        .r_en(free_list_dequeue), 
        .freed_physical_reg(RRF_rdata),
        .w_en(commit_sig), //rrf r_en 
        .flush(flush),
        .physical_reg(rename_phys_addr),
        .is_empty(free_list_empty) //future stall signalempty_sig
    );
   
    reorder_buffer ROB(
        .clk(clk),
        .rst(rst),
        .r_en(1'b1), //TODO: think about stalling
        .r_data(RRF_ready_reg),
        .cdb_rob_input(cdb_output),
        .decoded_output(decoded_output), 
        .w_en(issue_sig), 
        .w_data(rob_entry),
        .rvfi_signals(rvfi_signals),
        .mult_dispatch(mult_dispatch),
        .mem_dispatch(mem_dispatch),
        .arith_dispatch(arith_dispatch),
        .br_dispatch(br_dispatch),
        .div_dispatch(div_dispatch),
        .mult_res_station_reg(functional_mult_unit),
        .mem_res_station_reg(functional_mem_unit),
        .arith_res_station_reg(functional_arith_unit),
        .br_res_station_reg(functional_br_unit),
        .div_res_station_reg(functional_div_unit),
        .allocated_ROB_ID(allocated_ROB_ID),
        .full_sig(ROB_full),
        .empty_sig(),
        .commit_sig(commit_sig),
        .commit_store_sig(ROB_commit_store),
        .flush(flush),
        .pc_flush(pc_flush),
        .update_btb(update_btb),
        .update_br(update_br),
        .commit_pc(commit_pc),
        .commit_pc_next(commit_pc_next),
        .br_taken(br_taken)
    );

    reservationStation reservationStation(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .robIndex(rename_ROB_ID), 
        .decoded_output(decoded_output),
        .rs1_addr(rename_rs1_addr),
        .rs2_addr(rename_rs2_addr),
        .rs1_valid(rename_rs1_valid),
        .rs2_valid(rename_rs2_valid),
        .inst_resp(issue_sig),                
        .cdb_valid(cdb_output.valid),
        .rd_v(cdb_output.data), //cdb_data
        .cdb_phys_addr(cdb_output.commit_phys_rd_addr), //cdb_phys_addr
        .freed_physical_reg (rename_phys_addr),
        .mult_in_use(mult_in_use),
        .mem_in_use(mem_in_use),
        .div_in_use(div_in_use), //input
        .unit_stall(unit_stall),
        .arithmetic_filled(arithmetic_filled),
        .mult_filled(mult_filled),
        .mem_filled(mem_filled),
        .br_filled(br_filled),
        .div_filled(div_filled),
        .functional_arith_unit(functional_arith_unit),
        .functional_mult_unit(functional_mult_unit),
        .functional_mem_unit(functional_mem_unit),
        .functional_br_unit(functional_br_unit),
        .functional_div_unit(functional_div_unit),
        .arith_dispatch (arith_dispatch),
        .mult_dispatch (mult_dispatch),
        .mem_dispatch(mem_dispatch),
        .br_dispatch(br_dispatch),
        .div_dispatch(div_dispatch)
    );

    cdb cdb (
        .flush(flush),
        .alu_cdb_info(alu_cdb_info), 
        .mult_cdb_info(mult_cdb_info), 
        .mem_cdb_info(mem_cdb_info),
        .br_cdb_info(br_cdb_info),
        .div_cdb_info(div_cdb_info), //input
        .cdb_output(cdb_output),
        .unit_stall(unit_stall)
    );

    div_funct_unit div_funct_unit(
        .clk(clk),
        .rst(rst || flush),
        .start(div_dispatch),
        .functional_div_unit(functional_div_unit),
        .stall(unit_stall[0]),
        .div_cdb_info(div_cdb_info),
        .div_in_use(div_in_use)
    );

    mult_func_unit mult_func_unit(
        .clk(clk),
        .rst(rst || flush),
        .start(mult_dispatch), 
        .functional_mult_unit(functional_mult_unit),
        .stall(unit_stall[1]),
        .mult_cdb_info(mult_cdb_info),
        .mult_in_use(mult_in_use)
    );

    alu_func_unit alu_func_unit(
        .clk(clk),
        .rst(rst || flush),
        .start(arith_dispatch),
        .functional_arith_unit(functional_arith_unit),
        .stall(unit_stall[3]),
        .alu_cdb_info(alu_cdb_info)
    );

    br_func_unit br_func_unit(
        .clk(clk),
        .rst(rst || flush),
        .start(br_dispatch),
        .functional_br_unit(functional_br_unit),
        .stall(1'b0),
        .br_cdb_info(br_cdb_info)
    );

    new_mem_unit new_mem_unit(
        .clk(clk),
        .rst(rst),
        .flush(flush),
        .start(mem_dispatch),
        .functional_mem_unit(functional_mem_unit),
        .stall(unit_stall[2]),
        .ROB_commit_store(ROB_commit_store),
        .dmem_resp(dmem_resp),
        .dmem_rdata(dmem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_rmask(dmem_rmask),
        .dmem_wdata(dmem_wdata),
        .dmem_wmask(dmem_wmask),
        .mem_cdb_info(mem_cdb_info),
        .mem_in_use(mem_in_use)

    );


    cache_dfp_port_t i_cache;
    cache_dfp_port_t d_cache;
    cache_dfp_port_t arbiter;
    // cache_dfp_port_t prefetch;
    // logic icache_prefetch_available;
    // logic [255:0] prefetch_data;
    // // logic can_prefetch;

    // prefetcher prefetcher(
    //     .clk(clk),
    //     .rst(rst),
    //     .dfp_addr(prefetch.dfp_addr),
    //     .dfp_read(prefetch.dfp_read),
    //     .dfp_write(prefetch.dfp_write),
    //     .dfp_rdata(prefetch.dfp_rdata),
    //     .dfp_wdata(prefetch.dfp_wdata),
    //     .dfp_resp(prefetch.dfp_resp),
    //     .icache_read(i_cache.dfp_read),
    //     .icache_addr(i_cache.dfp_addr),
    //     .icache_prefetch_available(icache_prefetch_available),
    //     .prefetch_data(prefetch_data)
    //     // .can_prefetch(can_prefetch)
    // );


    icache icache(
        .clk(clk),
        .rst(rst),
        .ufp_addr(imem_addr),
        .ufp_rmask(imem_rmask),
        .ufp_wmask(4'b0),
        .ufp_rdata(imem_rdata),
        // .ufp_wdata('0),
        .ufp_resp(imem_resp),
        .dfp_addr(i_cache.dfp_addr),
        .dfp_read(i_cache.dfp_read),
        .dfp_write(i_cache.dfp_write),
        .dfp_rdata(i_cache.dfp_rdata),
        .dfp_wdata(i_cache.dfp_wdata),
        .dfp_resp(i_cache.dfp_resp)
    );

    dcache dcache(
        .clk(clk),
        .rst(rst),
        .ufp_addr(dmem_addr),
        .ufp_rmask(dmem_rmask),
        .ufp_wmask(dmem_wmask),
        .ufp_rdata(dmem_rdata),
        .ufp_wdata(dmem_wdata),
        .ufp_resp(dmem_resp),
        .dfp_addr(d_cache.dfp_addr),
        .dfp_read(d_cache.dfp_read),
        .dfp_write(d_cache.dfp_write),
        .dfp_rdata(d_cache.dfp_rdata),
        .dfp_wdata(d_cache.dfp_wdata),
        .dfp_resp(d_cache.dfp_resp)
    );


    cache_arbiter cache_arbiter(
        .clk(clk),
        .rst(rst),

        .icache_ufp_addr(i_cache.dfp_addr),
        .icache_ufp_read(i_cache.dfp_read),
        .icache_ufp_write(i_cache.dfp_write),
        .icache_ufp_rdata(i_cache.dfp_rdata),
        .icache_ufp_wdata(i_cache.dfp_wdata),
        .icache_ufp_resp(i_cache.dfp_resp),

        .dcache_ufp_addr(d_cache.dfp_addr),
        .dcache_ufp_read(d_cache.dfp_read),
        .dcache_ufp_write(d_cache.dfp_write),
        .dcache_ufp_rdata(d_cache.dfp_rdata),
        .dcache_ufp_wdata(d_cache.dfp_wdata),
        .dcache_ufp_resp(d_cache.dfp_resp),

        // .prefetch_ufp_addr(prefetch.dfp_addr),
        // .prefetch_ufp_read(prefetch.dfp_read),
        // .prefetch_ufp_write(prefetch.dfp_write),
        // .prefetch_ufp_rdata(prefetch.dfp_rdata),
        // .prefetch_ufp_wdata(prefetch.dfp_wdata),
        // .prefetch_ufp_resp(prefetch.dfp_resp),

        .dfp_addr(arbiter.dfp_addr), 
        .dfp_read(arbiter.dfp_read), 
        .dfp_write(arbiter.dfp_write),
        .dfp_rdata(arbiter.dfp_rdata), 
        .dfp_wdata(arbiter.dfp_wdata), 
        .dfp_resp(arbiter.dfp_resp)

        // .icache_prefetch_available(icache_prefetch_available),
        // .prefetch_data(prefetch_data)
        // .can_prefetch(can_prefetch)
    );

    cacheline_adaptor cacheline_adaptor(
        .clk(clk),
        .rst(rst),

        .ufp_addr(arbiter.dfp_addr),   //bmem_raddr?   
        .ufp_read(arbiter.dfp_read),       
        .ufp_write(arbiter.dfp_write),
        .ufp_rdata(arbiter.dfp_rdata),
        .ufp_wdata(arbiter.dfp_wdata),
        .ufp_resp(arbiter.dfp_resp), 

        .dfp_addr(bmem_addr), 
        .dfp_read(bmem_read), 
        .dfp_write(bmem_write),
        .dfp_rdata(bmem_rdata),
        .dfp_wdata(bmem_wdata),
        .dfp_resp(bmem_rvalid)       //or bmem_ready?                  //check this
    );

logic useless_currently;
always_comb begin
    useless_currently = |bmem_raddr && bmem_ready;
end

endmodule : cpu
