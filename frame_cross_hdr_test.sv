class frame_cross_hdr_test extends frame_base_test;

    `uvm_component_utils(frame_cross_hdr_test)

    function new(string name = "frame_cross_hdr_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task send_cross(bit[15:0] v);
        frame_cross_hdr_seq seq;
        seq = frame_cross_hdr_seq::type_id::create("seq");
        seq.cross_header = v;
        seq.start(env.agent.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        frame_lock_seq good;
        
        phase.raise_objection(this);
        // sending cross headers - lsb1 with msb2 and lsb2 with msb1
        //frame detect should be equal 0
        // lfc should be na/0
        send_cross(16'hBAAA);
        send_cross(16'hAF55);
        send_cross(16'hBAAA);
        send_cross(16'hAF55);
        send_cross(16'hBAAA);
        send_cross(16'hAF55);

        // sending good frames to see lock
        good = frame_lock_seq::type_id::create("good");
        good.num_frames = 4;
        good.start(env.agent.sequencer);
        
        drain();
        phase.drop_objection(this);
    endtask

endclass