// the goal of this test is to check combine headers

class frame_mixed_hdr_test extends frame_base_test;
    `uvm_component_utils(frame_mixed_hdr_test)
    
    function new(string name = "frame_mixed_hdr_test", uvm_component parent = null);
        super.new(name,parent);
    endfunction

    task send_one(frame_item::header_type_t t);// header 1 or header 2
        frame_base_seq seq;
        seq = frame_base_seq::type_id::create("seq");
        seq.hdr_type = t;
        seq.num_frames = 1;
        seq.payload_len = 10;
        seq.start(env.agent.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        frame_lock_seq seq;

        phase.raise_objection(this);
        
        send_one(frame_item::HEAD_1);// 0xAFAA
        send_one(frame_item::HEAD_2);// 0xBA55
        send_one(frame_item::HEAD_1);// frame detect should be 1
        send_one(frame_item::HEAD_2);// hold

        drain();
        phase.drop_objection(this);
    endtask

endclass