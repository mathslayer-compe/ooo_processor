module reservationStation
import rv32i_types::*;
import module_types::*;
(
    input logic clk,
    input logic rst,
    input logic flush,
    input [ROB_IDX_SIZE-1:0] robIndex,
    input decoded_output_t decoded_output,
    input logic [PHYS_REG_ADDR-1:0] rs1_addr,
    input logic [PHYS_REG_ADDR-1:0] rs2_addr,
    input logic rs1_valid,
    input logic rs2_valid,
    input logic inst_resp,                //signal coming from rename/dispatch if instruction is going to reservation station
    input logic cdb_valid,
    input logic [31:0] rd_v, //cdb_data
    input logic [PHYS_REG_ADDR-1:0] cdb_phys_addr, 
    input logic [PHYS_REG_ADDR-1:0] freed_physical_reg, 
    input logic mult_in_use,
    input logic mem_in_use,
    input logic div_in_use,
    input logic [3:0] unit_stall, //coming from CDB
    output logic arithmetic_filled,
    output logic mult_filled,
    output logic mem_filled,
    output logic br_filled,
    output logic div_filled,
    output functional_unit_t functional_arith_unit,
    output functional_unit_t functional_mult_unit,
    output functional_unit_t functional_mem_unit,
    output functional_unit_t functional_br_unit,
    output functional_unit_t functional_div_unit,
    output logic arith_dispatch,
    output logic mult_dispatch,
    output logic mem_dispatch,
    output logic br_dispatch,
    output logic div_dispatch
);

//pass on filled signal to dispatch 
//get whether source 1 and source 2 registers are valid from cdb

reservationStation_reg_t reservationStation_arith_reg[RES_SIZE];
reservationStation_reg_t reservationStation_mult_reg[MULT_RES_SIZE];
reservationStation_reg_t reservationStation_br_reg[BR_DIV_RES_SIZE];
reservationStation_reg_t reservationStation_mem_reg[1];
reservationStation_reg_t reservationStation_div_reg[BR_DIV_RES_SIZE];
func_unit_sel_t fu_signal;
assign fu_signal = decoded_output.func_unit_sel;


logic [RES_ADDR_WIDTH-1:0] reservationStation_arith_index;
logic [M_RES_ADDR_WIDTH-1:0] reservationStation_mult_index;
logic [BD_RES_ADDR_WIDTH-1:0] reservationStation_br_index;
logic [BD_RES_ADDR_WIDTH-1:0] reservationStation_div_index;
logic reservationStation_mem_index;
logic [RES_ADDR_WIDTH-1:0] arith_idx;
logic [M_RES_ADDR_WIDTH-1:0] mult_idx; 
logic [BD_RES_ADDR_WIDTH-1:0] br_idx, div_idx;

logic [31:0] arith_rs1_v, mult_rs1_v, mem_rs1_v, br_rs1_v, div_rs1_v;
logic [31:0] arith_rs2_v, mult_rs2_v, mem_rs2_v, br_rs2_v, div_rs2_v;


// CDB Snoop Logic
logic ready_snoop_valid1, ready_snoop_valid2;
always_comb begin
    ready_snoop_valid1 = '0;
    ready_snoop_valid2 = '0;

    if ((rs1_addr == cdb_phys_addr) && (cdb_phys_addr != '0)) begin
        ready_snoop_valid1 = 1'b1;
    end

    if ((rs2_addr == cdb_phys_addr) && (cdb_phys_addr != '0)) begin
        ready_snoop_valid2 = 1'b1;
    end
end

always_ff @(posedge clk) begin
    if (rst || flush) begin
        reservationStation_mem_reg[0] <= '0;
        for (int i = 0; i < RES_SIZE; i++) begin
            reservationStation_arith_reg[i] <= '0;
        end
        for(int j = 0; j < MULT_RES_SIZE; j++) begin
            reservationStation_mult_reg[j] <= '0;
        end
        for(int j = 0; j < BR_DIV_RES_SIZE; j++) begin
            reservationStation_br_reg[j] <= '0;
            reservationStation_div_reg[j] <= '0;
        end
    end
    else begin
        if (inst_resp && !arithmetic_filled && !mult_filled && !mem_filled && !br_filled && !div_filled) begin                  //check this!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            unique case (decoded_output.func_unit_sel)
                arith, comp: begin     //arithmetic arithmetic_filled
                    reservationStation_arith_reg[reservationStation_arith_index].inst <= decoded_output.inst;
                    reservationStation_arith_reg[reservationStation_arith_index].rs1_s <= rs1_addr;
                    reservationStation_arith_reg[reservationStation_arith_index].rs2_s <= rs2_addr;
                    reservationStation_arith_reg[reservationStation_arith_index].rd_s <= freed_physical_reg;
                    // reservationStation_arith_reg[reservationStation_arith_index].rs1_v <= ;
                    // reservationStation_arith_reg[reservationStation_arith_index].rs2_v <= ;
                    reservationStation_arith_reg[reservationStation_arith_index].rd_v <= rd_v;
                    reservationStation_arith_reg[reservationStation_arith_index].sext_imm <= decoded_output.sext_imm;
                    reservationStation_arith_reg[reservationStation_arith_index].opcode <= decoded_output.opcode;
                    reservationStation_arith_reg[reservationStation_arith_index].fuop <= decoded_output.fuop;
                    reservationStation_arith_reg[reservationStation_arith_index].filled <= 1'b1;
                    reservationStation_arith_reg[reservationStation_arith_index].robIndex <= robIndex;
                    reservationStation_arith_reg[reservationStation_arith_index].rs1_valid <= rs1_valid | ready_snoop_valid1;
                    reservationStation_arith_reg[reservationStation_arith_index].rs2_valid <= rs2_valid | ready_snoop_valid2;
                    reservationStation_arith_reg[reservationStation_arith_index].funct3 <= decoded_output.funct3;
                    reservationStation_arith_reg[reservationStation_arith_index].ALUsrc <= decoded_output.ALUsrc;
                    reservationStation_arith_reg[reservationStation_arith_index].pc <= decoded_output.pc;
                end
                mult: begin     //multiplication
                    reservationStation_mult_reg[reservationStation_mult_index].inst <= decoded_output.inst;
                    reservationStation_mult_reg[reservationStation_mult_index].rs1_s <= rs1_addr;
                    reservationStation_mult_reg[reservationStation_mult_index].rs2_s <= rs2_addr;
                    reservationStation_mult_reg[reservationStation_mult_index].rd_s <= freed_physical_reg;
                    // reservationStation_mult_reg[reservationStation_mult_index].rs1_v <= ;
                    // reservationStation_mult_reg[reservationStation_mult_index].rs2_v <= ;
                    reservationStation_mult_reg[reservationStation_mult_index].rd_v <= rd_v;
                    reservationStation_mult_reg[reservationStation_mult_index].sext_imm <= decoded_output.sext_imm;
                    reservationStation_mult_reg[reservationStation_mult_index].opcode <= decoded_output.opcode;
                    reservationStation_mult_reg[reservationStation_mult_index].fuop <= decoded_output.fuop;
                    reservationStation_mult_reg[reservationStation_mult_index].filled <= 1'b1;
                    reservationStation_mult_reg[reservationStation_mult_index].robIndex <= robIndex;
                    reservationStation_mult_reg[reservationStation_mult_index].rs1_valid <= rs1_valid | ready_snoop_valid1;
                    reservationStation_mult_reg[reservationStation_mult_index].rs2_valid <= rs2_valid | ready_snoop_valid2;
                    reservationStation_mult_reg[reservationStation_mult_index].funct3 <= decoded_output.funct3;
                    reservationStation_mult_reg[reservationStation_mult_index].ALUsrc <= decoded_output.ALUsrc;
                    reservationStation_mult_reg[reservationStation_mult_index].pc <= decoded_output.pc;
                end
                agen: begin
                    reservationStation_mem_reg[0].inst <= decoded_output.inst;
                    reservationStation_mem_reg[0].rs1_s <= rs1_addr;
                    reservationStation_mem_reg[0].rs2_s <= rs2_addr;
                    reservationStation_mem_reg[0].rd_s <= freed_physical_reg;
                    reservationStation_mem_reg[0].rd_v <= rd_v;
                    reservationStation_mem_reg[0].sext_imm <= decoded_output.sext_imm;
                    reservationStation_mem_reg[0].opcode <= decoded_output.opcode;
                    reservationStation_mem_reg[0].fuop <= decoded_output.fuop;
                    reservationStation_mem_reg[0].filled <= 1'b1;
                    reservationStation_mem_reg[0].robIndex <= robIndex;
                    reservationStation_mem_reg[0].rs1_valid <= rs1_valid | ready_snoop_valid1;
                    reservationStation_mem_reg[0].rs2_valid <= rs2_valid | ready_snoop_valid2;
                    reservationStation_mem_reg[0].funct3 <= decoded_output.funct3;
                    reservationStation_mem_reg[0].ALUsrc <= decoded_output.ALUsrc;
                    reservationStation_mem_reg[0].pc <= decoded_output.pc;
                end
                branch: begin
                    reservationStation_br_reg[reservationStation_br_index].inst <= decoded_output.inst;
                    reservationStation_br_reg[reservationStation_br_index].rs1_s <= rs1_addr;
                    reservationStation_br_reg[reservationStation_br_index].rs2_s <= rs2_addr;
                    reservationStation_br_reg[reservationStation_br_index].rd_s <= freed_physical_reg;
                    reservationStation_br_reg[reservationStation_br_index].rd_v <= rd_v;
                    reservationStation_br_reg[reservationStation_br_index].sext_imm <= decoded_output.sext_imm;
                    reservationStation_br_reg[reservationStation_br_index].opcode <= decoded_output.opcode;
                    reservationStation_br_reg[reservationStation_br_index].fuop <= decoded_output.fuop;
                    reservationStation_br_reg[reservationStation_br_index].filled <= 1'b1;
                    reservationStation_br_reg[reservationStation_br_index].robIndex <= robIndex;
                    reservationStation_br_reg[reservationStation_br_index].rs1_valid <= rs1_valid | ready_snoop_valid1;
                    reservationStation_br_reg[reservationStation_br_index].rs2_valid <= rs2_valid | ready_snoop_valid2;
                    reservationStation_br_reg[reservationStation_br_index].funct3 <= decoded_output.funct3;
                    reservationStation_br_reg[reservationStation_br_index].ALUsrc <= decoded_output.ALUsrc;
                    reservationStation_br_reg[reservationStation_br_index].pc <= decoded_output.pc;
                    reservationStation_br_reg[reservationStation_br_index].pc_next <= decoded_output.pc_next;
                    reservationStation_br_reg[reservationStation_br_index].br_pred <= decoded_output.br_pred;
                end
                division: begin
                    reservationStation_div_reg[reservationStation_div_index].inst <= decoded_output.inst;
                    reservationStation_div_reg[reservationStation_div_index].rs1_s <= rs1_addr;
                    reservationStation_div_reg[reservationStation_div_index].rs2_s <= rs2_addr;
                    reservationStation_div_reg[reservationStation_div_index].rd_s <= freed_physical_reg;
                    reservationStation_div_reg[reservationStation_div_index].rd_v <= rd_v;
                    reservationStation_div_reg[reservationStation_div_index].sext_imm <= decoded_output.sext_imm;
                    reservationStation_div_reg[reservationStation_div_index].opcode <= decoded_output.opcode;
                    reservationStation_div_reg[reservationStation_div_index].fuop <= decoded_output.fuop;
                    reservationStation_div_reg[reservationStation_div_index].filled <= 1'b1;
                    reservationStation_div_reg[reservationStation_div_index].robIndex <= robIndex;
                    reservationStation_div_reg[reservationStation_div_index].rs1_valid <= rs1_valid | ready_snoop_valid1;
                    reservationStation_div_reg[reservationStation_div_index].rs2_valid <= rs2_valid | ready_snoop_valid2;
                    reservationStation_div_reg[reservationStation_div_index].funct3 <= decoded_output.funct3;
                    reservationStation_div_reg[reservationStation_div_index].ALUsrc <= decoded_output.ALUsrc;
                    reservationStation_div_reg[reservationStation_div_index].pc <= decoded_output.pc;
                end
                default: begin
                    reservationStation_mult_reg[reservationStation_mult_index].inst <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].rs1_s <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].rs2_s <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].rd_s <= '0;
                    // reservationStation_mult_reg[reservationStation_mult_index].rs1_v <= ;
                    // reservationStation_mult_reg[reservationStation_mult_index].rs2_v <= ;
                    reservationStation_mult_reg[reservationStation_mult_index].rd_v <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].sext_imm <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].opcode <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].fuop <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].filled <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].robIndex <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].rs1_valid <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].rs2_valid <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].funct3 <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].ALUsrc <= '0;
                    reservationStation_mult_reg[reservationStation_mult_index].pc <= '0;
                end
            endcase
        end

        if (cdb_valid) begin
            for (int i = 0; i < RES_SIZE; i++) begin
                if (reservationStation_arith_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_arith_reg[i].rs1_valid <= 1'b1;
                end
                if (reservationStation_arith_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_arith_reg[i].rs2_valid <= 1'b1;
                end
            end
            for (int i = 0; i < BR_DIV_RES_SIZE; i++) begin
                if (reservationStation_br_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_br_reg[i].rs1_valid <= 1'b1;
                end
                if (reservationStation_br_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_br_reg[i].rs2_valid <= 1'b1;
                end
            end
            for (int i = 0; i < MULT_RES_SIZE; i++) begin
                if (reservationStation_mult_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_mult_reg[i].rs1_valid <= 1'b1;
                end
                if (reservationStation_mult_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_mult_reg[i].rs2_valid <= 1'b1;
                end
            end
            for (int i = 0; i < BR_DIV_RES_SIZE; i++) begin
                if (reservationStation_div_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_div_reg[i].rs1_valid <= 1'b1;
                end
                if (reservationStation_div_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                    reservationStation_div_reg[i].rs2_valid <= 1'b1;
                end
            end
            if (reservationStation_mem_reg[0].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                reservationStation_mem_reg[0].rs1_valid <= 1'b1;
            end
            if (reservationStation_mem_reg[0].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                reservationStation_mem_reg[0].rs2_valid <= 1'b1;
            end
        end
        if (reservationStation_arith_reg[arith_idx].rs1_valid && reservationStation_arith_reg[arith_idx].rs2_valid && arith_dispatch) begin
            reservationStation_arith_reg[arith_idx] <= '0;
        end
        if (reservationStation_mult_reg[mult_idx].rs1_valid && reservationStation_mult_reg[mult_idx].rs2_valid && mult_dispatch) begin
            reservationStation_mult_reg[mult_idx] <= '0;
        end
        if (reservationStation_mem_reg[0].rs1_valid && reservationStation_mem_reg[0].rs2_valid && mem_dispatch) begin
            reservationStation_mem_reg[0] <= '0;
        end
        if(reservationStation_br_reg[br_idx].rs1_valid && reservationStation_br_reg[br_idx].rs2_valid && br_dispatch) begin
            reservationStation_br_reg[br_idx] <= '0;
        end
        if(reservationStation_div_reg[div_idx].rs1_valid  && reservationStation_div_reg[div_idx].rs2_valid && div_dispatch) reservationStation_div_reg[div_idx] <= '0;
    end
end

//find empty reservation station to add instruction coming from decoder
always_comb begin
    reservationStation_mult_index = '0;
    reservationStation_arith_index = '0;
    reservationStation_br_index = '0;
    reservationStation_div_index = '0;
    mult_filled = 1'b0;
    arithmetic_filled = 1'b0;
    mem_filled = 1'b0; 
    br_filled = 1'b0;
    div_filled = 1'b0;

    
    if (fu_signal == arith || fu_signal == comp) begin
        for (int unsigned i = 0; i < RES_SIZE; i++) begin
            if (reservationStation_arith_reg[i].filled == 1'b0) begin
                reservationStation_arith_index = (RES_ADDR_WIDTH)'(i);
                arithmetic_filled = 1'b0;
                break;
            end
            else begin
                arithmetic_filled = 1'b1;
            end
        end
    end
    else if (fu_signal == mult ) begin
        for (int unsigned i = 0; i < MULT_RES_SIZE; i++) begin
            if (reservationStation_mult_reg[i].filled == 1'b0) begin
                reservationStation_mult_index = (M_RES_ADDR_WIDTH)'(i);
                mult_filled = 1'b0;
                break;
            end
            else begin
                mult_filled = 1'b1;
            end
        end
    end
    else if(fu_signal == division) begin
        for (int unsigned i = 0; i < BR_DIV_RES_SIZE; i++) begin
            if(reservationStation_div_reg[i].filled == 1'b0) begin
                reservationStation_div_index = (BD_RES_ADDR_WIDTH)'(i);
                div_filled = 1'b0;
                break;
            end
            else div_filled = 1'b1;
        end
    end
    else if (fu_signal == branch) begin
        for (int unsigned i = 0; i < BR_DIV_RES_SIZE; i++) begin
            if(reservationStation_br_reg[i].filled == 1'b0) begin
                reservationStation_br_index = (BD_RES_ADDR_WIDTH)'(i);
                br_filled = 1'b0;
                break;
            end
            else begin 
                br_filled = 1'b1;
            end
        end
    end
    if (fu_signal == agen) begin
        if (reservationStation_mem_reg[0].filled == 1'b0) begin
            mem_filled = 1'b0; 
        end
        else begin
            mem_filled = 1'b1;
        end
    end
end


//check if both sources are valid --> if valid, send it to functional unit
always_comb begin
    arith_dispatch = 1'b0;
    mult_dispatch = 1'b0;
    mem_dispatch = 1'b0;
    br_dispatch = 1'b0;
    div_dispatch = 1'b0;
    functional_arith_unit = '0;
    functional_mult_unit = '0;
    functional_mem_unit = '0;
    functional_br_unit = '0;
    functional_div_unit = '0;
    arith_idx = '0;
    mult_idx = '0;
    br_idx = '0;
    div_idx = '0;

    for (int unsigned i = 0; i < RES_SIZE; i++) begin
        if (reservationStation_arith_reg[i].rs1_valid && reservationStation_arith_reg[i].rs2_valid && !unit_stall[3]) begin
            arith_idx = (RES_ADDR_WIDTH)'(i);
            arith_dispatch = 1'b1;
            functional_arith_unit.inst = reservationStation_arith_reg[i].inst;
            functional_arith_unit.rs1_s = reservationStation_arith_reg[i].rs1_s;
            functional_arith_unit.rs2_s = reservationStation_arith_reg[i].rs2_s;
            functional_arith_unit.rd_s = reservationStation_arith_reg[i].rd_s;           // physical register from free list coming from dispatch
            functional_arith_unit.rd_v = reservationStation_arith_reg[i].rd_v;
            functional_arith_unit.opcode = reservationStation_arith_reg[i].opcode;
            functional_arith_unit.fuop = reservationStation_arith_reg[i].fuop;
            functional_arith_unit.funct3 = reservationStation_arith_reg[i].funct3;
            functional_arith_unit.sext_imm = reservationStation_arith_reg[i].sext_imm;
            functional_arith_unit.ALUsrc = reservationStation_arith_reg[i].ALUsrc;
            functional_arith_unit.filled = reservationStation_arith_reg[i].filled;
            functional_arith_unit.rs1_valid = reservationStation_arith_reg[i].rs1_valid;
            functional_arith_unit.rs2_valid = reservationStation_arith_reg[i].rs2_valid;
            functional_arith_unit.robIndex = reservationStation_arith_reg[i].robIndex;
            functional_arith_unit.pc = reservationStation_arith_reg[i].pc;
            if (reservationStation_arith_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_arith_unit.rs1_v = rd_v;
            end
            else begin
                functional_arith_unit.rs1_v = arith_rs1_v;
            end
            if (reservationStation_arith_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_arith_unit.rs2_v = rd_v;
            end
            else begin
                functional_arith_unit.rs2_v = arith_rs2_v;
            end
            break;
        end
    end
    for (int unsigned i = 0; i < MULT_RES_SIZE; i++) begin
        if (reservationStation_mult_reg[i].rs1_valid && reservationStation_mult_reg[i].rs2_valid && !mult_in_use && !unit_stall[1]) begin
            mult_idx = (M_RES_ADDR_WIDTH)'(i);
            mult_dispatch = 1'b1;
            functional_mult_unit.inst = reservationStation_mult_reg[i].inst;
            functional_mult_unit.rs1_s = reservationStation_mult_reg[i].rs1_s;
            functional_mult_unit.rs2_s = reservationStation_mult_reg[i].rs2_s;
            functional_mult_unit.rd_s = reservationStation_mult_reg[i].rd_s;           // physical register from free list coming from dispatch
            functional_mult_unit.rd_v = reservationStation_mult_reg[i].rd_v;
            functional_mult_unit.opcode = reservationStation_mult_reg[i].opcode;
            functional_mult_unit.fuop = reservationStation_mult_reg[i].fuop;
            functional_mult_unit.funct3 = reservationStation_mult_reg[i].funct3;
            functional_mult_unit.sext_imm = reservationStation_mult_reg[i].sext_imm;
            functional_mult_unit.ALUsrc = reservationStation_mult_reg[i].ALUsrc;
            functional_mult_unit.filled = reservationStation_mult_reg[i].filled;
            functional_mult_unit.rs1_valid = reservationStation_mult_reg[i].rs1_valid;
            functional_mult_unit.rs2_valid = reservationStation_mult_reg[i].rs2_valid;
            functional_mult_unit.robIndex = reservationStation_mult_reg[i].robIndex;
            functional_mult_unit.pc = reservationStation_mult_reg[i].pc;
            if (reservationStation_mult_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_mult_unit.rs1_v = rd_v;
            end
            else begin
                functional_mult_unit.rs1_v = mult_rs1_v;
            end
            if (reservationStation_mult_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_mult_unit.rs2_v = rd_v;
            end
            else begin
                functional_mult_unit.rs2_v = mult_rs2_v;
            end
            break;
        end
    end

    for(int unsigned i = 0; i < BR_DIV_RES_SIZE; i++) begin
        if(reservationStation_div_reg[i].rs1_valid && reservationStation_div_reg[i].rs2_valid && !div_in_use && !unit_stall[0]) begin
            div_idx = (BD_RES_ADDR_WIDTH)'(i);
            div_dispatch = 1'b1;
            functional_div_unit.inst = reservationStation_div_reg[i].inst;
            functional_div_unit.rs1_s = reservationStation_div_reg[i].rs1_s;
            functional_div_unit.rs2_s = reservationStation_div_reg[i].rs2_s;
            functional_div_unit.rd_s = reservationStation_div_reg[i].rd_s;
            functional_div_unit.rd_v = reservationStation_div_reg[i].rd_v;
            functional_div_unit.opcode = reservationStation_div_reg[i].opcode;
            functional_div_unit.fuop = reservationStation_div_reg[i].fuop;
            functional_div_unit.funct3 = reservationStation_div_reg[i].funct3;
            functional_div_unit.sext_imm = reservationStation_div_reg[i].sext_imm;
            functional_div_unit.ALUsrc = reservationStation_div_reg[i].ALUsrc;
            functional_div_unit.filled = reservationStation_div_reg[i].filled;
            functional_div_unit.rs1_valid = reservationStation_div_reg[i].rs1_valid;
            functional_div_unit.rs2_valid = reservationStation_div_reg[i].rs2_valid;
            functional_div_unit.robIndex = reservationStation_div_reg[i].robIndex;
            functional_div_unit.pc = reservationStation_div_reg[i].pc;

            if(reservationStation_div_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) functional_div_unit.rs1_v = rd_v;
            else functional_div_unit.rs1_v = div_rs1_v;

            if(reservationStation_div_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) functional_div_unit.rs2_v = rd_v;
            else functional_div_unit.rs2_v = div_rs2_v;

            break;

        end
    end

    for (int unsigned i = 0; i < BR_DIV_RES_SIZE; i++) begin
        if (reservationStation_br_reg[i].rs1_valid && reservationStation_br_reg[i].rs2_valid) begin
            br_idx = (BD_RES_ADDR_WIDTH)'(i);
            br_dispatch = 1'b1;
            functional_br_unit.inst = reservationStation_br_reg[i].inst;
            functional_br_unit.rs1_s = reservationStation_br_reg[i].rs1_s;
            functional_br_unit.rs2_s = reservationStation_br_reg[i].rs2_s;
            functional_br_unit.rd_s = reservationStation_br_reg[i].rd_s;           // physical register from free list coming from dispatch
            functional_br_unit.rd_v = reservationStation_br_reg[i].rd_v;
            functional_br_unit.opcode = reservationStation_br_reg[i].opcode;
            functional_br_unit.fuop = reservationStation_br_reg[i].fuop;
            functional_br_unit.funct3 = reservationStation_br_reg[i].funct3;
            functional_br_unit.sext_imm = reservationStation_br_reg[i].sext_imm;
            functional_br_unit.ALUsrc = reservationStation_br_reg[i].ALUsrc;
            functional_br_unit.filled = reservationStation_br_reg[i].filled;
            functional_br_unit.rs1_valid = reservationStation_br_reg[i].rs1_valid;
            functional_br_unit.rs2_valid = reservationStation_br_reg[i].rs2_valid;
            functional_br_unit.robIndex = reservationStation_br_reg[i].robIndex;
            functional_br_unit.pc = reservationStation_br_reg[i].pc;
            functional_br_unit.pc_next = reservationStation_br_reg[i].pc_next;
            functional_br_unit.br_pred = reservationStation_br_reg[i].br_pred;

            if (reservationStation_br_reg[i].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_br_unit.rs1_v = rd_v;
            end
            else begin
                functional_br_unit.rs1_v = br_rs1_v;
            end
            if (reservationStation_br_reg[i].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
                functional_br_unit.rs2_v = rd_v;
            end
            else begin
                functional_br_unit.rs2_v = br_rs2_v;
            end
            break;
        end
    end

    if (reservationStation_mem_reg[0].rs1_valid && reservationStation_mem_reg[0].rs2_valid && !mem_in_use && !unit_stall[2]) begin
        mem_dispatch = 1'b1;
        functional_mem_unit.inst = reservationStation_mem_reg[0].inst;
        functional_mem_unit.rs1_s = reservationStation_mem_reg[0].rs1_s;
        functional_mem_unit.rs2_s = reservationStation_mem_reg[0].rs2_s;
        functional_mem_unit.rd_s = reservationStation_mem_reg[0].rd_s;           // physical register from free list coming from dispatch
        functional_mem_unit.rd_v = reservationStation_mem_reg[0].rd_v;
        functional_mem_unit.opcode = reservationStation_mem_reg[0].opcode;
        functional_mem_unit.fuop = reservationStation_mem_reg[0].fuop;
        functional_mem_unit.funct3 = reservationStation_mem_reg[0].funct3;
        functional_mem_unit.sext_imm = reservationStation_mem_reg[0].sext_imm;
        functional_mem_unit.ALUsrc = reservationStation_mem_reg[0].ALUsrc;
        functional_mem_unit.filled = reservationStation_mem_reg[0].filled;
        functional_mem_unit.rs1_valid = reservationStation_mem_reg[0].rs1_valid;
        functional_mem_unit.rs2_valid = reservationStation_mem_reg[0].rs2_valid;
        functional_mem_unit.robIndex = reservationStation_mem_reg[0].robIndex;
        functional_mem_unit.pc = reservationStation_mem_reg[0].pc;
        if (reservationStation_mem_reg[0].rs1_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
            functional_mem_unit.rs1_v = rd_v;
        end
        else begin
            functional_mem_unit.rs1_v = mem_rs1_v;
        end
        if (reservationStation_mem_reg[0].rs2_s == cdb_phys_addr && (cdb_phys_addr != '0)) begin
            functional_mem_unit.rs2_v = rd_v;
        end
        else begin
            functional_mem_unit.rs2_v = mem_rs2_v;
        end
    end

end

regfile regfile (
  .clk (clk),
  .rst (rst),
  .regf_we (cdb_valid),                   //need to change later
  .rd_v (rd_v),
  .arith_rs1_s(reservationStation_arith_reg[arith_idx].rs1_s), 
  .arith_rs2_s(reservationStation_arith_reg[arith_idx].rs2_s),
  .mult_rs1_s(reservationStation_mult_reg[mult_idx].rs1_s), 
  .mult_rs2_s(reservationStation_mult_reg[mult_idx].rs2_s),
  .mem_rs1_s(reservationStation_mem_reg[0].rs1_s), 
  .mem_rs2_s(reservationStation_mem_reg[0].rs2_s),
  .br_rs1_s(reservationStation_br_reg[br_idx].rs1_s), 
  .br_rs2_s(reservationStation_br_reg[br_idx].rs2_s),
  .div_rs1_s(reservationStation_div_reg[div_idx].rs1_s),
  .div_rs2_s(reservationStation_div_reg[div_idx].rs2_s),
  .rd_s (cdb_phys_addr),
  .arith_rs1_v(arith_rs1_v), 
  .arith_rs2_v(arith_rs2_v),
  .mult_rs1_v(mult_rs1_v), 
  .mult_rs2_v(mult_rs2_v),
  .mem_rs1_v(mem_rs1_v), 
  .mem_rs2_v(mem_rs2_v),
  .br_rs1_v(br_rs1_v), 
  .br_rs2_v(br_rs2_v),
  .div_rs1_v(div_rs1_v),
  .div_rs2_v(div_rs2_v)
);


endmodule : reservationStation