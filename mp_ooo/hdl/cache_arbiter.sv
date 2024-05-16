module cache_arbiter(
    input   logic           clk,
    input   logic           rst,

    input   logic   [31:0]  icache_ufp_addr,
    input   logic           icache_ufp_read,
    input   logic           icache_ufp_write,
    output  logic   [255:0] icache_ufp_rdata,
    input   logic   [255:0] icache_ufp_wdata,
    output  logic           icache_ufp_resp,

    input   logic   [31:0]  dcache_ufp_addr,
    input   logic           dcache_ufp_read,
    input   logic           dcache_ufp_write,
    output  logic   [255:0] dcache_ufp_rdata,
    input   logic   [255:0] dcache_ufp_wdata,
    output  logic           dcache_ufp_resp,

    // input   logic   [31:0]  prefetch_ufp_addr,
    // input   logic           prefetch_ufp_read,
    // input   logic           prefetch_ufp_write,
    // output  logic   [255:0] prefetch_ufp_rdata,
    // input   logic   [255:0] prefetch_ufp_wdata,
    // output  logic           prefetch_ufp_resp,

    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read, 
    output  logic           dfp_write, 
    input   logic   [255:0] dfp_rdata, 
    output  logic   [255:0] dfp_wdata, 
    input   logic           dfp_resp

    // input   logic           icache_prefetch_available,
    // input   logic   [255:0] prefetch_data
    // // output  logic           can_prefetch
);

enum int unsigned {
        idle, icache, dcache, prefetch
} state, state_next;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= idle;
    end
    else begin
        state <= state_next;
    end
end

always_comb begin
    dfp_addr = 'x;
    dfp_read = 1'b0;
    dfp_write = 1'b0;
    dfp_wdata = 'x;
    icache_ufp_rdata = 'x;
    icache_ufp_resp = 1'b0;
    dcache_ufp_rdata = '0;
    dcache_ufp_resp = 1'b0;
    // prefetch_ufp_rdata = '0;
    // prefetch_ufp_resp = 1'b0;
    state_next = state;
    // can_prefetch = 1'b0;
    unique case(state)
        idle: begin
            // can_prefetch = 1'b1;
            if (icache_ufp_read || icache_ufp_write) begin
                state_next = icache;
            end
            else if (dcache_ufp_read || dcache_ufp_write) begin
                state_next = dcache;
            end
            // else if (prefetch_ufp_read || prefetch_ufp_write) begin
            //     state_next = prefetch;
            // end
        end

        icache: begin
            // // can_prefetch = 1'b0;
            // if (icache_prefetch_available) begin
            //     icache_ufp_rdata = prefetch_data;
            //     icache_ufp_resp = 1'b1;
            //     state_next = idle;
            // end
            // else begin
                dfp_addr = icache_ufp_addr;
                dfp_read = icache_ufp_read;
                dfp_write = icache_ufp_write;
                dfp_wdata = icache_ufp_wdata;
                icache_ufp_rdata = dfp_rdata;
                icache_ufp_resp = dfp_resp;
                if (icache_ufp_resp) begin
                    state_next = idle;
                end
            // end
        end

        dcache: begin
            // can_prefetch = 1'b0;
            dfp_addr = dcache_ufp_addr;
            dfp_read = dcache_ufp_read;
            dfp_write = dcache_ufp_write;
            dfp_wdata = dcache_ufp_wdata;
            dcache_ufp_rdata = dfp_rdata;
            dcache_ufp_resp = dfp_resp;
            if (dcache_ufp_resp) begin
                state_next = idle;
            end
        end

        // prefetch: begin
        //     dfp_addr = prefetch_ufp_addr;
        //     dfp_read = prefetch_ufp_read;
        //     dfp_write = prefetch_ufp_write;
        //     dfp_wdata = prefetch_ufp_wdata;
        //     prefetch_ufp_rdata = dfp_rdata;
        //     prefetch_ufp_resp = dfp_resp;
        //     if (prefetch_ufp_resp) begin
        //         state_next = idle;
        //     end
        // end

        default: begin
        end
    endcase
end


endmodule