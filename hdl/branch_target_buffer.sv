module branch_target_buffer
import module_types::*;
(
    input logic clk,
    input logic rst,

    input   logic [31:0]    inst_pc,
    output  logic [31:0]    pred_target_addr,
    output  logic read_hit,

    input   logic w_en,
    input   logic [31:0] commit_pc,
    input   logic [31:0] actual_target_addr
);
    
    logic [BTB_SET_IDX-1:0] read_set_idx;
    logic [BTB_TAG_SIZE-1:0] read_tag;
    logic [BTB_SET_IDX-1:0] read_set_idx_ff;
    logic [BTB_TAG_SIZE-1:0] read_tag_ff;
    logic valid_bit;

    logic [BTB_SET_IDX-1:0] write_set_idx;
    logic [BTB_TAG_SIZE-1:0] write_tag;

    logic BTB_valid_array[BTB_HEIGHT];
    BTB_read_t BTB_read_data;

    assign read_set_idx = inst_pc[2+:BTB_SET_IDX];
    assign read_tag = inst_pc[BTB_SET_IDX+2+:BTB_TAG_SIZE];
    assign write_set_idx = commit_pc[2+:BTB_SET_IDX];
    assign write_tag = commit_pc[BTB_SET_IDX+2+:BTB_TAG_SIZE];

    btb_array btb_array (
        //WRITE PORTS
        .clk0(clk), // clock
        .csb0(!w_en), // active low chip select
        .addr0(write_set_idx),
        .din0({write_tag, actual_target_addr}),
        //READ PORTS
        .clk1(clk), // clock
        .csb1(1'b0), // active low chip select
        .addr1(read_set_idx),
        .dout1({BTB_read_data.tag, BTB_read_data.target_addr})
    );


    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < BTB_HEIGHT; i++) begin
                BTB_valid_array[i] <= 1'b0;
            end
            read_set_idx_ff <= '0;
            read_tag_ff <= '0;
        end else begin
            if (w_en) begin
                BTB_valid_array[write_set_idx] <= 1'b1;
            end
            read_set_idx_ff <= read_set_idx;
            read_tag_ff <= read_tag;
        end
    end

    always_comb begin
        valid_bit = BTB_valid_array[read_set_idx_ff] ;
    end

    always_comb begin : read
        read_hit = 1'b0;
        pred_target_addr = '0;
        if((read_tag_ff == BTB_read_data.tag) && valid_bit) begin
            read_hit = 1'b1;
            pred_target_addr = BTB_read_data.target_addr;
        end    
    end

endmodule
