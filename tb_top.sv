`timescale 1ns/1ps

module tb_top;

    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import frame_pkg::*;

    logic clk = 1'b0;
    logic reset;

    always #5 clk = ~clk;// 100 MHz

    frame_interface vif (.clk(clk), .reset(reset));

    frame_aligner dut (
        .clk(clk),
        .rx_data(vif.rx_data),
        .reset(reset),
        .fr_byte_position(vif.fr_byte_position),
        .frame_detect(vif.frame_detect)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_top);
    end

    initial begin
        reset = 1'b1;
        repeat (5) @(posedge clk);
        reset = 1'b0;
    end

    initial begin
        uvm_config_db#(virtual frame_interface)::set(null, "*", "frame_vif", vif);
        run_test("frame_lock_test");
    end

endmodule