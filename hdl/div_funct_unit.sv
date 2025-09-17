module div_funct_unit
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic start,
    input functional_unit_t functional_div_unit,
    input logic stall,
    output cdb_output_t div_cdb_info,
    output logic div_in_use
);

    logic [31:0] quotient_u, remainder_u;
    logic div_done1, div_by_0_u;
    logic done;
    logic start_ff;
    functional_unit_t functional_div_unit_ff;

    always_ff @(posedge clk) begin
        if(rst) begin
            start_ff <= 1'b0;
            functional_div_unit_ff <= '0;
        end
        else if(start && !stall) begin
            start_ff <= start;
            functional_div_unit_ff <= functional_div_unit;
        end
        else if(!stall) begin
            start_ff <= '0;
        end
    end

    DW_div_seq #(
        .a_width(32),
        .b_width(32),
        .tc_mode(0), //1 for signed
        .num_cyc(16),
        .rst_mode(1),
        .input_mode(1),
        .output_mode(1),
        .early_start(0)
        // parameters
    ) div0 (
        .clk(clk),
        .rst_n(~rst),
        .hold(~div_in_use),
        .start(start_ff), //maybe active low
        .a(functional_div_unit_ff.rs1_v),
        .b(functional_div_unit_ff.rs2_v),
        .complete(div_done1),
        .divide_by_0(div_by_0_u),
        .quotient(quotient_u),
        .remainder(remainder_u)
    );

    assign done = div_done1 && div_in_use && !start_ff;

    always_ff @(posedge clk) begin
        if(rst) begin
            div_cdb_info <= '0;
            // div_in_use <= '0;
        end
        else if(done && !stall) begin
            // div_in_use <= '0;
            div_cdb_info.valid <= done;
            div_cdb_info.ROB_id <= functional_div_unit_ff.robIndex;
            div_cdb_info.commit_phys_rd_addr <= functional_div_unit_ff.rd_s;
            div_cdb_info.commit_arch_rd_addr <= functional_div_unit_ff.inst[11:7];
            unique case(functional_div_unit_ff.funct3)
                div: div_cdb_info.data <= ~(quotient_u)-1;
                divu: div_cdb_info.data <= quotient_u;
                rem: div_cdb_info.data <= ~(remainder_u)-1;
                remu: div_cdb_info.data <= remainder_u;
                default: ;
            endcase

        end
        else if(!stall) div_cdb_info <= '0;
    end



    always_ff @(posedge clk) begin
        if(rst) begin
            div_in_use <= 1'b0;
        end
        else if(start) begin
            div_in_use <= 1'b1;
        end
        else if(done && !stall) begin
            div_in_use <= 1'b0;
        end
    end

endmodule: div_funct_unit
