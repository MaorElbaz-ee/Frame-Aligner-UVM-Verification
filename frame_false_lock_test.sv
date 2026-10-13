// sending good frames until frame detect = 1
// then unlock it with frame that contains bad header and planted header in the payload
//should ignore the planted header because we are still aligned ( frame detect = 1)
//LSB TEST
class frame_false_lock_test extends frame_base_test;

    `uvm_component_utils(frame_false_lock_test)

    function new(string name = "frame_false_lock_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        set_report_max_quit_count(100000);
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_payload_hdr_seq bad;
        frame_lock_seq good;

        phase.raise_objection(this);

        good = frame_lock_seq::type_id::create("good");
        good.num_frames = 4;
        good.start(env.agent.sequencer);
 
        bad = frame_payload_hdr_seq::type_id::create("bad");
        bad.hdr_kind_h = frame_payload_hdr_seq::HDR_BAD_LSB;
        bad.cyclic_location = 1'b1;
        bad.plant_pair = 1'b1;

        repeat (10) begin
            bad.start(env.agent.sequencer);

            good = frame_lock_seq::type_id::create("good2");
            good.num_frames = 6;
            good.start(env.agent.sequencer);
        end

        drain();
        phase.drop_objection(this);
    endtask
endclass
