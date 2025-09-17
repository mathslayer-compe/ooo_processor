module reorder_buffer
import module_types::*;
import rv32i_types::*;
(
    input   logic                   clk,
    input   logic                   rst,
    input   logic                   r_en,
    output  rob_entry_t             r_data,
    input   cdb_output_t            cdb_rob_input,
    input   decoded_output_t        decoded_output,
    input   logic                   w_en,
    input   rob_entry_t             w_data,
    output   RVFI_signals_t         rvfi_signals,
    input   logic                   arith_dispatch,
    input   logic                   mult_dispatch,
    input   logic                   mem_dispatch,
    input   logic                   br_dispatch,
    input logic div_dispatch,
    input   functional_unit_t       arith_res_station_reg,
    input   functional_unit_t       mult_res_station_reg,
    input   functional_unit_t       mem_res_station_reg,
    input   functional_unit_t       br_res_station_reg,
    input functional_unit_t div_res_station_reg,
    output  [ROB_IDX_SIZE-1:0]      allocated_ROB_ID,
    output  logic                   full_sig,
    output  logic                   empty_sig,
    output  logic                   commit_sig,
    output  logic                   commit_store_sig,
    output  logic                   flush,
    output  logic [31:0]            pc_flush,
    output  logic                   update_btb,
    output  logic                   update_br,
    output  logic [31:0]            commit_pc,
    output  logic [31:0]            commit_pc_next,
    output  logic                   br_taken


);

    rob_entry_t                 rob_array[ROB_DEPTH];
    logic   [ROB_ADDR_WIDTH:0]      head_ptr, tail_ptr; //extra bit for overflow
    logic ready_to_commit;
    logic [63:0] order;

    //debug signals
    logic [31:0] branches;
    logic [31:0] miss_preds;

    assign full_sig = (head_ptr[ROB_ADDR_WIDTH-1:0] == tail_ptr[ROB_ADDR_WIDTH-1:0]) && (head_ptr[ROB_ADDR_WIDTH] != tail_ptr[ROB_ADDR_WIDTH]);
    assign empty_sig = (head_ptr[ROB_ADDR_WIDTH-1:0] == tail_ptr[ROB_ADDR_WIDTH-1:0]) && (head_ptr[ROB_ADDR_WIDTH] == tail_ptr[ROB_ADDR_WIDTH]);
    assign allocated_ROB_ID = tail_ptr[ROB_ADDR_WIDTH-1:0];

    assign ready_to_commit = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].ready;
    assign commit_store_sig = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].store_inst;

    always_ff @( posedge clk ) begin : manage_queue
        if(rst) begin
            branches <= '0;
            miss_preds <= '0;
            flush <= '0;
            pc_flush <= '0;
            update_btb <= '0; 
            update_br <= '0;
            commit_pc <= '0;
            commit_pc_next <= '0;
            br_taken <= '0;
            head_ptr <= '0;
            tail_ptr <= '0;
            order <= 64'h0;
            for(int unsigned i = 0; i < ROB_DEPTH; i++) begin
                rob_array[i] <= '0;
            end
        end
        else begin
            flush <= '0;
            pc_flush <= '0;
            if(w_en && ~full_sig) begin
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rd_addr <=  w_data.rd_addr;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].ready <=  w_data.ready;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].phys_addr <=  w_data.phys_addr;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].store_inst <= (decoded_output.opcode == op_b_store);
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].control_inst <= (decoded_output.opcode == op_b_jal || decoded_output.opcode == op_b_jalr || decoded_output.opcode == op_b_br );
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].br_inst <= (decoded_output.opcode == op_b_br);
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].pc <= decoded_output.pc;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.inst <= decoded_output.inst ;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs1_addr <= decoded_output.rs1_addr;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs2_addr <= decoded_output.rs2_addr;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rd_addr <= decoded_output.rd_addr;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.pc_rdata <= decoded_output.pc;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.pc_wdata <= decoded_output.pc_next; 
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_addr <= '0;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_rmask <= '0;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_wmask <= '0;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_rdata <= '0;
                rob_array[tail_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_wdata <= '0;
                tail_ptr <= tail_ptr+1'b1;
            end
            if(cdb_rob_input.valid && ~empty_sig) begin
                rob_array[cdb_rob_input.ROB_id].ready <=  1'b1;
                rob_array[cdb_rob_input.ROB_id].br_miss <= cdb_rob_input.br_miss;
                rob_array[cdb_rob_input.ROB_id].taken <= cdb_rob_input.br_en;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.rd_wdata <= cdb_rob_input.data;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.mem_addr <= cdb_rob_input.mem_addr;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.mem_rmask <= cdb_rob_input.mem_rmask;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.mem_wmask <= cdb_rob_input.mem_wmask;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.mem_wdata <= cdb_rob_input.mem_wdata;
                rob_array[cdb_rob_input.ROB_id].rvfi_signals.mem_rdata <= (|cdb_rob_input.mem_rmask) ? cdb_rob_input.mem_rdata : '0;
                
                if(rob_array[cdb_rob_input.ROB_id].control_inst) begin
                    rob_array[cdb_rob_input.ROB_id].rvfi_signals.pc_wdata <= cdb_rob_input.pc_next;
                    rob_array[cdb_rob_input.ROB_id].pc_next <= cdb_rob_input.pc_next;
                end
                
            end
            if(arith_dispatch) begin
                rob_array[arith_res_station_reg.robIndex].rvfi_signals.rs1_rdata <= arith_res_station_reg.rs1_v;
                rob_array[arith_res_station_reg.robIndex].rvfi_signals.rs2_rdata <= arith_res_station_reg.rs2_v;
            end
            if(mult_dispatch) begin
                rob_array[mult_res_station_reg.robIndex].rvfi_signals.rs1_rdata <= mult_res_station_reg.rs1_v;
                rob_array[mult_res_station_reg.robIndex].rvfi_signals.rs2_rdata <= mult_res_station_reg.rs2_v;
            end
            if(mem_dispatch) begin
                rob_array[mem_res_station_reg.robIndex].rvfi_signals.rs1_rdata <= mem_res_station_reg.rs1_v;
                rob_array[mem_res_station_reg.robIndex].rvfi_signals.rs2_rdata <= mem_res_station_reg.rs2_v;
            end
            if(br_dispatch) begin
                rob_array[br_res_station_reg.robIndex].rvfi_signals.rs1_rdata <= br_res_station_reg.rs1_v;
                rob_array[br_res_station_reg.robIndex].rvfi_signals.rs2_rdata <= br_res_station_reg.rs2_v;
            end
            if(div_dispatch) begin
                rob_array[div_res_station_reg.robIndex].rvfi_signals.rs1_rdata <= div_res_station_reg.rs1_v;
                rob_array[div_res_station_reg.robIndex].rvfi_signals.rs2_rdata <= div_res_station_reg.rs2_v;
            end
            if(r_en && ready_to_commit && ~empty_sig) begin
                order <= order + 64'h1;
                flush <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].br_miss; 
                // branches <= branches+ rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].control_inst; 
                // miss_preds <= miss_preds+ rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].br_miss;
                update_btb <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].control_inst; //TODO comment out this line
                update_br <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].br_inst; 
                commit_pc <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].pc; 
                commit_pc_next <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].pc_next; //TODO comment out this line 
                br_taken <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].taken; 
                if(rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].br_miss) begin 
                    pc_flush <= rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].pc_next;
                    head_ptr <= '0;
                    tail_ptr <= '0;
                    for(int unsigned i = 0; i < ROB_DEPTH; i++) begin
                        rob_array[i] <= '0; 
                    end
                end
                else begin
                    head_ptr <= head_ptr+1'b1;
                    rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]] <= '0; 
                end
            end
        end
    end


    always_comb begin
        if(rst) begin
            commit_sig = '0; 
            r_data = '0; 
            rvfi_signals = '0;
        end
        else if(r_en && ready_to_commit && ~empty_sig) begin
            commit_sig = 1'b1;
            r_data = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]];
            rvfi_signals.valid = 1'b1;
            rvfi_signals.order = order;
            rvfi_signals.inst = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.inst;
            rvfi_signals.rs1_addr = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs1_addr;
            rvfi_signals.rs2_addr = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs2_addr;
            rvfi_signals.rs1_rdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs1_rdata;
            rvfi_signals.rs2_rdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rs2_rdata;
            rvfi_signals.rd_addr = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rd_addr;
            rvfi_signals.rd_wdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.rd_wdata;
            rvfi_signals.pc_rdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.pc_rdata;
            rvfi_signals.pc_wdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.pc_wdata;
            rvfi_signals.mem_addr = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_addr;
            rvfi_signals.mem_rmask = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_rmask;
            rvfi_signals.mem_wmask = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_wmask;
            rvfi_signals.mem_rdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_rdata;
            rvfi_signals.mem_wdata = rob_array[head_ptr[ROB_ADDR_WIDTH-1:0]].rvfi_signals.mem_wdata;
        end
        else begin
            commit_sig = '0; 
            r_data = '0; 
            rvfi_signals = '0;
        end
    end

endmodule : reorder_buffer
