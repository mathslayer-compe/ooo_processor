module rename
import rv32i_types::*;
import module_types::*;
(
    input rat_entry_t RAT_rs1_out,
    input rat_entry_t RAT_rs2_out,
    input logic is_empty,
    input logic [PHYS_REG_ADDR-1:0] physical_reg,
    input logic [4:0] rd,
    input logic [ROB_IDX_SIZE-1:0] allocated_ROB_ID,
    input logic ROB_full,
    output rob_entry_t rob_entry,
    output  logic [ROB_IDX_SIZE-1:0] rename_ROB_ID,
    output logic [PHYS_REG_ADDR-1:0] rs1_addr,
    output logic [PHYS_REG_ADDR-1:0] rs2_addr,
    output logic rs1_valid,
    output logic rs2_valid,
    output logic [4:0] rename_arch_addr,
    output logic rename_sig,
    output logic issue_sig
);

always_comb begin
    rob_entry = '0;
    rob_entry.phys_addr = '0;
    rob_entry.rd_addr = '0;
    rob_entry.ready = '0;
    rename_ROB_ID = '0;
    rename_sig = '0;
    issue_sig = '0;
    rs1_addr = '0;
    rs1_valid = '0;

    rs2_addr = '0;
    rs2_valid = '0;

    rename_arch_addr = '0;
    if(!is_empty && !ROB_full) begin
        rob_entry.phys_addr = physical_reg;
        rob_entry.rd_addr = rd;
        rob_entry.ready = '0;
        rename_ROB_ID = allocated_ROB_ID; // this part needs to be added to rob
        rename_sig = (rd != 5'b0);
        issue_sig = 1'b1;
        rs1_addr = RAT_rs1_out.phys_addr;
        rs1_valid = RAT_rs1_out.RAT_valid;

        rs2_addr = RAT_rs2_out.phys_addr;
        rs2_valid = RAT_rs2_out.RAT_valid;

        rename_arch_addr = rd;

    end
end

endmodule: rename