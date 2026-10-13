class frame_regression_test extends frame_base_test;

    `uvm_component_utils(frame_regression_test)

    function new(string name = "frame_regression_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // The run must reach the end regardless of how many errors accumulate -
        // an unreached section is an unreached coverage bin.
        set_report_max_quit_count(1000000);
    endfunction

    task banner(string s);
        `uvm_info("REGR", $sformatf("---------- %s ----------", s), UVM_LOW)
    endtask

    task send_good(int unsigned num);
        frame_lock_seq good;
        good = frame_lock_seq::type_id::create("good");
        good.num_frames = num;
        good.start(env.agent.sequencer);
    endtask

    task send_illegal(int unsigned num);
        frame_illegal_seq bad;
        bad = frame_illegal_seq::type_id::create("bad");
        bad.num_frames = num;
        bad.start(env.agent.sequencer);
    endtask

    task send_typed(frame_item::header_type_t t);
        frame_base_seq seq;
        seq = frame_base_seq::type_id::create("seq");
        seq.hdr_type    = t;
        seq.num_frames  = 1;
        seq.payload_len = 10;
        seq.start(env.agent.sequencer);
    endtask

    task send_cross(bit [15:0] v);
        frame_cross_hdr_seq seq;
        seq = frame_cross_hdr_seq::type_id::create("seq");
        seq.cross_header = v;
        seq.start(env.agent.sequencer);
    endtask

    task send_planted(frame_payload_hdr_seq::hdr_kind k, bit plant = 1'b1);
        frame_payload_hdr_seq seq;
        seq = frame_payload_hdr_seq::type_id::create("seq");
        seq.hdr_kind_h       = k;
        seq.plant_pair       = plant;
        seq.payload_location = 3;
        seq.start(env.agent.sequencer);
    endtask

    task send_cross_retest(bit swap);
        frame_cross_retest_seq seq;
        seq = frame_cross_retest_seq::type_id::create("seq");
        seq.swap = swap;
        seq.start(env.agent.sequencer);
    endtask

    task flush_alignment();
        banner("  ... flushing alignment (60 clean bytes)");
        send_cross(16'h1234);
        send_cross(16'h1234);
        send_cross(16'h1234);
        send_cross(16'h1234);
        send_cross(16'h1234);
    endtask

    task send_lsb_run(bit extra);
        frame_lsb_in_msb_seq seq;
        seq = frame_lsb_in_msb_seq::type_id::create("seq");
        seq.extra_lsb = extra;
        seq.start(env.agent.sequencer);
    endtask

//--------------------------------------------------------------------------

    virtual task run_phase(uvm_phase phase);
        frame_weighted_random_seq rand_seq;
        frame_random_seq          plain_seq;

        phase.raise_objection(this);

        // ---- 1. acquisition and hold ----
        // Covers: fd 0->1, positions 0..11, the 11->0 frame boundary.
        banner("1 - lock: 6 clean HEAD_1 frames");
        send_good(6);

        // ---- 2. loss of alignment and re-acquisition ----
        // Covers: fd 1->0, the 48-byte na path, fd 0->1 a second time.
        banner("2 - unlock: 4 good, 4 illegal, 4 good");
        send_good(4);
        send_illegal(4);
        send_good(4);

        // ---- 3. both header patterns ----
        // Covers: the H2 byte classes (55, BA), which sections 1-2 never produce.
        banner("3 - mixed headers: HEAD_1 / HEAD_2 alternating");
        send_typed(frame_item::HEAD_1);
        send_typed(frame_item::HEAD_2);
        send_typed(frame_item::HEAD_1);
        send_typed(frame_item::HEAD_2);

        // ---- 4. cross-pattern headers ----
        // Covers: PAT_CROSS - the LSB of one pattern with the MSB of the other.
        banner("4 - bug 3: cross headers: BAAA / AF55");
        send_cross(16'hBAAA);
        send_cross(16'hAF55);
        send_cross(16'hBAAA);
        send_cross(16'hAF55);
        send_good(4);

        // ---- 5. header bytes inside a payload, while UNALIGNED ----
        // Legitimate re-anchoring. The control for section 6.
        banner("5 - planted header in payload, block not aligned");
        send_planted(frame_payload_hdr_seq::HDR_BAD_LSB);
        send_planted(frame_payload_hdr_seq::HDR_BAD_MSB);
        send_good(4);

        // ---- 6. header bytes inside a payload, while ALIGNED ----
        banner("6 - bug 1: planted header in payload, block aligned");
        send_planted(frame_payload_hdr_seq::HDR_VALID);
        send_good(4);
        send_planted(frame_payload_hdr_seq::HDR_BAD_LSB, 1'b1);
        send_good(6);

        // ---- 7. a valid LSB sitting in the MSB slot ----
        flush_alignment();
        banner("7 - bug 2: AA AA AF (never acquired)");
        send_lsb_run(1'b0);
        send_lsb_run(1'b0);
        send_lsb_run(1'b0);

        flush_alignment();
        banner("7b - CONTROL: AA AA AA AF (acquired)");
        send_lsb_run(1'b1);
        send_lsb_run(1'b1);
        send_lsb_run(1'b1);
        send_lsb_run(1'b1);

        // ---- 7c. the same case across header patterns ----
        flush_alignment();
        banner("7c - bug 2 across patterns: AA 55 BA");
        send_cross_retest(1'b0);
        send_cross_retest(1'b0);
        send_cross_retest(1'b0);

        flush_alignment();
        banner("7d - bug 2 across patterns: 55 AA AF");
        send_cross_retest(1'b1);
        send_cross_retest(1'b1);
        send_cross_retest(1'b1);

        // ---- 8. constrained-random soak ----
        // Off-grid payload lengths and unconstrained payload bytes: the only
        // section whose stimulus was not written by hand.
        banner("8 - constrained-random soak");
        send_good(4);                       // re-acquire before the soak
        rand_seq = frame_weighted_random_seq::type_id::create("rand_seq");
        rand_seq.num_frames = 50;
        rand_seq.start(env.agent.sequencer);

        banner("8b - unbiased random soak");
        send_good(4);
        plain_seq = frame_random_seq::type_id::create("plain_seq");
        plain_seq.num_frames = 25;
        plain_seq.start(env.agent.sequencer);

        banner("regression complete");
        drain();
        phase.drop_objection(this);
    endtask

endclass
