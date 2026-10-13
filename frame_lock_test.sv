class frame_lock_test extends frame_base_test;

    `uvm_component_utils(frame_lock_test)

    function new(string name = "frame_lock_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_lock_seq seq;

        phase.raise_objection(this);

        seq = frame_lock_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        drain();

        phase.drop_objection(this);
    endtask

endclass