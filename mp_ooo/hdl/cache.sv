module cache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

logic data_we[4];
logic [255:0] data_in[4];
logic [255:0] data_out[4];

logic tag_we[4];
logic [23:0] tag[4];
logic [23:0] curr_tag;

logic valid_we[4];
logic valid_in[4];
logic valid_out[4];

logic [3:0] set_index;
logic plru_flag;
logic [1:0] hit_index;
logic [1:0] lru_way;
assign set_index = ufp_addr[8:5];
// assign curr_tag = ufp_addr[31:9]; --> add extra bit for dirty
logic dirty_bit;
assign curr_tag = {dirty_bit, ufp_addr[31:9]};
// assign plru_flag = 1'b0;

// logic [31:0] rmask;
logic [31:0] wmask;
// assign rmask = {{28'b0, ufp_rmask} << 4*(ufp_addr[4:0] % 4)};
// assign wmask = {{28'b0, ufp_wmask} << 4*(ufp_addr[4:0] % 4)};


    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (data_we[i]),
            .wmask0     (wmask),
            .addr0      (set_index),
            .din0       (data_in[i]),
            .dout0      (data_out[i])
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (tag_we[i]),
            .addr0      (set_index),
            .din0       (curr_tag),
            .dout0      (tag[i])
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (valid_we[i]),
            .addr0      (set_index),
            .din0       (1'b1),
            .dout0      (valid_out[i])
        );
    end endgenerate


// change valid to 0??????????????????????????????????????????????????????????


enum int unsigned {
        idle, compare_tag, allocate, write_back
} state, state_next;

always_ff @(posedge clk) begin
    if (rst) begin
        state <= idle;
    end        
    else begin
        state <= state_next;
    end
end

logic temp;
always_comb begin
    temp = 1'b0;
    state_next = state;

    data_we[0] = 1'b1;
    data_we[1] = 1'b1;
    data_we[2] = 1'b1;
    data_we[3] = 1'b1;
    data_in[0] = '0;
    data_in[1] = '0;
    data_in[2] = '0;
    data_in[3] = '0;
    // data_out[0] = '0;
    tag_we[0] = 1'b1;
    tag_we[1] = 1'b1;
    tag_we[2] = 1'b1;
    tag_we[3] = 1'b1;
    // tag[0] = '0;
    // tag[1] = '0;
    // tag[2] = '0;
    // tag[3] = '0;
    
    valid_we[0] = 1'b1;
    valid_we[1] = 1'b1;
    valid_we[2] = 1'b1;
    valid_we[3] = 1'b1;
    valid_in[0] = '0;
    valid_in[1] = '0;
    valid_in[2] = '0;
    valid_in[3] = '0;
    // valid_out[0] = '0;
    // valid_out[1] = '0;
    // valid_out[2] = '0;
    // valid_out[3] = '0;

    ufp_resp = 1'b0;
    hit_index = 2'b00;
    dirty_bit = 1'b0;
    dfp_addr = '0;
    plru_flag = 1'b0;
    wmask = '0;
    dfp_read = 1'b0;
    dfp_write = 1'b0;
    ufp_rdata = '0;
    dfp_wdata = '0;

    unique case(state) 
        idle: begin
            if (ufp_wmask != 0 || ufp_rmask != 0) begin
                state_next = compare_tag;
            end
            else begin
                state_next = idle;
            end
        end

        compare_tag: begin
            if (valid_out[0] && (curr_tag[22:0] == tag[0][22:0])) begin
                ufp_resp = 1'b1;
                plru_flag = 1'b1;
                hit_index = 2'b00;
                // ufp_rdata = data_out[0][32*(ufp_addr[4:0] % 4) +: 32];
                ufp_rdata = data_out[0][(32*(ufp_addr[4:2])) +: 32];
                temp = 1'b1;
            end
            else if (valid_out[1] && (curr_tag[22:0] == tag[1][22:0])) begin
                ufp_resp = 1'b1;
                plru_flag = 1'b1;
                hit_index = 2'b01;
                // ufp_rdata = data_out[1][32*ufp_addr[4:0] % 4 +: 32];
                ufp_rdata = data_out[1][(32*(ufp_addr[4:2])) +: 32];
                temp = 1'b1;
            end
            else if (valid_out[2] && (curr_tag[22:0] == tag[2][22:0])) begin
                ufp_resp = 1'b1;
                plru_flag = 1'b1;
                hit_index = 2'b10;
                // ufp_rdata = data_out[2][32*(ufp_addr[4:0] % 4) +: 32];
                ufp_rdata = data_out[2][(32*(ufp_addr[4:2])) +: 32];
                temp = 1'b1;
            end
            else if (valid_out[3] && (curr_tag[22:0] == tag[3][22:0])) begin
                ufp_resp = 1'b1;
                plru_flag = 1'b1;
                hit_index = 2'b11;
                // ufp_rdata = data_out[3][32*(ufp_addr[4:0] % 4) +: 32];
                ufp_rdata = data_out[3][(32*(ufp_addr[4:2])) +: 32];
                temp = 1'b1;
            end
            else if (tag[lru_way][23] == 1'b0) begin
                state_next = allocate;
            end

            if (ufp_resp == 1'b1) begin
                // set dirty;
                // set msb of tag to 1 (currtag)
                // set tag write enable to 1
                if(|ufp_wmask) begin
                    // curr_tag[23] = 1'b1;
                    dirty_bit = 1'b1;
                    tag_we[hit_index] = 1'b0;
                    data_in[hit_index] = {8{ufp_wdata}};
                    data_we[hit_index] = 1'b0;
                    // wmask = {{28'b0, ufp_wmask} << 4*(ufp_addr[4:0] % 4)};
                    wmask = {{28'b0, ufp_wmask} << 4*(ufp_addr[4:2])};
                end
                state_next = idle;
            end
            else if (ufp_resp == 1'b0) begin
                // set dirty;
                // set msb of tag to 1 (currtag)
                // set tag write enable to 1
                // if (curr_tag[23] == 1'b1) begin
                // if (dirty_bit == 1'b1) begin
                if (tag[lru_way][23] == 1'b1) begin
                    state_next = write_back;
                end
                else begin
                    state_next = allocate;
                end
            end
        end

        allocate: begin
            dfp_read = 1'b1;
            wmask = 32'hffff_ffff;
            dfp_addr = {ufp_addr[31:9], ufp_addr[8:5], 5'b0};
            if (dfp_resp) begin
                state_next = idle;
                // set write enable to 1
                // grab plru value for set I am checking
                // traverse plru tree for that vlaue to see what to replace
                data_we[lru_way] = 1'b0;
                // set value from plru to data_in; data_in[way] = value from memory = dfp_rdata
                data_in[lru_way] = dfp_rdata;
                // do it for tag and data
                tag_we[lru_way] = 1'b0;
                valid_we[lru_way] = 1'b0;
            end
            else if (!dfp_resp) begin
                state_next = allocate;
                // set write enable default to 0 at top
            end
        end

        write_back: begin
            dfp_addr = {tag[lru_way][22:0], ufp_addr[8:5], 5'b0};
            dfp_wdata = data_out[lru_way];
            dfp_write = 1'b1;
            if (dfp_resp) begin
                state_next = allocate;
            end
            else if (!dfp_resp) begin
                state_next = write_back;
            end
        end

        default: begin
            state_next = idle;
        end
    endcase
end


logic [2:0] PLRU[16];
logic [2:0] PLRU_next[16];
always_comb begin
    if (PLRU[set_index][0]) begin
        if (PLRU[set_index][2]) begin
            lru_way = 2'b11; 
        end
        else begin
            lru_way = 2'b10;
        end
    end
    else begin
        if (PLRU[set_index][1]) begin
            lru_way = 2'b01;
        end
        else begin
            lru_way = 2'b00;
        end
    end
end


// logic [3:0] j;
always_ff @(posedge clk) begin
    if (rst) begin
        for (int j = 0; j < 15; j++) begin
            PLRU[j] <= '0;
        end
    end
    else begin
        PLRU <= PLRU_next;
    end
end

// create ff array of plru 3bits
// set plru signal to 1 in comapretag then update it
always_comb begin
    PLRU_next = PLRU;
    if (plru_flag == 1'b1) begin
        unique case (hit_index)
            2'b00: begin
                PLRU_next[set_index][0] = 1'b1;
                PLRU_next[set_index][1] = 1'b1;
                PLRU_next[set_index][2] = PLRU[set_index][2];
            end
            2'b01: begin
                PLRU_next[set_index][0] = 1'b1;
                PLRU_next[set_index][1] = 1'b0;
                PLRU_next[set_index][2] = PLRU[set_index][2];
            end
            2'b10: begin
                PLRU_next[set_index][0] = 1'b0;
                PLRU_next[set_index][1] = PLRU[set_index][1];
                PLRU_next[set_index][2] = 1'b1;
            end
            2'b11: begin
                PLRU_next[set_index][0] = 1'b0;
                PLRU_next[set_index][1] = PLRU[set_index][1];
                PLRU_next[set_index][2] = 1'b0;
            end
            default: begin
                PLRU_next[set_index][0] = PLRU[set_index][0];
                PLRU_next[set_index][1] = PLRU[set_index][1];
                PLRU_next[set_index][2] = PLRU[set_index][2];
            end
        endcase
    end
    else begin
        PLRU_next[set_index][0] = PLRU[set_index][0];
        PLRU_next[set_index][1] = PLRU[set_index][1];
        PLRU_next[set_index][2] = PLRU[set_index][2];
    end
end

endmodule