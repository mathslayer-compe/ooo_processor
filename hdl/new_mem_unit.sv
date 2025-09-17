module new_mem_unit
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic flush,
    input logic start,
    input functional_unit_t functional_mem_unit,
    input logic stall,
    input logic ROB_commit_store,

    input   logic           dmem_resp,
    input   logic   [31:0]  dmem_rdata,
    
    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [31:0]  dmem_wdata,
    output  logic   [3:0]   dmem_wmask,

    output  cdb_output_t    mem_cdb_info,
    output  logic           mem_in_use

);

    logic [31:0] alu_out;
    logic start_ff;
    functional_unit_t functional_mem_unit_ff;


    always_ff @(posedge clk) begin
        if(rst || flush) begin
            start_ff <= 1'b0;
            functional_mem_unit_ff <= '0;
        end
        else if(start && !stall) begin
            start_ff <= start;
            functional_mem_unit_ff <= functional_mem_unit;
        end
        else if(!stall) begin
            start_ff <= '0;
            // functional_mem_unit_ff <= '0;TODO: come back to this and make a decision
        end
    end

    alu arith_logic_unit (
        .aluop(functional_mem_unit_ff.fuop),
        .a(functional_mem_unit_ff.rs1_v), 
        .b(functional_mem_unit_ff.ALUsrc ? functional_mem_unit_ff.sext_imm : functional_mem_unit_ff.rs2_v),
        .f(alu_out)
    );

    logic [3:0]     mem_write, mem_write_ff; //writing to memory
    logic [3:0]     mem_read, mem_read_ff; //reading from memory
    logic [31:0]    mem_addr, mem_addr_ff;
    logic [31:0]    mem_wdata, mem_wdata_ff;
    logic [31:0]    mem_rdata, mem_rdata_ff;


    enum int unsigned {  
        START, ADDR_CALC, LOAD_1, LOAD_2, STORE_1, STORE_2, STORE_3, WAIT_ON_RESP
    } curr_state, next_state;


    always_ff @(posedge clk) begin
        if(rst) begin
            curr_state <= START;
            mem_write_ff <= '0;
            mem_read_ff <= '0;
            mem_addr_ff <= '0;
            mem_wdata_ff <= '0;
        end 
        else begin
            curr_state <= next_state;
            mem_write_ff <= mem_write;
            mem_read_ff <= mem_read;
            mem_addr_ff <= mem_addr;
            mem_wdata_ff <= mem_wdata;
            mem_rdata_ff <= mem_rdata;
        end
    end

    always_comb begin
        dmem_addr = '0;
        dmem_rmask = '0;
        dmem_wdata = '0;
        dmem_wmask = '0;
        mem_cdb_info = '0;
        mem_write = mem_write_ff;
        mem_read = mem_read_ff;
        mem_addr = mem_addr_ff;
        mem_wdata = mem_wdata_ff;
        mem_rdata = mem_rdata_ff;
        mem_in_use = 1'b1;
        next_state = curr_state;


        unique case(curr_state)
            START: begin
                mem_in_use = '0;
                mem_write = '0;
                mem_read = '0;
                mem_addr = '0;
                mem_wdata = '0;
                mem_rdata = '0;
                if(start_ff && !flush) begin
                    next_state = ADDR_CALC;
                    mem_in_use = 1'b1;
                end
            end
            ADDR_CALC: begin
                if(flush) begin
                    next_state = START;
                end
                else begin
                    mem_addr = alu_out;
                    if(functional_mem_unit_ff.opcode == op_b_load) begin
                        next_state = LOAD_1;
                        unique case (functional_mem_unit_ff.funct3)
                            lb, lbu: mem_read = 4'b0001 << mem_addr[1:0];
                            lh, lhu: mem_read = 4'b0011 << mem_addr[1:0];
                            lw:      mem_read = 4'b1111;
                            default: mem_read = '0;
                        endcase
                    end
                    else if(functional_mem_unit_ff.opcode == op_b_store) begin
                        next_state = STORE_1;
                        unique case (functional_mem_unit_ff.funct3)
                            sb: mem_write = 4'b0001 << mem_addr[1:0];
                            sh: mem_write = 4'b0011 << mem_addr[1:0];
                            sw: mem_write = 4'b1111;
                            default: mem_write = '0;
                        endcase
                    end
                end
            end
            LOAD_1: begin
                dmem_addr = {mem_addr[31:2], 2'b00};
                dmem_rmask = mem_read;
                if(flush) begin
                    next_state = WAIT_ON_RESP;
                end
                else if(dmem_resp) begin
                    next_state = LOAD_2;
                    mem_rdata = dmem_rdata;
                end
            end
            LOAD_2: begin
                if(flush) begin
                    next_state = START;
                end
                else begin
                    if(!stall) begin
                        next_state = START;
                    end
                    unique case (functional_mem_unit_ff.funct3)
                            lb : mem_cdb_info.data = {{24{mem_rdata[7 +8 *mem_addr[1:0]]}}, mem_rdata[8 *mem_addr[1:0] +: 8 ]};
                            lbu: mem_cdb_info.data = {{24{1'b0}}                          , mem_rdata[8 *mem_addr[1:0] +: 8 ]};
                            lh : mem_cdb_info.data = {{16{mem_rdata[15+16*mem_addr[1]  ]}}, mem_rdata[16*mem_addr[1]   +: 16]};
                            lhu: mem_cdb_info.data = {{16{1'b0}}                          , mem_rdata[16*mem_addr[1]   +: 16]};
                            lw : mem_cdb_info.data = mem_rdata;
                            default: mem_cdb_info.data = 32'b0;
                    endcase
                    mem_cdb_info.valid = 1'b1;
                    mem_cdb_info.ROB_id = functional_mem_unit_ff.robIndex;
                    mem_cdb_info.commit_phys_rd_addr = functional_mem_unit_ff.rd_s;
                    mem_cdb_info.commit_arch_rd_addr = functional_mem_unit_ff.inst[11:7];
                    mem_cdb_info.mem_addr = mem_addr;
                    mem_cdb_info.mem_rmask = mem_read;
                    mem_cdb_info.mem_wmask = '0;
                    mem_cdb_info.mem_wdata = '0;
                    mem_cdb_info.mem_rdata = mem_rdata;
                end
            end
            STORE_1: begin
                if(flush) begin
                    next_state = START;
                end
                else begin
                    unique case (functional_mem_unit_ff.funct3)
                        sb: mem_wdata[8 *mem_addr[1:0] +: 8 ] = functional_mem_unit_ff.rs2_v[7 :0];
                        sh: mem_wdata[16*mem_addr[1]   +: 16] = functional_mem_unit_ff.rs2_v[15:0];
                        sw: mem_wdata = functional_mem_unit_ff.rs2_v;
                        default: mem_wdata = 32'b0;
                    endcase
                    
                    if(ROB_commit_store) begin 
                        dmem_addr  = {mem_addr[31:2], 2'b00};
                        dmem_wdata  = mem_wdata;
                        dmem_wmask  = mem_write;
                        dmem_rmask = '0;
                        next_state = STORE_2;
                    end
                end
            end
            STORE_2: begin
                dmem_addr  = {mem_addr[31:2], 2'b00};
                dmem_wdata  = mem_wdata;
                dmem_wmask  = mem_write;
                dmem_rmask = '0;
                if(flush) begin
                    next_state = WAIT_ON_RESP;
                end
                else if(dmem_resp) begin
                    next_state = STORE_3;
                end
            end
            STORE_3: begin
                if(flush) begin
                    next_state = START;
                end
                else begin
                    if(!stall) begin
                        next_state = START;
                    end
                    mem_cdb_info.data = '0;
                    mem_cdb_info.valid = 1'b1;
                    mem_cdb_info.ROB_id = functional_mem_unit_ff.robIndex;
                    mem_cdb_info.commit_phys_rd_addr = functional_mem_unit_ff.rd_s;
                    mem_cdb_info.commit_arch_rd_addr = '0;
                    mem_cdb_info.mem_addr = mem_addr;
                    mem_cdb_info.mem_rmask = '0;
                    mem_cdb_info.mem_wmask = mem_write;
                    mem_cdb_info.mem_wdata = mem_wdata;
                    mem_cdb_info.mem_rdata = '0;    
                end            
            end
            WAIT_ON_RESP: begin
                dmem_addr = {mem_addr[31:2], 2'b00};
                dmem_rmask = mem_read;
                dmem_wdata  = mem_wdata;
                dmem_wmask  = mem_write;
                if(dmem_resp) begin
                   next_state = START;
                end
            end
            default: begin
            end

        endcase
    end

endmodule: new_mem_unit



//start state empty and waiting for request
//calcaulate address
//load state - wait for dmem_resp
//store state - wait in here until ROB_commit_store
//2nd store state - wait for dmem_resp