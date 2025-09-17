/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;

    typedef enum logic [6:0] {
        op_b_lui   = 7'b0110111, // U load upper immediate 
        op_b_auipc = 7'b0010111, // U add upper immediate PC 
        op_b_jal   = 7'b1101111, // J jump and link 
        op_b_jalr  = 7'b1100111, // I jump and link register 
        op_b_br    = 7'b1100011, // B branch 
        op_b_load  = 7'b0000011, // I load 
        op_b_store = 7'b0100011, // S store 
        op_b_imm   = 7'b0010011, // I arith ops with register/immediate operands 
        op_b_reg   = 7'b0110011, // R arith ops with register operands 
        op_b_csr   = 7'b1110011  // I control and status register 
    } rv32i_op_b_t;

    typedef enum logic [6:0] {
        op_lui   = 7'b0110111, // U load upper immediate 
        op_auipc = 7'b0010111, // U add upper immediate PC 
        op_jal   = 7'b1101111, // J jump and link 
        op_jalr  = 7'b1100111, // I jump and link register 
        op_br    = 7'b1100011, // B branch 
        op_load  = 7'b0000011, // I load 
        op_store = 7'b0100011, // S store 
        op_imm   = 7'b0010011, // I arith ops with register/immediate operands 
        op_reg   = 7'b0110011, // R arith ops with register operands 
        op_csr   = 7'b1110011  // I control and status register 
    } rv32i_opcode;

    // Add more things here . . .
    typedef enum bit [2:0] {
        beq  = 3'b000,
        bne  = 3'b001,
        blt  = 3'b100,
        bge  = 3'b101,
        bltu = 3'b110,
        bgeu = 3'b111
    } branch_funct3_t;

    typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_funct3_t;

    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
    } store_funct3_t;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

    typedef enum bit [2:0] {
        alu_add = 3'b000,
        alu_sll = 3'b001,
        alu_sra = 3'b010,
        alu_sub = 3'b011,
        alu_xor = 3'b100,
        alu_srl = 3'b101,
        alu_or  = 3'b110,
        alu_and = 3'b111
    } alu_ops;

    typedef enum bit [2:0] {
        mul     = 3'b000,
        mulh    = 3'b001,
        mulhsu  = 3'b010,
        mulhu   = 3'b011
    } mul_funct3_t;

    typedef enum bit [2:0] {
        div = 3'b100,
        divu = 3'b101,
        rem = 3'b110,
        remu = 3'b111
    } div_funct3_t;

        // // Constants for multiplication case readability
    // `define UNSIGNED_UNSIGNED_MUL 2'b00
    // `define SIGNED_SIGNED_MUL     2'b01
    // `define SIGNED_UNSIGNED_MUL   2'b10
    typedef enum bit [2:0] {
        mul_uu      = 3'b000,
        mul_ss      = 3'b001,
        mul_su      = 3'b010
    } mul_ops;

endpackage

package module_types;
    localparam I_QUEUE_D_WIDTH = 64+32+1;
    localparam I_QUEUE_DEPTH = 32;

    // localparam S_BUFF_D_WIDTH = 64+4;
    // localparam S_BUF_DEPTH = 1;

    localparam ROB_DEPTH = 16;
    localparam ROB_ADDR_WIDTH = $clog2(ROB_DEPTH);
    localparam ROB_IDX_SIZE = $clog2(ROB_DEPTH);

    localparam PHYS_REGSIZE = 64;
    localparam HALF_PHYS_REGSIZE = 32;
    localparam HALF_PHYS_REG_ADDR = $clog2(HALF_PHYS_REGSIZE);

    localparam PHYS_REG_ADDR = $clog2(PHYS_REGSIZE);

    localparam RES_SIZE = 16;
    localparam RES_ADDR_WIDTH = $clog2(RES_SIZE);
    localparam MULT_RES_SIZE = 8;
    localparam M_RES_ADDR_WIDTH = $clog2(MULT_RES_SIZE);
    localparam BR_DIV_RES_SIZE = 8;
    localparam BD_RES_ADDR_WIDTH = $clog2(BR_DIV_RES_SIZE);


    localparam BTB_HEIGHT = 128;
    localparam BTB_SET_IDX = $clog2(BTB_HEIGHT);
    localparam BTB_TAG_SIZE = 32 - BTB_SET_IDX - 2;

    localparam BP_HEIGHT = 64;
    localparam BP_SET_IDX = $clog2(BP_HEIGHT);

    typedef struct packed {
        logic  valid;
        logic [63:0]  order;   
        logic [31:0]  inst;
        logic [4:0]  rs1_addr;
        logic [4:0] rs2_addr;
        logic [31:0] rs1_rdata;
        logic [31:0] rs2_rdata;
        logic [4:0] rd_addr;
        logic [31:0] rd_wdata;
        logic [31:0] pc_rdata;
        logic [31:0] pc_wdata;
        logic [31:0] mem_addr;
        logic [3:0]  mem_rmask;
        logic [3:0]  mem_wmask;
        logic [31:0] mem_rdata;
        logic [31:0] mem_wdata;
    } RVFI_signals_t;

    typedef struct packed {
        logic [31:0] inst;
        logic [PHYS_REG_ADDR-1:0]  rs1_s;
        logic [PHYS_REG_ADDR-1:0]  rs2_s;
        logic [PHYS_REG_ADDR-1:0]  rd_s;           // physical register from free list coming from dispatch
        // logic [31:0] rs1_v;
        // logic [31:0] rs2_v;
        logic [31:0] rd_v;
        logic [6:0] opcode;
        logic [2:0] fuop;
        logic [2:0] funct3;
        logic [31:0] sext_imm;
        logic ALUsrc;
        logic filled;
        logic rs1_valid;
        logic rs2_valid;
        logic [ROB_IDX_SIZE-1:0] robIndex;
        logic [31:0] pc;
        logic [31:0] pc_next;
        logic  br_pred;
    } reservationStation_reg_t;

    typedef struct packed {
        logic [31:0] inst;
        logic [PHYS_REG_ADDR-1:0]  rs1_s;
        logic [PHYS_REG_ADDR-1:0]  rs2_s;
        logic [PHYS_REG_ADDR-1:0]  rd_s;           // physical register from free list coming from dispatch
        logic [31:0] rs1_v;
        logic [31:0] rs2_v;
        logic [31:0] rd_v;
        logic [6:0] opcode;
        logic [2:0] fuop;
        logic [2:0] funct3;
        logic [31:0] sext_imm;
        logic ALUsrc;
        logic filled;
        logic rs1_valid;
        logic rs2_valid;
        logic [ROB_IDX_SIZE-1:0] robIndex;
        logic [31:0] pc;
        logic [31:0] pc_next;
        logic  br_pred;
    } functional_unit_t;


    typedef struct packed {
        RVFI_signals_t rvfi_signals;
        logic [PHYS_REG_ADDR-1:0]    phys_addr;
        logic [4:0]    rd_addr;
        logic store_inst;
        logic control_inst;
        logic br_inst;
        logic [31:0] pc;
        logic [31:0] pc_next;
        logic taken;
        // logic update;
        logic br_miss;
        logic ready;
    } rob_entry_t;

    typedef enum bit [2:0] {
        arith   = 3'b000,
        comp    = 3'b001,
        mult    = 3'b010,
        agen    = 3'b011,
        branch  = 3'b100,
        division = 3'b101
    } func_unit_sel_t;

    typedef struct packed {
        logic [31:0]        inst;
        logic               ALUsrc;
        logic   [2:0]       fuop;
        logic   [4:0]       rd_addr;
        logic   [4:0]       rs1_addr;
        logic   [4:0]       rs2_addr;
        logic   [31:0]      sext_imm;
        logic   [6:0]       funct7; //might not need this
        logic   [2:0]       funct3;
        logic   [6:0]       opcode; //maybe I can use less bits for this
        func_unit_sel_t     func_unit_sel;
        logic [31:0] pc;
        logic [31:0] pc_next;
        logic  br_pred;

    } decoded_output_t;

    typedef struct packed {
        logic [PHYS_REG_ADDR-1:0]     phys_addr;
        logic           RAT_valid;
    } rat_entry_t;

    typedef struct packed {
        logic [31:0] data;
        logic valid;
        logic [PHYS_REG_ADDR-1:0] commit_phys_rd_addr;
        logic [4:0] commit_arch_rd_addr;
        logic [ROB_IDX_SIZE-1:0] ROB_id;
        logic [31:0] mem_addr;
        logic [3:0] mem_rmask;
        logic [3:0] mem_wmask;
        logic [31:0] mem_wdata;
        logic [31:0] mem_rdata;
        logic [31:0] pc_next;
        logic br_miss;
        logic br_en;
    } cdb_output_t;

    typedef struct packed {
        logic [31:0] mem_addr;
        logic [31:0] mem_wdata;
        logic [3:0] mem_wmask;
    } store_buf_entry_t;


    typedef struct packed{
        // memory side signals, dfp -> downward facing port
        logic   [31:0]  dfp_addr;
        logic           dfp_read;
        logic           dfp_write;
        logic   [255:0] dfp_rdata;
        logic   [255:0] dfp_wdata;
        logic           dfp_resp;
    } cache_dfp_port_t;

    typedef struct packed {
        logic [31:0] target_addr;
        logic [BTB_TAG_SIZE-1:0] tag;
        logic  valid;
    } BTB_read_t;

    typedef enum bit [1:0] {  
        STRONGLY_NOT, WEAKLY_NOT, WEAKLY_TAKEN, STRONGLY_TAKEN
    } TWO_BIT_SAT_COUNTER;

endpackage