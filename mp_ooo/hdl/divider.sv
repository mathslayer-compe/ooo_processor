// module shift_add_divider #(
//     parameter int OPERAND_WIDTH = 32
// )(
//     input logic clk,
//     input logic rst,
//     input logic start,
//     input logic [OPERAND_WIDTH-1:0] b,
//     input logic [OPERAND_WIDTH-1:0] a,
//     output logic [OPERAND_WIDTH-1:0] quotient,
//     output logic done
// );

//     logic [OPERAND_WIDTH-1:0] remainder, a_reg, b_reg, accumulator, range_select;
//     logic div_ready1, div_ready2;

//     enum int unsigned {IDLE, DIVIDE1, DIVIDE2, DONE} curr_state, next_state;

//     always_comb begin : state_transition
//         next_state = curr_state;
//         unique case(curr_state)
//             IDLE: next_state = start ? DIVIDE1 : IDLE;
//             DIVIDE1: next_state = div_ready1 ? DONE : DIVIDE2;
//             DIVIDE2: next_state = div_ready2 ? DONE : DIVIDE1;
//             DONE: next_state = start ?  DONE: IDLE;
//             default: next_state = curr_state;
//         endcase
//     end

//     always_comb begin : state_outputs
//         quotient = '0;
//         done = '0;
//         unique case(curr_state)
//             DONE: begin
//                 done = 1'b1;
//                 quotient = accumulator;
//             end
//             default: ;
//         endcase
//     end

//     //unsigned division
//     always_ff @(posedge clk) begin
//         if(rst) begin
//             curr_state <= IDLE;
//             a_reg <= '0;
//             b_reg <= '0;
//             accumulator <= '0;
//             remainder <= '0;
//             div_ready1 <= '0;
//             div_ready2 <= '0;
//         end
//         else begin
//             curr_state <= next_state;
//             unique case(curr_state)
//                 IDLE: begin
//                     if(start) begin
//                         a_reg <= a;
//                         b_reg <= b;
//                         accumulator <= '0; 
//                         remainder <= a;
//                     end
//                 end
//                 DIVIDE1: begin
//                     if(remainder < b_reg) begin
//                         div_ready1 <= 1'b1;
//                     end
//                     else begin
//                         remainder <= remainder - b_reg;
//                         accumulator <= accumulator + 1'b1;
//                         div_ready1 <= (remainder == '0) ? 1'b1 : '0;
//                     end
//                 end
//                 DIVIDE2: begin
//                     if(remainder < b_reg) begin
//                         div_ready2 <= 1'b1;
//                     end
//                     else begin
//                         remainder <= remainder - b_reg;
//                         accumulator <= accumulator + 1'b1;
//                         div_ready2 <= (remainder == '0) ? 1'b1 : '0;
//                     end
//                 end
//                 default: ;
//             endcase
//         end
        
//     end

// endmodule
