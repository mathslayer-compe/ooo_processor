module prefetcher(
    input   logic           clk,
    input   logic           rst,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp,

    input   logic           icache_read,
    input   logic   [31:0]  icache_addr,
    output  logic           icache_prefetch_available,
    output  logic   [255:0] prefetch_data,
    input   logic           can_prefetch

);

    logic [31:0] prefetch_addr;
    // logic [255:0] prefetch_data; 
    logic valid;
    logic update_prefetch_addr;
    // logic request_received;

    always_ff @(posedge clk) begin
        if(rst || icache_prefetch_available) begin
            valid <= 1'b0;
            // request_received <= 1'b0;
        end
        else begin
            if (dfp_resp) begin
                valid <= 1'b1;
                prefetch_data <= dfp_rdata;
                // request_received <= 1'b1;
            end
            if (update_prefetch_addr) begin
                prefetch_addr <= icache_addr + 32'd32;
                valid <= 1'b0;
            end
            // if (dfp_read) begin
            //     request_received <= 1'b0;
            // end
        end
    end

    always_comb begin
        dfp_addr = 'x;
        dfp_read = 1'b0;
        dfp_write = 1'b0;
        dfp_wdata = 'x;
        icache_prefetch_available = 1'b0;
        update_prefetch_addr = 1'b0;
       
        if (icache_read) begin
            if ((icache_addr == prefetch_addr)) begin
                if (valid) begin
                    icache_prefetch_available = 1'b1;
                end
            end
            else begin
                update_prefetch_addr = 1'b1;
                dfp_read = 1'b1;                    //added this
                dfp_addr = prefetch_addr;           //added this
            end
        end
        // else if (can_prefetch && !request_received)begin
        //     dfp_read = 1'b1;
        //     dfp_addr = prefetch_addr;
        // end
        // else begin
        //     dfp_read = 1'b1;
        //     dfp_addr = prefetch_addr;
        // end
    end

endmodule