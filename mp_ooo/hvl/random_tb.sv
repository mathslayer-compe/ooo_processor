//-----------------------------------------------------------------------------
// Title         : random_tb
// Project       : ECE 411 mp_verif
//-----------------------------------------------------------------------------
// File          : random_tb.sv
// Author        : ECE 411 Course Staff
//-----------------------------------------------------------------------------
// IMPORTANT: If you don't change the random seed, every time you do a `make run`
// you will run the /same/ random test. SystemVerilog calls this "random stability",
// and it's to ensure you can reproduce errors as you try to fix the DUT. Make sure
// to change the random seed or run more instructions if you want more extensive
// coverage.
//------------------------------------------------------------------------------
module random_tb
import rv32i_types::*;
(
  mem_itf.mem itf_i,
  mem_itf.mem itf_d
);

  `include "../../hvl/randinst.svh"

  RandInst gen = new();

  // Do a bunch of LUIs to get useful register state.
  task init_register_state();
    for (int i = 0; i < 32; ++i) begin
      @(posedge itf_i.clk iff itf_i.rmask);
        gen.randomize() with {
        instr.j_type.opcode == op_lui;
        instr.j_type.rd == i[4:0];
      };

      // int bla = 5;
      // #(bla);
      // Your code here: package these memory interactions into a task.
      itf_i.rdata <= gen.instr.word;
      itf_i.resp <= 1'b1;
      // @(posedge itf_i.clk) itf_i.resp <= 1'b0;
    end
  endtask : init_register_state

  // Note that this memory model is not consistent! It ignores
  // writes and always reads out a random, valid instruction.
  task run_random_instrs();
    repeat (300000) begin
      @(posedge itf_i.clk iff (itf_i.rmask | itf_d.rmask | itf_d.wmask));

      // if (itf_i.read && itf_i.write) begin
      //   $error("Simultaneous read and write to memory model!");
      // end

      // itf_i.resp <= 1'b1;
      // Always read out a valid instruction.
      if (itf_i.rmask) begin
        // gen.randomize();
        gen.randomize() with {
          instr.i_type.opcode == op_br;
          // instr.j_type.rd == i[4:0];
        };
        itf_i.rdata <= gen.instr.word;
      end
      // @(posedge itf_i.clk iff (itf_i.rmask));
      // if (itf_i.rmask) begin
      //   itf_i.rdata <= 32'h13;
      // end
      // @(posedge itf_i.clk iff (itf_i.rmask));
      // if (itf_i.rmask) begin
      //   itf_i.rdata <= 32'h13;
      // end
      // @(posedge itf_i.clk iff (itf_i.rmask));
      // if (itf_i.rmask) begin
      //   itf_i.rdata <= 32'h13;
      // end
      // @(posedge itf_i.clk iff (itf_i.rmask));
      // if (itf_i.rmask) begin
      //   itf_i.rdata <= 32'h13;
      // end


      // If it's a write, do nothing and just respond.
      itf_i.resp <= 1'b1;
      // @(posedge itf_i.clk) itf_i.resp <= 1'b0;
    end
  endtask : run_random_instrs

  // A single initial block ensures random stability.
  initial begin
    itf_i.resp <= 1'b0;
    itf_d.rdata <= 1'b0;

    // Wait for reset.
    // @(posedge itf_i.clk iff itf_i.rst == 1'b0);
    repeat (2) @(posedge itf_i.clk);

    // Get some useful state into the processor by loading in a bunch of state.
    init_register_state();

    // Run!
    run_random_instrs();

    // Finish up
    $display("Random testbench finished!");
    $finish;
  end

endmodule : random_tb