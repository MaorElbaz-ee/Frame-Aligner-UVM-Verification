class frame_base_test extends uvm_test;

    `uvm_component_utils(frame_base_test)

    frame_env env;
    virtual frame_interface vif;

    function new(string name = "frame_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        env = frame_env::type_id::create("env", this);

        if (!uvm_config_db#(virtual frame_interface)::get(this, "", "frame_vif", vif))
            `uvm_fatal("TEST", "Could not get frame_interface from uvm_config_db")

        set_report_max_quit_count(10);
    endfunction

    // let the last frame drain through the DUT and the monitor.
    virtual task drain();
        repeat (20) @(posedge vif.clk);
    endtask

endclass