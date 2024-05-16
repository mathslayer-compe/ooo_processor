module store_buffer
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic store_buffer_w_en,
    input store_buf_entry_t store_buffer_w_data,
    input logic ROB_commit_store,


    output  store_buf_entry_t store_buffer_top,
    output  logic store_buffer_full,
    output  logic store_buffer_empty

);
    
    store_buf_entry_t store_buffer[1];
    always_ff @(posedge clk) begin
        if(rst) begin
            store_buffer[0] <= '0;
            store_buffer_full <= '0;
            store_buffer_empty <= '0;

        end
        else if(store_buffer_w_en && ~store_buffer_full) begin
            store_buffer[0] <= store_buffer_w_data;
            store_buffer_full <= 1'b1;
            store_buffer_empty <= '0;
        end
        else if(ROB_commit_store && ~store_buffer_empty) begin
            store_buffer_empty <= 1'b1;
            store_buffer_full <= '0;
        end
    end

    assign store_buffer_top = store_buffer[0];

endmodule