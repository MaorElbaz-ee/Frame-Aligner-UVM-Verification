class frame_lsb_lsb_msb_test extends frame_base_test;

    `uvm_component_utils(frame_lsb_lsb_msb_test)
    
    function new(string name = "frame_lsb_lsb_msb_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        set_report_max_quit_count(1000);
    endfunction

    task send_good(int unsigned num);
        frame_lock_seq good;
        good = frame_lock_seq::type_id::create("good");
        good.num_frames = num;
        good.start(env.agent.sequencer);
    endtask

    task send_planted(bit extra = 1'b0);
        frame_lsb_in_msb_seq seq;
        seq = frame_lsb_in_msb_seq::type_id::create("seq");
        seq.extra_lsb = extra;
        seq.start(env.agent.sequencer);
    endtask

    // sending a bad frame to unalign
    task send_bad();
        frame_illegal_seq bad;
        bad = frame_illegal_seq::type_id::create("bad");
        bad.num_frames = 4;
        bad.start(env.agent.sequencer);
    endtask

    // one frame of  AA AA AF + 9 clean payload bytes

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        //first case - when we align
        send_good(3); // frame detect = 1
        send_planted();
        send_planted();

        send_bad();// frame detect = 0

        // same case - now frame detect = 0 so we are not align
        send_planted();
        send_planted();
        send_planted();

        send_bad();// frame detect = 0 
        send_good(1); // now we starting the align process - should looking after 12 clks

        send_planted();
        send_planted();

        send_bad();
        
        drain();

        phase.drop_objection(this);

    endtask

endclass