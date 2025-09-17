module RAT
import module_types::*;
(
    input   logic       clk,
    input   logic       rst,
    input   logic       flush,
    input   [PHYS_REG_ADDR-1:0] RRF_state[32],
    input   logic [4:0] rs1_addr,
    input   logic [4:0] rs2_addr,
    output  rat_entry_t rs1_data,
    output  rat_entry_t rs2_data,
    input   logic       rename_w_en,
    input   logic       CDB_w_en,
    input   logic [4:0]  CDB_reg_addr,
    input   logic [PHYS_REG_ADDR-1:0] CDB_phys_addr,
    input   logic [4:0]  rename_reg_addr,
    input   [PHYS_REG_ADDR-1:0]   w_data
);

    rat_entry_t RAT_array[HALF_PHYS_REGSIZE];

    always_ff @( posedge clk ) begin
        if(rst) begin
            for(int unsigned i = 0; i < HALF_PHYS_REGSIZE; i++) begin
                RAT_array[i].RAT_valid <= 1'b1;
                RAT_array[i].phys_addr <= i;
            end
        end
        else if(flush) begin
            for(int i = 1; i < HALF_PHYS_REGSIZE; i++) begin
                RAT_array[i].phys_addr <=  RRF_state[i];
                RAT_array[i].RAT_valid <= 1'b1;
            end
        end
        else begin
            if(CDB_w_en && (CDB_phys_addr == RAT_array[CDB_reg_addr].phys_addr) ) begin
                RAT_array[CDB_reg_addr].RAT_valid <= 1'b1;
            end
            if(rename_w_en && rename_reg_addr != 5'b0) begin
                RAT_array[rename_reg_addr].RAT_valid <= 1'b0;
                RAT_array[rename_reg_addr].phys_addr <= w_data; //if rename_reg_addr == 0, w_data == 0
            end
        end
    end

    always_comb begin
        rs1_data = RAT_array[rs1_addr];
        rs2_data = RAT_array[rs2_addr];
    end

endmodule