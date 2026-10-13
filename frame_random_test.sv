class frame_random_test extends frame_base_test;

    `uvm_component_utils(frame_random_test)

    int unsigned num_frames = 50;

    function new(string name = "frame_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        void'($value$plusargs("num_frames=%d", num_frames));

        set_report_max_quit_count(100000);
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_weighted_random_seq seq;
        frame_lock_seq            preamble;

        phase.raise_objection(this);

        `uvm_info("RAND_TEST", "phase 1: 4 clean frames to acquire alignment", UVM_LOW)
        preamble = frame_lock_seq::type_id::create("preamble");
        preamble.num_frames = 4;
        preamble.start(env.agent.sequencer);

        // ---- Phase 2 : soak ----
        `uvm_info("RAND_TEST",
                  $sformatf("phase 2: constrained-random soak, %0d frames", num_frames),
                  UVM_LOW)

        // The weighted variant. frame_random_seq (its unbiased parent) is still
        // available if you want the plain-random baseline for comparison.
        seq = frame_weighted_random_seq::type_id::create("seq");
        seq.num_frames = num_frames;
        seq.start(env.agent.sequencer);

        drain();
        phase.drop_objection(this);
    endtask

endclass
