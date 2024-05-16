.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # addi x1, x0, 5  # x1 <= 4
    # nop             # nops in between to prevent hazard
    # nop
    # addi x3, x1, 8  # x3 <= x1 + 8

    # Add your own test cases here! 
    auipc x24, 0

    add x26, x0, x0

    addi x25, x24, 1

    addi x30, x26, 1

    sub x2, x1, x3  # x2 = -8

    addi x2, x2, 20  # x2 = 12

    sll x4, x2, x1  # x4 = c0 decimal 192
 
    add x5, x2, x1  # x5 = 16

    slt x6, x1, x2  # x6 = 0

    # nop
    sltu x7, x1, x2  # x7 = 1

    xor x8, x1, x2  # x8 = 8

    srl x9, x7, x2  # x9 = 6

    auipc x24, 0
    # addi x1, x0, 1
    # addi x2, x0, 2
    addi x4, x0, 3
    addi x5, x0, 4

    addi x10, x7, -20  # x10 = -19
   
    sra x11, x8, x10   # x11 = 0

    or x12, x5, x8   # x12 = 24

    and x13, x12, x8   # x13 = 8

    lui x14, 10   # x13 = 40960

    auipc x15, 5   # x15 = 1610633576

    slti x16, x13, 4   # x13 = 40960
  
    sltiu x17, x13, 4   # x13 = 40960
  
    xori x18, x13, 7   # x13 = 40960
 
    or x19, x13, 7   # x13 = 40960
  
    andi x20, x13, 7   # x13 = 40960

    slli x21, x13, 7   # x13 = 40960
  
    srli x22, x13, 7   # x13 = 40960
  
    srai x23, x13, 7   # x13 = 40960

    slti x0, x0, -256 # this is the magic instruction to end the simulation

# .section .data

# DATA1: .word 0x60000000