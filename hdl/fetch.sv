module fetch
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    input logic imem_resp,
    input logic [31:0] imem_rdata,
    input logic full_sig,
    input logic flush,
    input logic [31:0] pc_flush,
    input logic update_btb,
    input logic update_br,
    input logic [31:0] commit_pc,
    input logic [31:0] commit_pc_next,
    input logic br_taken,
    output logic [31:0] imem_addr,
    output logic [3:0] imem_rmask,
    output logic [31:0] pc_prev,
    output logic [31:0] pc_prev_next,
    output logic br_pred,
    output logic fetch_stall
);

    logic flush_ff;
    logic [31:0] pc_flush_ff;
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pred_target_addr, BTB_target_addr;
    logic edge_case;
    logic BTB_hit;
    logic branch_prediction;

    logic ras_empty, ras_w_en, ras_r_en;
    logic [31:0] ras_target_addr;

    always_ff @(posedge clk) begin
        if (rst) begin
            pc <= 32'h60000000;
        end
        else
            pc <= pc_next;

        if(rst) begin
            fetch_stall <= '0;
            pc_flush_ff <= '0;
        end
        else if(flush) begin
            fetch_stall <= flush;
            pc_flush_ff <= pc_flush;
        end
        else if(imem_resp) begin
            fetch_stall <= '0;
        end
    end

    always_comb begin
        pc_next = pc;
        if ( imem_resp && fetch_stall)
            pc_next = pc_flush_ff; 
        else if (imem_resp && !full_sig && !fetch_stall)
            pc_next = (br_pred) ? pred_target_addr : pc+32'd4;
    end

    assign pc_prev = pc;
    assign pc_prev_next = pc_next;
    assign imem_addr = pc_next;
    assign imem_rmask = (flush) ? 4'd0 : 4'b1111;

    always_comb begin
        ras_w_en = 1'b0;
        ras_r_en = 1'b0;
        if(imem_rdata[6:0] == op_b_br ) begin 
            br_pred = branch_prediction && BTB_hit;
            pred_target_addr = BTB_target_addr;
        end
        else if(imem_rdata[6:0] == op_b_jal) begin
            if(imem_rdata[11:7] ==  5'd1 || imem_rdata[11:7] ==  5'd5) begin //checking rs1
                ras_w_en = 1'b1; //push
            end
            br_pred = BTB_hit;
            pred_target_addr = BTB_target_addr;
        end
        else if(imem_rdata[6:0] == op_b_jalr ) begin
            if( (imem_rdata[11:7] ==  5'd1 || imem_rdata[11:7] ==  5'd5)  && (imem_rdata[11:7] == imem_rdata[19:15]))  begin //both link and rs1 == rd
                ras_w_en = 1'b1;
                br_pred = BTB_hit;
                pred_target_addr = BTB_target_addr;
            end
            else if((imem_rdata[11:7] ==  5'd1 || imem_rdata[11:7] ==  5'd5)  && (imem_rdata[19:15] ==  5'd1 || imem_rdata[19:15] ==  5'd5) && !ras_empty) begin //both link 
                ras_r_en = 1'b1;
                ras_w_en = 1'b1;
                br_pred = 1'b1;
                pred_target_addr = ras_target_addr;
            end
            else if ((imem_rdata[11:7] ==  5'd1 || imem_rdata[11:7] ==  5'd5)) begin //just rd is link
                ras_w_en = 1'b1;
                br_pred = BTB_hit;
                pred_target_addr = BTB_target_addr;
            end
            else if((imem_rdata[19:15] ==  5'd1 || imem_rdata[19:15] ==  5'd5) && !ras_empty) begin //just rs1 is link
                ras_r_en = 1'b1;
                br_pred = 1'b1;
                pred_target_addr = ras_target_addr;
            end
            else begin
                br_pred = BTB_hit;
                pred_target_addr = BTB_target_addr;
                ras_w_en = 1'b0;
                ras_r_en = 1'b0;
            end
        end
        else begin
            br_pred = 1'b0;
            pred_target_addr = '0;
            ras_w_en = 1'b0;
            ras_r_en = 1'b0;
        end
    end

    branch_predictor bp(
        .clk(clk),
        .rst(rst),
        .inst_pc(pc_next),
        .pred(branch_prediction), //take branch: 1, not taken branch: 0
        .w_en(update_br), //ROB
        .commit_pc(commit_pc), //ROB
        .taken(br_taken) //taken: 1, not taken: 0 //ROB
    );

    branch_target_buffer btb(
        .clk(clk),
        .rst(rst),
        .inst_pc(pc_next),
        .pred_target_addr(BTB_target_addr),
        .read_hit(BTB_hit),
        .w_en(br_taken && update_btb), 
        .commit_pc(commit_pc), 
        .actual_target_addr(commit_pc_next) 
    );

    stack #(  .DEPTH(2) ) ras(
        .clk(clk),
        .rst(rst || flush),
        .r_en(ras_r_en),
        .r_data(ras_target_addr),
        .w_en(ras_w_en && !fetch_stall),
        .w_data(pc+32'd4),
        .empty_sig(ras_empty)
    );


endmodule : fetch