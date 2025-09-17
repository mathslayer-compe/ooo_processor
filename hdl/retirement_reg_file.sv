module RRF
import module_types::*;
(
    input   logic       clk,
    input   logic       rst,
    output  logic [PHYS_REG_ADDR-1:0] RRF_state[32],
    input   logic [4:0]       r_addr,
    output  logic [PHYS_REG_ADDR-1:0] r_data,
    input   logic               w_en,
    input   logic [4:0]         w_addr,
    input   [PHYS_REG_ADDR-1:0] w_data
);

    logic [PHYS_REG_ADDR-1:0] RRF_array[HALF_PHYS_REGSIZE];

    always_ff @( posedge clk ) begin
        if(rst) begin
            for(int unsigned i = 0; i < HALF_PHYS_REGSIZE; i++) begin
                RRF_array[i] <= 6'(i);
            end
        end
        else begin
            if(w_en && w_addr != 5'b0) begin //writing register mapping
                RRF_array[w_addr] <= w_data;
            end
        end
    end

    always_comb begin
        r_data = RRF_array[r_addr]; //old physical register index
        for(int i = 0; i < HALF_PHYS_REGSIZE; i++) begin
            RRF_state[i] = RRF_array[i];
        end
    end
    
endmodule