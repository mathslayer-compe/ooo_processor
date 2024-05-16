module stack
#(  parameter   D_WIDTH = 32,
    parameter   DEPTH = 16,
    localparam  ADDR_WIDTH = $clog2(DEPTH)
)(
    input   logic                   clk,
    input   logic                   rst,
    input   logic                   r_en,
    output  logic   [D_WIDTH-1:0]   r_data,
    input   logic                   w_en,
    input   logic   [D_WIDTH-1:0]   w_data,
    output  logic                   empty_sig
);

    logic   [D_WIDTH-1:0]   d_array[DEPTH];
    logic   [ADDR_WIDTH:0]       read_ptr;

    assign empty_sig = (read_ptr == '0);

    always_ff @( posedge clk ) begin : manage_stack
        if(rst) begin
            read_ptr <= '0;
        end
        else begin
            if(w_en) begin
                d_array[read_ptr[ADDR_WIDTH-1:0]] <=  w_data;
                read_ptr <= read_ptr+1'b1;
            end
            if(r_en && ~empty_sig) begin
                read_ptr <= read_ptr-1'b1;
            end
        end
    end

    always_comb begin
        if(r_en && ~empty_sig) begin
            r_data = d_array[read_ptr[ADDR_WIDTH:1]];
        end
        else begin
            r_data = 'x;
        end

    end

endmodule : stack