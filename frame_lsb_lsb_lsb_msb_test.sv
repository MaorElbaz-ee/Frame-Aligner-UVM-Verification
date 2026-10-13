class frame_lsb_lsb_lsb_msb_test extends frame_base_test;

    `uvm_component_utils(frame_lsb_lsb_lsb_msb_test)

    function new(string name = "frame_lsb_lsb_lsb_msb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    // one frame of  AA AA AA AF + 8 clean payload bytes
    task send_planted_b();
        frame_lsb_in_msb_seq seq;
        seq = frame_lsb_in_msb_seq::type_id::create("seq");
        seq.extra_lsb = 1'b1;
        seq.start(env.agent.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        send_planted_b();
        send_planted_b();
        send_planted_b();

        send_planted_b();

        drain();
        phase.drop_objection(this);
    endtask

endclass
