module cacheline_adaptor(
    input   logic           clk,
    input   logic           rst,

    // cache side signals, ufp
    input  logic   [31:0]  ufp_addr, //cache/adaptor addr
    input  logic           ufp_read, // cache read signal
    input  logic           ufp_write, // cache write signal
    output logic   [255:0] ufp_rdata, // adaptor read data 
    input  logic   [255:0] ufp_wdata, // cache write data
    output logic           ufp_resp, // adaptor response to cache


    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr, //adaptor/mem addr
    output  logic           dfp_read, //main mem read signal
    output  logic           dfp_write, //main mem write signal
    input   logic   [63:0]  dfp_rdata, //main mem read data (from)
    output  logic   [63:0]  dfp_wdata, //main mem write data
    input   logic           dfp_resp //main mem response (from)
);

    logic [255:0]   rdata, rdata_ff;
    logic [255:0]   wdata, wdata_ff;
    logic [31:0]    mem_addr, mem_addr_ff;


    enum int unsigned {  
        IDLE, READ_REQ, READ_ACCUM_1, READ_ACCUM_2, READ_ACCUM_3, READ_ACCUM_4 , WRITE_1, WRITE_2, WRITE_3, WRITE_4 /*PREFETCH_1, PREFETCH_2*/
    } curr_state, next_state;

    always_ff @(posedge clk) begin
        if(rst) begin
            curr_state <= IDLE;
        end else begin
            curr_state <= next_state;
            rdata_ff <= rdata;
            wdata_ff <= wdata;
            mem_addr_ff <= mem_addr;
        end
    end

    always_comb begin
        dfp_addr = '0;
        dfp_read = '0;
        dfp_write = '0;
        dfp_wdata = '0;
        ufp_resp = '0;
        ufp_rdata = '0;
        rdata = rdata_ff;
        wdata = wdata_ff;
        next_state = curr_state;
        mem_addr = mem_addr_ff;
        unique case(curr_state)
            IDLE: begin
                if(ufp_read) begin
                    mem_addr = ufp_addr;
                    next_state = READ_REQ;
                end
                else if(ufp_write) begin
                    mem_addr = ufp_addr;
                    next_state = WRITE_1;
                    wdata = ufp_wdata;
                end
            end
            READ_REQ: begin
                dfp_addr = mem_addr_ff;
                dfp_read = 1'b1;
                next_state = READ_ACCUM_1;
            end
            READ_ACCUM_1: begin
                if(dfp_resp) begin
                    rdata[63:0] = dfp_rdata;
                    next_state = READ_ACCUM_2;
                end
            end
            READ_ACCUM_2: begin
                rdata[127:64] = dfp_rdata;
                next_state = READ_ACCUM_3;
            end
            READ_ACCUM_3: begin
                rdata[191:128] = dfp_rdata;
                next_state = READ_ACCUM_4;
            end
            READ_ACCUM_4: begin
                rdata[255:192] = dfp_rdata;
                ufp_rdata = rdata;
                ufp_resp = 1'b1;
                next_state = IDLE;
            end
            WRITE_1: begin
                dfp_addr = mem_addr_ff;
                dfp_write = 1'b1;
                dfp_wdata = wdata_ff[63:0];
                next_state = WRITE_2;
            end
            WRITE_2: begin
                dfp_addr = mem_addr_ff;
                dfp_write = 1'b1;
                dfp_wdata = wdata_ff[127:64];
                next_state = WRITE_3;
            end
            WRITE_3: begin
                dfp_addr = mem_addr_ff;
                dfp_write = 1'b1;
                dfp_wdata = wdata_ff[191:128];
                next_state = WRITE_4;
            end
            WRITE_4: begin
                dfp_addr = mem_addr_ff;
                dfp_write = 1'b1;
                dfp_wdata = wdata_ff[255:192];
                ufp_resp = 1'b1;
                next_state = IDLE;
            end
            default: begin
            end

        endcase
    end

endmodule: cacheline_adaptor