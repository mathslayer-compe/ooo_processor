module br_func_unit
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic start,
    input functional_unit_t functional_br_unit,
    input logic stall,
    output cdb_output_t br_cdb_info
);

    logic br_en;
    logic [31:0] alu_out;


    logic start_ff;
    functional_unit_t functional_br_unit_ff;

    bit [31:0] misses;
    bit [31:0] btb_misses;

    always_ff @(posedge clk) begin
        if(rst) begin
            start_ff <= 1'b0;
            functional_br_unit_ff <= '0;
        end
        else if(start && !stall) begin
            start_ff <= start;
            functional_br_unit_ff <= functional_br_unit;
        end
        else if(!stall) begin
            start_ff <= '0;
        end
    end

    alu arith_logic_unit (
        .aluop(functional_br_unit_ff.fuop),
        .a(functional_br_unit_ff.rs1_v), 
        .b(functional_br_unit_ff.ALUsrc ? functional_br_unit_ff.sext_imm : functional_br_unit_ff.rs2_v),
        .f(alu_out)
    );

    comparator comparator_i (
        .cmpop(functional_br_unit_ff.fuop),
        .a(functional_br_unit_ff.rs1_v),
        .b(functional_br_unit_ff.ALUsrc ? functional_br_unit_ff.sext_imm : functional_br_unit_ff.rs2_v),
        .br_en(br_en)
    );


    always_ff @(posedge clk) begin
        if(rst) begin
            br_cdb_info <= '0;
            // misses <= '0;
            // btb_misses <= '0;
        end
        else if(start_ff && !stall)begin
            br_cdb_info.valid <= 1'b1;
            br_cdb_info.ROB_id <= functional_br_unit_ff.robIndex;
            br_cdb_info.commit_phys_rd_addr <= functional_br_unit_ff.rd_s;
            br_cdb_info.commit_arch_rd_addr <= functional_br_unit_ff.inst[11:7];
            unique case(functional_br_unit_ff.opcode) //opcode
                op_b_jal   : begin // jump and link (J type)
                    br_cdb_info.data <= functional_br_unit_ff.pc + 4;
                    br_cdb_info.br_en <= 1'b1;
                    if(!functional_br_unit_ff.br_pred) begin
                        br_cdb_info.br_miss <= 1'b1; 
                        misses <= misses +1'b1;
                    end
                    br_cdb_info.pc_next <= functional_br_unit_ff.pc + functional_br_unit_ff.sext_imm;
                end
                op_b_jalr  : begin // jump and link register (I type)
                    br_cdb_info.data <= functional_br_unit_ff.pc + 4;
                    br_cdb_info.br_en <= 1'b1;
                    if(!functional_br_unit_ff.br_pred) begin
                        br_cdb_info.br_miss <= 1'b1; 
                        misses <= misses +1'b1;
                    end
                    else begin
                        br_cdb_info.br_miss <= (((functional_br_unit_ff.rs1_v + functional_br_unit_ff.sext_imm) & 32'hfffffffe )!= functional_br_unit_ff.pc_next);
                        if(((functional_br_unit_ff.rs1_v + functional_br_unit_ff.sext_imm) & 32'hfffffffe )!= functional_br_unit_ff.pc_next) begin
                            misses <= misses +1'b1;
                            btb_misses <= btb_misses+1'b1;
                        end
                    end
                    br_cdb_info.pc_next <= (functional_br_unit_ff.rs1_v + functional_br_unit_ff.sext_imm) & 32'hfffffffe;
                end
                op_b_br    : begin // branch (B type)
                    br_cdb_info.data <= functional_br_unit_ff.rs1_v + functional_br_unit_ff.rs2_v;
                    br_cdb_info.br_en <= br_en;
                    if(br_en != functional_br_unit_ff.br_pred) begin
                        br_cdb_info.br_miss <= 1'b1; 
                        misses <= misses +1'b1;
                    end
                    br_cdb_info.pc_next <= br_en ? (functional_br_unit_ff.pc + functional_br_unit_ff.sext_imm) : (functional_br_unit_ff.pc + 4);
                end
                default  : begin
                    br_cdb_info <= '0;
                end
            endcase 
        end
        else if(!stall) begin
            br_cdb_info <= '0;
        end 
    end


endmodule : br_func_unit