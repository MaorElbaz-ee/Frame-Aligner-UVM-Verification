import uvm_pkg::*;
`include "uvm_macros.svh"
import frame_types_pkg::*;

class frame_monitor extends uvm_monitor;

    `uvm_component_utils(frame_monitor)

    uvm_analysis_port #(frame_report_s) mon_port;
    virtual frame_interface frame_vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_port = new("mon_port", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual frame_interface)::get(this, "", "frame_vif", frame_vif)) begin
            `uvm_fatal("MON", "Could not get frame_interface from uvm_config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_report_s sample;

        wait (frame_vif.reset === 1'b0);
        forever begin
            @(frame_vif.mon_cb);

            sample = '{default: '0};

            sample.rx_data              = frame_vif.mon_cb.rx_data;
            sample.fr_byte_position     = frame_vif.mon_cb.fr_byte_position;
            sample.frame_detect         = frame_vif.mon_cb.frame_detect;

            mon_port.write(sample);
        end
    endtask
endclass