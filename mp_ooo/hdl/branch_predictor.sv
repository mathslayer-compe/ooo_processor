module branch_predictor
import module_types::*;
(
    input logic clk,
    input logic rst,

    input   logic [31:0]    inst_pc,
    output  logic pred, //take branch: 1, not taken branch: 0

    input   logic w_en,
    input   logic [31:0] commit_pc,
    input   logic taken //taken: 1, not taken: 0

);

    logic [BP_SET_IDX-1:0] read_pht_idx;
    logic [BP_SET_IDX-1:0] write_pht_idx;

    assign read_pht_idx = inst_pc[2+:BP_SET_IDX];
    assign write_pht_idx = commit_pc[2+:BP_SET_IDX];

    TWO_BIT_SAT_COUNTER pattern_history_table[BP_HEIGHT];
    logic [BP_SET_IDX-1:0] GHR; // global history register

    always_ff @(posedge clk) begin
        if(rst) begin
            GHR <= '1;
            for (int i=0; i<BP_HEIGHT; ++i) begin
                pattern_history_table[i] <= STRONGLY_TAKEN;
            end
        end
        else if(w_en) begin
            GHR <= {GHR[BP_SET_IDX-2:0], taken};   
            unique case(pattern_history_table[write_pht_idx])    
                STRONGLY_NOT: begin
                    if(taken) begin
                        pattern_history_table[write_pht_idx] <= WEAKLY_NOT;
                    end
                end 
                WEAKLY_NOT: begin
                    if(taken) begin
                        pattern_history_table[write_pht_idx] <= WEAKLY_TAKEN;
                    end
                    else begin
                        pattern_history_table[write_pht_idx] <= STRONGLY_NOT;
                    end
                end
                WEAKLY_TAKEN: begin
                    if(taken) begin
                        pattern_history_table[write_pht_idx] <= STRONGLY_TAKEN;
                    end
                    else begin
                        pattern_history_table[write_pht_idx] <= WEAKLY_NOT;
                    end
                end
                STRONGLY_TAKEN: begin 
                    if (!taken) begin
                        pattern_history_table[write_pht_idx] <= WEAKLY_TAKEN;
                    end
                end
                default: begin
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin  
        if(rst) begin 
            pred <= '0;
        end
        else begin
            // pred <= pattern_history_table[read_pht_idx ^ GHR][1]; //upper bit tells taken or not taken GSHARE
            // pred <= pattern_history_table[read_pht_idx + GHR][1]; //upper bit tells taken or not taken GSELECT
            pred <= pattern_history_table[read_pht_idx][1]; //upper bit tells taken or not taken
        end
        
    end
    
endmodule