module decoder 
import rv32i_types::*;
import module_types::*;
(
    input   logic                   rst,
    input   logic                   br_pred,
    input   logic   [31:0]          inst,
    input   logic   [31:0]          pc_next,
    input   logic   [31:0]          pc,

    output  decoded_output_t        decoded_output
);
    //opcode 7 bits
    //rd_addr 5 bits

    always_comb begin
        if(rst) begin
            decoded_output = '0;
        end
        else begin
            decoded_output.inst = inst;
            decoded_output.opcode = inst[6:0];
            decoded_output.rd_addr = inst[11:7];
            decoded_output.rs1_addr = inst[19:15];
            decoded_output.rs2_addr = inst[24:20];
            decoded_output.funct7  = inst[31:25]; //might not need this
            decoded_output.funct3 = inst[14:12];
            decoded_output.func_unit_sel = arith;
            decoded_output.sext_imm = '0;
            decoded_output.fuop = '0;
            decoded_output.ALUsrc = 1'b0;
            decoded_output.pc = pc;
            decoded_output.br_pred = br_pred;
            decoded_output.pc_next = pc_next;

            unique case(inst[6:0]) //opcode
                op_b_lui   : begin // load upper immediate (U type)
                    decoded_output.sext_imm =  {inst[31:12], 12'h000};  
                    decoded_output.fuop = alu_add;
                    decoded_output.func_unit_sel = arith;
                    decoded_output.ALUsrc = 1'b1;
                    decoded_output.rs1_addr = '0;
                    decoded_output.rs2_addr = '0;
                end
                op_b_auipc : begin // add upper immediate PC (U type)
                    decoded_output.sext_imm =  {inst[31:12], 12'h000};  
                    decoded_output.fuop = alu_add;
                    decoded_output.func_unit_sel = arith;
                    decoded_output.rs1_addr = '0;
                    decoded_output.rs2_addr = '0;
                end
                op_b_jal   : begin // jump and link (J type)
                    decoded_output.sext_imm =  {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0}; 
                    decoded_output.func_unit_sel = branch;
                    decoded_output.rs1_addr = '0;
                    decoded_output.rs2_addr = '0;
                end
                op_b_jalr  : begin // jump and link register (I type)
                    decoded_output.sext_imm =  {{21{inst[31]}}, inst[30:20]};   
                    decoded_output.fuop = alu_add;
                    decoded_output.func_unit_sel = branch;    
                    decoded_output.ALUsrc = 1'b1;    
                    decoded_output.rs2_addr = '0;
                end
                op_b_br    : begin // branch (B type)
                    decoded_output.sext_imm =  {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};  
                    decoded_output.fuop = decoded_output.funct3;
                    decoded_output.func_unit_sel = branch;
                    decoded_output.rd_addr = '0;
                end
                op_b_load  : begin // load (I type)
                    decoded_output.sext_imm =  {{21{inst[31]}}, inst[30:20]}; 
                    decoded_output.fuop = alu_add;  
                    decoded_output.func_unit_sel = agen; 
                    decoded_output.ALUsrc = 1'b1;
                    decoded_output.rs2_addr = '0;
                end
                op_b_store : begin // store (S type)
                    decoded_output.sext_imm =  {{21{inst[31]}}, inst[30:25], inst[11:7]};   
                    decoded_output.fuop = alu_add;  
                    decoded_output.func_unit_sel = agen;   
                    decoded_output.ALUsrc = 1'b1;
                    decoded_output.rd_addr = '0;
                end
                op_b_imm   : begin // arith ops with register/immediate operands (I type)
                    decoded_output.sext_imm =  {{21{inst[31]}}, inst[30:20]}; 
                    decoded_output.ALUsrc = 1'b1;
                    decoded_output.rs2_addr = '0;
                    unique case (decoded_output.funct3)
                        slt: begin
                            decoded_output.func_unit_sel = comp;   
                            decoded_output.fuop = blt;
                        end
                        sltu: begin
                            decoded_output.func_unit_sel = comp;   
                            decoded_output.fuop = bltu;
                        end
                        sr: begin
                            decoded_output.func_unit_sel = arith;   
                            decoded_output.fuop = decoded_output.funct7[5] ? alu_sra : alu_srl;
                        end
                        default: begin
                            decoded_output.func_unit_sel = arith;   
                            decoded_output.fuop = decoded_output.funct3;
                        end
                    endcase
                end
                op_b_reg  : begin // arith ops with register operands (R type)
                    decoded_output.sext_imm =  'x; 
                    unique case (decoded_output.funct3)
                        slt: begin //or mulhsu
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? mult : comp;   
                            decoded_output.fuop  = decoded_output.funct7[0] ? mul_su : blt;
                        end
                        sltu: begin // or mulhu
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? mult : comp;    
                            decoded_output.fuop  = decoded_output.funct7[0] ? mul_uu : bltu;
                        end
                        sr: begin //divu
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? division : arith;   
                            decoded_output.fuop  = decoded_output.funct7[0] ? divu : (decoded_output.funct7[5] ? alu_sra : alu_srl);
                        end
                        add: begin //or mul 
                            if(decoded_output.funct7[0]) begin
                                decoded_output.func_unit_sel = mult;  
                                decoded_output.fuop = mul_ss;
                            end
                            else if(decoded_output.funct7[5]) begin
                                decoded_output.func_unit_sel = arith;  
                                decoded_output.fuop  = alu_sub;
                            end
                            else begin
                                decoded_output.func_unit_sel = arith;  
                                decoded_output.fuop  = alu_add;
                            end
                        end
                        sll: begin //or mulh
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? mult : arith;   
                            decoded_output.fuop  = decoded_output.funct7[0] ? mul_ss : decoded_output.funct3;
                        end
                        axor: begin //div
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? division : arith;
                            decoded_output.fuop = decoded_output.funct7[0] ? div : decoded_output.funct3;
                        end
                        aor: begin  //rem
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? division : arith;
                            decoded_output.fuop = decoded_output.funct7[0] ? rem : decoded_output.funct3;
                        end
                        aand: begin //remu
                            decoded_output.func_unit_sel = decoded_output.funct7[0] ? division : arith;
                            decoded_output.fuop = decoded_output.funct7[0] ? remu : decoded_output.funct3;
                        end
                        default: begin
                            decoded_output.func_unit_sel = arith;  
                            decoded_output.fuop  = decoded_output.funct3;
                        end

                    endcase                        
                end
                default  : begin
                    decoded_output = 'x;
                end
            endcase
        end

    end

endmodule
