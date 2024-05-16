module freeList
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic r_en,
    input logic [PHYS_REG_ADDR-1:0] freed_physical_reg,
    input logic w_en,
    input logic flush,
    output logic [PHYS_REG_ADDR-1:0]  physical_reg,
    output logic is_empty
);

    logic   [PHYS_REG_ADDR-1:0]   d_array[HALF_PHYS_REGSIZE];
    logic   [HALF_PHYS_REG_ADDR:0]       read_ptr, write_ptr; //extra bit for overflow

    assign is_empty = (read_ptr[HALF_PHYS_REG_ADDR-1:0] == write_ptr[HALF_PHYS_REG_ADDR-1:0]) && (read_ptr[HALF_PHYS_REG_ADDR] == write_ptr[HALF_PHYS_REG_ADDR]);

    always_ff @( posedge clk ) begin : manage_queue
        if(rst) begin
            read_ptr <= {1'b1, {5{1'b0}}};
            write_ptr <= '0;
            for(int unsigned i = 0; i < HALF_PHYS_REGSIZE; i++) begin 
                d_array[i] <= 6'(i) + 6'd32;
            end
        end
        else if(flush) begin
            read_ptr <= {1'b1, {5{1'b0}}};
            write_ptr <= '0;
        end
        else begin
            if(w_en && freed_physical_reg != '0) begin
                d_array[write_ptr[HALF_PHYS_REG_ADDR-1:0]] <= freed_physical_reg;
                write_ptr <= write_ptr+1'b1;
            end
            if(r_en && ~is_empty) begin
                read_ptr <= read_ptr+1'b1;
            end
        end
    end

    always_comb begin
        if(rst) begin
            physical_reg = '0;
        end
        else if(r_en && ~is_empty) begin
            physical_reg = d_array[read_ptr[HALF_PHYS_REG_ADDR-1:0]];
        end
        else begin
            physical_reg = '0;
        end
    end

endmodule : freeList