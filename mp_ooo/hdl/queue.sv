module queue
#(  parameter   D_WIDTH = 32,
    parameter   DEPTH = 16, //change to be area of reservation stations
    localparam  ADDR_WIDTH = $clog2(DEPTH)
)(
    input   logic                   clk,
    input   logic                   rst,
    input   logic                   r_en,
    output  logic   [D_WIDTH-1:0]   r_data,
    input   logic                   w_en,
    input   logic   [D_WIDTH-1:0]   w_data,
    output  logic                   full_sig,
    output  logic                   empty_sig
);

    logic   [D_WIDTH-1:0]   d_array[DEPTH];
    logic   [ADDR_WIDTH:0]       read_ptr, write_ptr; //extra bit for overflow

    assign full_sig = (read_ptr[ADDR_WIDTH-1:0] == write_ptr[ADDR_WIDTH-1:0]) && (read_ptr[ADDR_WIDTH] != write_ptr[ADDR_WIDTH]);
    assign empty_sig = (read_ptr[ADDR_WIDTH-1:0] == write_ptr[ADDR_WIDTH-1:0]) && (read_ptr[ADDR_WIDTH] == write_ptr[ADDR_WIDTH]);

    always_ff @( posedge clk ) begin : manage_queue
        if(rst) begin
            read_ptr <= '0;
            write_ptr <= '0;
        end
        else begin
            if(w_en && ~full_sig) begin
                d_array[write_ptr[ADDR_WIDTH-1:0]] <=  w_data;
                write_ptr <= write_ptr+1'b1;
            end
            if(r_en && ~empty_sig) begin
                read_ptr <= read_ptr+1'b1;
            end
        end
    end

    always_comb begin
        r_data = d_array[read_ptr[ADDR_WIDTH-1:0]];
    end

endmodule : queue