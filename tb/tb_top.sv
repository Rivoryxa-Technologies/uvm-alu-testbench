// tb/tb_top.sv - top-level testbench: clock, reset, DUT, interface, run_test.
`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import alu_pkg::*;

  logic clk;
  logic rst_n;

  always #5 clk = ~clk;             // 100 MHz

  alu_if #(.WIDTH(32)) vif (.clk(clk), .rst_n(rst_n));

  alu #(.WIDTH(32)) dut (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (vif.in_valid),
    .a         (vif.a),
    .b         (vif.b),
    .op        (vif.op),
    .out_valid (vif.out_valid),
    .result    (vif.result)
  );

  initial begin
    clk   = 1'b0;
    rst_n = 1'b0;
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual alu_if)::set(null, "*", "vif", vif);
    run_test("alu_base_test");
  end
endmodule
