class frame_na47_hdr_test extends frame_base_test;

    `uvm_component_utils(frame_na47_hdr_test)

    function new(string name = "frame_na47_hdr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        set_report_max_quit_count(1000);
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_lock_seq good;
        frame_illegal_seq bad;
        frame_payload_hdr_seq planted;

        phase.raise_objection(this);

        // lock
        good = frame_lock_seq::type_id::create("good");
        good.num_frames = 4;
        good.start(env.agent.sequencer);

        // 36 non-aligned bytes
        bad = frame_illegal_seq::type_id::create("bad");
        bad.num_frames = 3;
        bad.start(env.agent.sequencer);

        // bytes 37-48: bad header, AA AF on bytes 47,48
        `uvm_info("NA47", "header AA AF completes on the 48th non-aligned byte - check frame_detect on the next cycle", UVM_LOW)
        planted = frame_payload_hdr_seq::type_id::create("planted");
        planted.hdr_kind_h = frame_payload_hdr_seq::HDR_BAD_LSB;
        planted.plant_pair = 1'b1;
        planted.payload_location = 8;
        planted.start(env.agent.sequencer);

        // good frames on the original grid - relock
        good = frame_lock_seq::type_id::create("good2");
        good.num_frames = 4;
        good.start(env.agent.sequencer);

        drain();
        phase.drop_objection(this);
    endtask

endclass
