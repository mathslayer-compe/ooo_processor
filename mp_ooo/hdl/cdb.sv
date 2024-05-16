module cdb
import module_types::*;
#(
    parameter D_WIDTH = 32
)(
    input logic flush,
    input cdb_output_t alu_cdb_info, 
    input cdb_output_t mult_cdb_info, 
    input cdb_output_t mem_cdb_info,
    input cdb_output_t br_cdb_info,
    input cdb_output_t div_cdb_info,
    output cdb_output_t cdb_output,
    output logic [3:0] unit_stall
);

    always_comb begin
        cdb_output = '0;
        unit_stall = '0;
        if(!flush) begin
            if(br_cdb_info.valid) begin
            cdb_output.data = br_cdb_info.data;
            cdb_output.valid = br_cdb_info.valid;
            cdb_output.commit_phys_rd_addr = br_cdb_info.commit_phys_rd_addr;
            cdb_output.commit_arch_rd_addr = br_cdb_info.commit_arch_rd_addr;
            cdb_output.ROB_id = br_cdb_info.ROB_id;
            cdb_output.pc_next = br_cdb_info.pc_next;
            cdb_output.br_miss = br_cdb_info.br_miss;
            cdb_output.br_en = br_cdb_info.br_en;
            unit_stall[0] = div_cdb_info.valid;
            unit_stall[1] = mult_cdb_info.valid;
            unit_stall[2] = mem_cdb_info.valid;
            unit_stall[3] = alu_cdb_info.valid;
            end
            else if(div_cdb_info.valid) begin
                cdb_output.data = div_cdb_info.data;
                cdb_output.valid = div_cdb_info.valid;
                cdb_output.commit_phys_rd_addr = div_cdb_info.commit_phys_rd_addr;
                cdb_output.commit_arch_rd_addr = div_cdb_info.commit_arch_rd_addr;
                cdb_output.ROB_id = div_cdb_info.ROB_id;
                unit_stall[1] = mult_cdb_info.valid;
                unit_stall[2] = mem_cdb_info.valid;
                unit_stall[3] = alu_cdb_info.valid;
            end
            else if(mult_cdb_info.valid) begin //prioritizing mult
                cdb_output.data = mult_cdb_info.data;
                cdb_output.valid = mult_cdb_info.valid;
                cdb_output.commit_phys_rd_addr = mult_cdb_info.commit_phys_rd_addr;
                cdb_output.commit_arch_rd_addr = mult_cdb_info.commit_arch_rd_addr;
                cdb_output.ROB_id = mult_cdb_info.ROB_id;
                unit_stall[2] = mem_cdb_info.valid;
                unit_stall[3] = alu_cdb_info.valid;
            end
            else if(mem_cdb_info.valid) begin
                cdb_output.data = mem_cdb_info.data;
                cdb_output.valid = mem_cdb_info.valid;
                cdb_output.commit_phys_rd_addr = mem_cdb_info.commit_phys_rd_addr;
                cdb_output.commit_arch_rd_addr = mem_cdb_info.commit_arch_rd_addr;
                cdb_output.ROB_id = mem_cdb_info.ROB_id;
                cdb_output.mem_addr = mem_cdb_info.mem_addr;
                cdb_output.mem_rmask = mem_cdb_info.mem_rmask;
                cdb_output.mem_wmask = mem_cdb_info.mem_wmask;
                cdb_output.mem_wdata = mem_cdb_info.mem_wdata;
                cdb_output.mem_rdata = mem_cdb_info.mem_rdata;
                unit_stall[3] = alu_cdb_info.valid;
            end
            else if(alu_cdb_info.valid) begin
                cdb_output.data = alu_cdb_info.data;
                cdb_output.valid = alu_cdb_info.valid;
                cdb_output.commit_phys_rd_addr = alu_cdb_info.commit_phys_rd_addr;
                cdb_output.commit_arch_rd_addr = alu_cdb_info.commit_arch_rd_addr;
                cdb_output.ROB_id = alu_cdb_info.ROB_id;
            end
        end
    end

endmodule: cdb
