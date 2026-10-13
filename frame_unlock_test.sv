class frame_unlock_test extends frame_base_test;
    `uvm_component_utils(frame_unlock_test)

    function new(string name = "frame_unlock_test" , uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_lock_seq good_seq;
        frame_illegal_seq bad_seq;

        phase.raise_objection(this);
        // 4 good frames - to lock it.
        good_seq = frame_lock_seq::type_id::create("good_seq");
        good_seq.num_frames = 4;// instead of 6
        good_seq.start(env.agent.sequencer);

        // 4 bad frames - to lose the lock
        bad_seq = frame_illegal_seq::type_id::create("bad_seq");
        bad_seq.start(env.agent.sequencer);
       
        // another 4 good frames - to relock it       
        good_seq = frame_lock_seq::type_id::create("good_seq2");
        good_seq.num_frames = 4;// instead of 6
        good_seq.start(env.agent.sequencer);

        drain();
        phase.drop_objection(this);
    endtask
endclass