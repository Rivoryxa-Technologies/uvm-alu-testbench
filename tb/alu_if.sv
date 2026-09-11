// tb/alu_if.sv - DUT interface with driver and monitor clocking blocks.
`timescale 1ns/1ps
interface alu_if #(parameter int WIDTH = 32) (input logic clk, input logic rst_n);
  logic             in_valid;
  logic [WIDTH-1:0] a;
  logic [WIDTH-1:0] b;
  logic [2:0]       op;
  logic             out_valid;
  logic [WIDTH-1:0] result;

  clocking drv_cb @(posedge clk);
    default input #1step output #1;
    output in_valid, a, b, op;
  endclocking

  clocking mon_cb @(posedge clk);
    default input #1step;
    input in_valid, a, b, op, out_valid, result;
  endclocking

  modport DRV (clocking drv_cb, input clk, input rst_n);
  modport MON (clocking mon_cb, input clk, input rst_n);
endinterface
