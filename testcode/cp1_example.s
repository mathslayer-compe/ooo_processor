.section .text
.globl _start
_start:
    addi x1, x0, 4   # x1 <= 4
    addi x3, x1, 8   # x3 <= x1 + 8
    addi x1, x0, 4   # x1 <= 4
    addi x3, x1, 8   # x3 <= x1 + 8
    lui x2, 2        # x2 <= (2 << 'd12)
    auipc x7, 8      # X <= PC + (8 << 'd12)

    # Test Writing to x0, should not write
    lui x0, 5        # x0 <= 5

    # Test immediate operand instructions
    addi x2, x1, 0x123 
    slti x3, x2, 0x123 
    sltiu x4, x3, 0x123 
    xori x5, x4, 0x123 
    ori x6, x5, 0x123 
    andi x7, x6, 0x123 
    slli x8, x7, 0xF 
    srli x9, x8, 0xF 
    srai x10, x9, 0xF 

    # Test register operand instructions
    add x11, x10, x9
    add x12, x11, x10
    sub x13, x12, x11
    sub x14, x13, x12
    sll x15, x14, x13
    sll x16, x15, x14
    slt x17, x16, x15
    slt x18, x17, x16
    sltu x19, x18, x17
    sltu x20, x19, x18
    xor x21, x20, x19
    xor x22, x21, x20
    srl x23, x22, x21
    srl x24, x23, x22
    sra x25, x24, x23
    sra x26, x25, x24
    or x27, x26, x25
    or x28, x27, x26
    and x29, x28, x27
    and x30, x29, x28
    and x31, x30, x29
    

    # # Test load/store instructions
    addi x2, x0, 8
    lui x7, 0x70000
    sb x2, 0(x7)
    sb x2, 1(x7)
    sb x2, 2(x7)
    sb x2, 3(x7)
    lw x3, 0(x7)
    sh x2, 0(x7)
    sh x2, 2(x7)
    lw x3, 0(x7)

    # # Create a new test value 0x89ABCDEF
    lui x2, 0x89ABD
    sw x2, 0(x7)
    lw x3, 0(x7)
    lh x2, 0(x7)
    lh x2, 2(x7)
    lb x2, 0(x7)
    lb x2, 1(x7)
    lb x2, 2(x7)
    lb x2, 3(x7)
    lhu x2, 0(x7)
    lhu x2, 2(x7)
    lbu x2, 0(x7)
    lbu x2, 1(x7)
    lbu x2, 2(x7)
    lbu x2, 3(x7)

    # Add your own test cases here!

    # Additional store/load cases using x8 through x31
    # Set base address in x8
    lui x8, 0x70000

    # Store byte values
    li x9, 0x1
    li x10, 0x2
    li x11, 0x3
    li x12, 0x4
    li x13, 0x5
    li x14, 0x6
    li x15, 0x7
    li x16, 0x8
    li x17, 0x9
    li x18, 0xA
    li x19, 0xB
    li x20, 0xC
    li x21, 0xD
    li x22, 0xE
    li x23, 0xF
    li x24, 0x10
    li x25, 0x11
    li x26, 0x12
    li x27, 0x13
    li x28, 0x14
    li x29, 0x15
    li x30, 0x16

    # Store bytes to memory
    sb x9, 0(x8)
    sb x10, 1(x8)
    sb x11, 2(x8)
    sb x12, 3(x8)
    sb x13, 4(x8)
    sb x14, 5(x8)
    sb x15, 6(x8)
    sb x16, 7(x8)
    sb x17, 8(x8)
    sb x18, 9(x8)
    sb x19, 10(x8)
    sb x20, 11(x8)
    sb x21, 12(x8)
    sb x22, 13(x8)
    sb x23, 14(x8)
    sb x24, 15(x8)
    sb x25, 16(x8)
    sb x26, 17(x8)
    sb x27, 18(x8)
    sb x28, 19(x8)
    sb x29, 20(x8)
    sb x30, 21(x8)

    # Load bytes from memory
    lb x9, 0(x8)
    lb x10, 1(x8)
    lb x11, 2(x8)
    lb x12, 3(x8)
    lb x13, 4(x8)
    lb x14, 5(x8)
    lb x15, 6(x8)
    lb x16, 7(x8)
    lb x17, 8(x8)
    lb x18, 9(x8)
    lb x19, 10(x8)
    lb x20, 11(x8)
    lb x21, 12(x8)
    lb x22, 13(x8)
    lb x23, 14(x8)
    lb x24, 15(x8)
    lb x25, 16(x8)
    lb x26, 17(x8)
    lb x27, 18(x8)
    lb x28, 19(x8)
    lb x29, 20(x8)
    lb x30, 21(x8)



halt:                 
    slti x0, x0, -256

