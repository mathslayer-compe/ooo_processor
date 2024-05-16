module mult_func_unit
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic start,
    input functional_unit_t functional_mult_unit,
    input logic stall,
    output cdb_output_t mult_cdb_info,
    output logic mult_in_use
);

    logic [63:0] mult_out;
    logic mult_done;

    logic start_ff;
    functional_unit_t functional_mult_unit_ff;

    always_ff @(posedge clk) begin
        if(rst) begin
            start_ff <= 1'b0;
            functional_mult_unit_ff <= '0;
        end
        else if(start && !stall) begin
            start_ff <= start;
            functional_mult_unit_ff <= functional_mult_unit;
        end
        else if(!stall) begin
            start_ff <= '0;
        end
    end

    dadda_multiplier dadda(
        .clk(clk),
        .rst(rst),
        .start(start_ff),
        // .mul_type(functional_mult_unit_ff.fuop[1:0]),
        .a(functional_mult_unit_ff.rs1_v),
        .b(functional_mult_unit_ff.rs2_v),
        .p(mult_out),
        .done(mult_done)
    );

    // shift_add_multiplier multiplier(
    //     .clk(clk),
    //     .rst(rst),
    //     .start(start_ff),
    //     .mul_type(functional_mult_unit_ff.fuop[1:0]),
    //     .a(functional_mult_unit_ff.rs1_v),
    //     .b(functional_mult_unit_ff.rs2_v),
    //     .p(mult_out),
    //     .done(mult_done)
    // );

    always_ff @(posedge clk) begin
        if(rst) begin
            mult_cdb_info <= '0;
        end
        else if(mult_done && !stall) begin
            mult_cdb_info.valid <= mult_done;
            mult_cdb_info.ROB_id <= functional_mult_unit_ff.robIndex;
            mult_cdb_info.commit_phys_rd_addr <= functional_mult_unit_ff.rd_s;
            mult_cdb_info.commit_arch_rd_addr <= functional_mult_unit_ff.inst[11:7];
            unique case (functional_mult_unit_ff.funct3)
                add: mult_cdb_info.data <= mult_out[31:0]; //mul
                default: begin
                    mult_cdb_info.data <= mult_out[63:32]; //mulh, mulhu, mulhsu
                end
            endcase
        end
        else if(!stall)begin
            mult_cdb_info <= '0;
        end
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            mult_in_use <= 1'b0;
        end
        else if(start) begin
            mult_in_use <= 1'b1;
        end
        else if(mult_done && !stall) begin
            mult_in_use <= 1'b0;
        end
    end

endmodule : mult_func_unit