
module regfile
import module_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           regf_we,
    input   logic   [31:0]  rd_v,
    input   logic   [PHYS_REG_ADDR-1:0] rd_s, 
    input   logic   [PHYS_REG_ADDR-1:0]   arith_rs1_s, arith_rs2_s,
    input   logic   [PHYS_REG_ADDR-1:0]   mult_rs1_s, mult_rs2_s,
    input   logic   [PHYS_REG_ADDR-1:0]   mem_rs1_s, mem_rs2_s,
    input   logic   [PHYS_REG_ADDR-1:0]   br_rs1_s, br_rs2_s,
    input logic [PHYS_REG_ADDR-1:0] div_rs1_s, div_rs2_s,
    output  logic   [31:0]  arith_rs1_v, arith_rs2_v,
    output  logic   [31:0]  mult_rs1_v, mult_rs2_v,
    output  logic   [31:0]  mem_rs1_v, mem_rs2_v,
    output  logic   [31:0]  br_rs1_v, br_rs2_v,
    output logic [31:0] div_rs1_v, div_rs2_v
);

    logic   [31:0]  data [PHYS_REGSIZE];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < PHYS_REGSIZE; i++) begin
                data[i] <= '0;
            end
        end else if (regf_we && (rd_s != '0)) begin
            data[rd_s] <= rd_v;
        end
    end

    always_comb begin
        arith_rs1_v = (arith_rs1_s != '0) ? data[arith_rs1_s] : '0;  
        arith_rs2_v = (arith_rs2_s != '0) ? data[arith_rs2_s] : '0;
        if (arith_rs1_s != '0 && rd_s == arith_rs1_s && regf_we) arith_rs1_v = rd_v;
        if (arith_rs2_s != '0 && rd_s == arith_rs2_s && regf_we) arith_rs2_v = rd_v;

        mult_rs1_v = (mult_rs1_s != '0) ? data[mult_rs1_s] : '0;  
        mult_rs2_v = (mult_rs2_s != '0) ? data[mult_rs2_s] : '0;
        if (mult_rs1_s != '0 && rd_s == mult_rs1_s && regf_we) mult_rs1_v = rd_v;
        if (mult_rs2_s != '0 && rd_s == mult_rs2_s && regf_we) mult_rs2_v = rd_v;

        mem_rs1_v = (mem_rs1_s != '0) ? data[mem_rs1_s] : '0;  
        mem_rs2_v = (mem_rs2_s != '0) ? data[mem_rs2_s] : '0;
        if (mem_rs1_s != '0 && rd_s == mem_rs1_s && regf_we) mem_rs1_v = rd_v;
        if (mem_rs2_s != '0 && rd_s == mem_rs2_s && regf_we) mem_rs2_v = rd_v;

        br_rs1_v = (br_rs1_s != '0) ? data[br_rs1_s] : '0;  
        br_rs2_v = (br_rs2_s != '0) ? data[br_rs2_s] : '0;
        if (br_rs1_s != '0 && rd_s == br_rs1_s && regf_we) br_rs1_v = rd_v;
        if (br_rs2_s != '0 && rd_s == br_rs2_s && regf_we) br_rs2_v = rd_v;

        div_rs1_v = (div_rs1_s != '0) ? data[div_rs1_s] : '0;
        div_rs2_v = (div_rs2_s != '0) ? data[div_rs2_s] : '0;
        if(div_rs1_s != '0 && rd_s == div_rs1_s && regf_we) div_rs1_v = rd_v;
        if(div_rs2_s != '0 && rd_s == div_rs2_s && regf_we) div_rs2_v = rd_v;
    end

endmodule : regfile
