// tb/alu_pkg.sv - UVM environment for the ALU: transaction, sequence, driver,
// monitor, agent, scoreboard, coverage, env, and test.
`timescale 1ns/1ps
package alu_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  localparam int WIDTH = 32;

  // ------------------------------------------------------------ sequence item
  class alu_item extends uvm_sequence_item;
    rand bit [WIDTH-1:0] a;
    rand bit [WIDTH-1:0] b;
    rand bit [2:0]       op;
    bit [WIDTH-1:0]      result;  // captured by the monitor on the output beat

    `uvm_object_utils_begin(alu_item)
      `uvm_field_int(a,      UVM_ALL_ON)
      `uvm_field_int(b,      UVM_ALL_ON)
      `uvm_field_int(op,     UVM_ALL_ON)
      `uvm_field_int(result, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "alu_item");
      super.new(name);
    endfunction
  endclass

  // ---------------------------------------------------------------- sequence
  class alu_random_seq extends uvm_sequence #(alu_item);
    `uvm_object_utils(alu_random_seq)
    int unsigned num = 200;

    function new(string name = "alu_random_seq");
      super.new(name);
    endfunction

    task body();
      repeat (num) begin
        alu_item tr = alu_item::type_id::create("tr");
        start_item(tr);
        if (!tr.randomize())
          `uvm_error("SEQ", "randomize failed")
        finish_item(tr);
      end
    endtask
  endclass

  // ------------------------------------------------------------------ driver
  class alu_driver extends uvm_driver #(alu_item);
    `uvm_component_utils(alu_driver)
    virtual alu_if vif;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
        `uvm_fatal("DRV", "no virtual interface set for driver")
    endfunction

    task run_phase(uvm_phase phase);
      vif.drv_cb.in_valid <= 1'b0;
      wait (vif.rst_n === 1'b1);
      forever begin
        alu_item tr;
        seq_item_port.get_next_item(tr);
        @(vif.drv_cb);
        vif.drv_cb.in_valid <= 1'b1;
        vif.drv_cb.a        <= tr.a;
        vif.drv_cb.b        <= tr.b;
        vif.drv_cb.op       <= tr.op;
        @(vif.drv_cb);
        vif.drv_cb.in_valid <= 1'b0;
        seq_item_port.item_done();
      end
    endtask
  endclass

  // ----------------------------------------------------------------- monitor
  class alu_monitor extends uvm_monitor;
    `uvm_component_utils(alu_monitor)
    virtual alu_if vif;
    uvm_analysis_port #(alu_item) ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual alu_if)::get(this, "", "vif", vif))
        `uvm_fatal("MON", "no virtual interface set for monitor")
    endfunction

    task run_phase(uvm_phase phase);
      forever begin
        @(vif.mon_cb);
        if (vif.mon_cb.in_valid) begin
          alu_item tr = alu_item::type_id::create("tr");
          tr.a  = vif.mon_cb.a;
          tr.b  = vif.mon_cb.b;
          tr.op = vif.mon_cb.op;
          @(vif.mon_cb);              // registered output is valid next cycle
          tr.result = vif.mon_cb.result;
          ap.write(tr);
        end
      end
    endtask
  endclass

  // ------------------------------------------------------------------- agent
  class alu_agent extends uvm_agent;
    `uvm_component_utils(alu_agent)
    alu_driver                 drv;
    alu_monitor                mon;
    uvm_sequencer #(alu_item)  seqr;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      mon = alu_monitor::type_id::create("mon", this);
      if (get_is_active() == UVM_ACTIVE) begin
        drv  = alu_driver::type_id::create("drv", this);
        seqr = uvm_sequencer#(alu_item)::type_id::create("seqr", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      if (get_is_active() == UVM_ACTIVE)
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
  endclass

  // -------------------------------------------------------------- scoreboard
  class alu_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(alu_scoreboard)
    uvm_analysis_imp #(alu_item, alu_scoreboard) imp;
    int unsigned matched;
    int unsigned mismatched;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      imp = new("imp", this);
    endfunction

    function bit [WIDTH-1:0] predict(alu_item tr);
      case (tr.op)
        3'd0: return tr.a + tr.b;
        3'd1: return tr.a - tr.b;
        3'd2: return tr.a & tr.b;
        3'd3: return tr.a | tr.b;
        3'd4: return tr.a ^ tr.b;
        3'd5: return tr.a << tr.b[4:0];
        3'd6: return tr.a >> tr.b[4:0];
        3'd7: return ($signed(tr.a) < $signed(tr.b)) ? {{(WIDTH-1){1'b0}}, 1'b1}
                                                     : '0;
        default: return '0;
      endcase
    endfunction

    function void write(alu_item tr);
      bit [WIDTH-1:0] exp = predict(tr);
      if (tr.result === exp) begin
        matched++;
      end else begin
        mismatched++;
        `uvm_error("SCB", $sformatf("op=%0d a=%0h b=%0h exp=%0h got=%0h",
                                    tr.op, tr.a, tr.b, exp, tr.result))
      end
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("SCB", $sformatf("matched=%0d mismatched=%0d",
                                 matched, mismatched), UVM_LOW)
      if (mismatched != 0)
        `uvm_error("SCB", "there were mismatches")
    endfunction
  endclass

  // ---------------------------------------------------------------- coverage
  class alu_coverage extends uvm_subscriber #(alu_item);
    `uvm_component_utils(alu_coverage)
    alu_item item;

    covergroup cg;
      coverpoint item.op { bins ops[] = {[0:7]}; }
    endgroup

    function new(string name, uvm_component parent);
      super.new(name, parent);
      cg = new();
    endfunction

    function void write(alu_item t);
      item = t;
      cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
      `uvm_info("COV", $sformatf("opcode coverage = %0.1f%%", cg.get_coverage()),
                UVM_LOW)
    endfunction
  endclass

  // --------------------------------------------------------------------- env
  class alu_env extends uvm_env;
    `uvm_component_utils(alu_env)
    alu_agent      agent;
    alu_scoreboard scb;
    alu_coverage   cov;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = alu_agent::type_id::create("agent", this);
      scb   = alu_scoreboard::type_id::create("scb", this);
      cov   = alu_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(scb.imp);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass

  // -------------------------------------------------------------------- test
  class alu_base_test extends uvm_test;
    `uvm_component_utils(alu_base_test)
    alu_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = alu_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      alu_random_seq seq = alu_random_seq::type_id::create("seq");
      phase.raise_objection(this);
      seq.start(env.agent.seqr);
      #100ns;                        // let the pipeline drain
      phase.drop_objection(this);
    endtask
  endclass
endpackage
