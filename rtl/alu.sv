// rtl/alu.sv - registered ALU DUT for the UVM testbench.
// Inputs are captured when in_valid is high; result and out_valid appear the
// following cycle (one-cycle pipeline latency).
`timescale 1ns/1ps
module alu #(
  parameter int WIDTH = 32
)(
  input  logic             clk,
  input  logic             rst_n,
  input  logic             in_valid,
  input  logic [WIDTH-1:0] a,
  input  logic [WIDTH-1:0] b,
  input  logic [2:0]       op,
  output logic             out_valid,
  output logic [WIDTH-1:0] result
);
  localparam logic [2:0] OP_ADD = 3'd0;
  localparam logic [2:0] OP_SUB = 3'd1;
  localparam logic [2:0] OP_AND = 3'd2;
  localparam logic [2:0] OP_OR  = 3'd3;
  localparam logic [2:0] OP_XOR = 3'd4;
  localparam logic [2:0] OP_SLL = 3'd5;
  localparam logic [2:0] OP_SRL = 3'd6;
  localparam logic [2:0] OP_SLT = 3'd7;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      out_valid <= 1'b0;
      result    <= '0;
    end else begin
      out_valid <= in_valid;
      unique case (op)
        OP_ADD: result <= a + b;
        OP_SUB: result <= a - b;
        OP_AND: result <= a & b;
        OP_OR : result <= a | b;
        OP_XOR: result <= a ^ b;
        OP_SLL: result <= a << b[4:0];
        OP_SRL: result <= a >> b[4:0];
        OP_SLT: result <= ($signed(a) < $signed(b)) ? {{(WIDTH-1){1'b0}}, 1'b1}
                                                     : '0;
        default: result <= '0;
      endcase
    end
  end
endmodule
