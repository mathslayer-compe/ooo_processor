module alu_func_unit
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic start,
    input functional_unit_t functional_arith_unit,
    input logic stall,
    output cdb_output_t alu_cdb_info
);

    logic br_en;
    logic [31:0] alu_out;
    logic start_ff;
    functional_unit_t functional_arith_unit_ff;

    always_ff @(posedge clk) begin
        if(rst) begin
            start_ff <= 1'b0;
            functional_arith_unit_ff <= '0;
        end
        else if(start && !stall) begin
            start_ff <= start;
            functional_arith_unit_ff <= functional_arith_unit;
        end
        else if(!stall) begin
            start_ff <= '0;
        end
    end



    alu arith_logic_unit (
        .aluop(functional_arith_unit_ff.fuop),
        .a(functional_arith_unit_ff.rs1_v), 
        .b(functional_arith_unit_ff.ALUsrc ? functional_arith_unit_ff.sext_imm : functional_arith_unit_ff.rs2_v),
        .f(alu_out)
    );

    comparator comparator_i (
        .cmpop(functional_arith_unit_ff.fuop),
        .a(functional_arith_unit_ff.rs1_v),
        .b(functional_arith_unit_ff.ALUsrc ? functional_arith_unit_ff.sext_imm : functional_arith_unit_ff.rs2_v),
        .br_en(br_en)
    );

    always_ff @(posedge clk) begin
        if(rst) begin
            alu_cdb_info <= '0;
        end
        else if(start_ff && !stall)begin
            alu_cdb_info.valid <= 1'b1;
            alu_cdb_info.ROB_id <= functional_arith_unit_ff.robIndex;
            alu_cdb_info.commit_phys_rd_addr <= functional_arith_unit_ff.rd_s;
            alu_cdb_info.commit_arch_rd_addr <= functional_arith_unit_ff.inst[11:7];
            unique case(functional_arith_unit_ff.opcode) //opcode
                op_b_lui    : begin //U type
                    alu_cdb_info.data <= alu_out;
                end
                op_b_auipc    : begin //U type
                    alu_cdb_info.data <= functional_arith_unit_ff.pc + functional_arith_unit_ff.sext_imm;
                end
                op_b_imm   : begin // arith ops with register/immediate operands (I type)
                    unique case (functional_arith_unit_ff.funct3)
                        slt, sltu: begin
                            alu_cdb_info.data <= {31'd0, br_en};
                        end
                        default: begin
                            alu_cdb_info.data <= alu_out;
                        end
                    endcase
                end
                op_b_reg  : begin // arith ops with register operands (R type)
                    unique case (functional_arith_unit_ff.funct3)
                        slt, sltu: begin
                            alu_cdb_info.data <= {31'd0, br_en};
                        end
                        default: begin
                            alu_cdb_info.data <= alu_out;
                        end
                    endcase
                end
                default  : begin
                    alu_cdb_info.data <= '0;
                end
            endcase 
        end
        else if(!stall) begin
            alu_cdb_info <= '0;
        end
    end

endmodule : alu_func_unit