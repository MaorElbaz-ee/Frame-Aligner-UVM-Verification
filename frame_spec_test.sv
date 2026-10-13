class frame_spec_test extends frame_base_test;

    `uvm_component_utils(frame_spec_test)

    function new(string name = "frame_spec_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task banner(string s);
        `uvm_info("SPEC", $sformatf("---------- %s ----------", s), UVM_LOW)
    endtask

    // num legal frames of one header type, payload free of 0xAA / 0x55.
    task send_clean(frame_item::header_type_t t, int unsigned num);
        frame_clean_seq seq;
        seq = frame_clean_seq::type_id::create("seq");
        seq.hdr_type    = t;
        seq.num_frames  = num;
        seq.payload_len = 10;
        seq.start(env.agent.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        frame_illegal_seq bad;

        phase.raise_objection(this);

        banner("1. 5 x HEAD_1 (0xAFAA) - acquire on frame 3, hold through 5");
        send_clean(frame_item::HEAD_1, 5);

        banner("2. 4 x ILLEGAL = 48 non-aligned bytes - unlock on the last byte");
        bad = frame_illegal_seq::type_id::create("bad");
        bad.num_frames = 4;
        bad.start(env.agent.sequencer);

        banner("3. 5 x HEAD_2 (0xBA55) - re-acquire on the other header pattern");
        send_clean(frame_item::HEAD_2, 5);

        drain();
        phase.drop_objection(this);
    endtask

endclass
