class my_agent extends uvm_agent;

    `uvm_component_utils(my_agent)

    frame_driver driver;
    frame_sequencer sequencer;
    frame_monitor monitor;

    function new(string name = "my_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        monitor = frame_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            driver    = frame_driver::type_id::create("driver", this);
            sequencer = frame_sequencer::type_id::create("sequencer", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction

endclass