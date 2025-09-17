module dadda_multiplier
#(
    parameter int OPERAND_WIDTH = 32
)
(
    input logic clk,
    input logic rst,
    input logic start,
    // input logic [1:0] mul_type,
    input logic[OPERAND_WIDTH-1:0] a,
    input logic[OPERAND_WIDTH-1:0] b,
    output logic[2*OPERAND_WIDTH-1:0] p,
    output logic done
);

    enum int unsigned {IDLE, MULTIPLY, ADD1, ADD2, ADD3, ACCUMULATE, DONE} curr_state, next_state;
    logic [OPERAND_WIDTH-1:0] a_reg, b_reg;
    logic [(2*OPERAND_WIDTH)-1:0] accumulator;
    logic [OPERAND_WIDTH-1:0] pp1, pp2, pp3, pp4;
    logic sum_ready1, sum_ready2, sum_ready3, accumulator_done;
    logic [OPERAND_WIDTH-1:0] sum1, cout1, sum2, sum3;

    always_comb begin: state_transition
        next_state = curr_state;
        unique case(curr_state)
            IDLE: next_state = start ? MULTIPLY : IDLE;
            MULTIPLY: next_state = ADD1;
            ADD1: next_state = sum_ready1 ? ADD2 : ADD1;
            ADD2: next_state = sum_ready2 ? ADD3 : ADD2;
            ADD3: next_state = sum_ready3 ? ACCUMULATE : ADD3;
            ACCUMULATE: next_state = accumulator_done ? DONE : ACCUMULATE;
            DONE: next_state = start ? DONE : IDLE;
            default: ;
        endcase
    end: state_transition

    always_comb begin: state_outputs
        done = '0;
        p = '0;
        unique case(curr_state)
            DONE: begin
                done = 1'b1;
                p = accumulator;
            end
            default: ;
        endcase
    end: state_outputs

    always_ff @(posedge clk) begin
        if(rst) begin
            curr_state <= IDLE;
            a_reg <= '0;
            b_reg <= '0;
            accumulator <= '0;
            sum_ready1 <= '0;
            sum_ready2 <= '0;
            sum_ready3 <= '0;
            accumulator_done <= '0;
        end
        else begin
            curr_state <= next_state;
            // accumulator <= '0; //maybe need it?
            unique case(curr_state)
                IDLE: begin
                    if(start) begin
                        accumulator <= '0;
                        a_reg <= a;
                        b_reg <= b;
                    end
                end
                MULTIPLY: begin
                    pp1 <= 32'(a_reg[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)] * b_reg[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)]); //TODO: LINT MAD IDK I HAD TO FIX IT SOMEHOW
                    pp2 <= 32'(a_reg[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)] * b_reg[(OPERAND_WIDTH/2)-1:0]);
                    pp3 <= 32'(a_reg [(OPERAND_WIDTH/2)-1:0] * b_reg[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)]);
                    pp4 <= 32'(a_reg[(OPERAND_WIDTH/2)-1:0] * b_reg[(OPERAND_WIDTH/2)-1:0]);
                end
                ADD1: begin
                    sum1 <= pp2 + pp3;
                    cout1 <= {31'b0, sum1[OPERAND_WIDTH-1]};
                    sum_ready1 <= 1'b1;
                end
                ADD2: begin
                    sum2 <= sum1 + {16'b0, pp4[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)]}; //maybe {pp4[31:16], 16'b0}?
                    sum_ready2 <= 1'b1;
                end
                ADD3: begin
                    sum3 <= pp1 + cout1 + {sum2[OPERAND_WIDTH-1:(OPERAND_WIDTH/2)], 16'b0}; //maybe {0, sum2}?
                    sum_ready3 <= 1'b1;
                end
                ACCUMULATE: begin
                    accumulator[63:32] <= sum3;
                    accumulator[31:16] <= sum2[15:0];
                    accumulator[15:0] <= pp4[15:0];
                    accumulator_done <= 1'b1;
                end
                default: ;
            endcase
        end
    end


    

endmodule

