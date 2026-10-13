// at the begining - invalid header with planted header in the payload
// then a frame whose OWN header is valid, carrying the same planted pair in its payload
// the DUT is inside FR_DATA and must ignore the planted pair and stay alinged to the real header rate -
// because the positions are the same.
// then - after we send the good frames - we send frames that containts lsb or msb but without planted hdr.
//score expected - PASS

class frame_payload_hdr_ok_test extends frame_base_test;
    `uvm_component_utils(frame_payload_hdr_ok_test)

    function new(string name = "frame_payload_hdr_ok_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction


    task send_planted(frame_payload_hdr_seq::hdr_kind k, bit plant = 1'b1);
        frame_payload_hdr_seq seq;
        seq = frame_payload_hdr_seq::type_id::create("seq");
        seq.hdr_kind_h = k;
        seq.plant_pair = plant;
        seq.payload_location = 3;
        seq.start(env.agent.sequencer);
    endtask

    task send_good(int unsigned num);
        frame_lock_seq good;
        good = frame_lock_seq::type_id::create("good");
        good.num_frames = num;
        good.start(env.agent.sequencer);
    endtask
        

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        // we aren't aligned yet - we hunt every byte for valid header. both are false lock
        send_planted(frame_payload_hdr_seq::HDR_BAD_LSB); // bad LSB
        send_planted(frame_payload_hdr_seq::HDR_BAD_MSB); // bad MSB

        // send 4 good frames
        send_good(4);

        // we are aligned but in this payload we have valid header
        send_planted(frame_payload_hdr_seq::HDR_VALID); 
        send_good(4);

        // same bad header , will fail at the LSB but without planted hdr in payload
        send_planted(frame_payload_hdr_seq::HDR_BAD_LSB, 1'b0);
        send_good(4);

        // same bad header , will fail at the MSB but without planted hdr in payload
        send_planted(frame_payload_hdr_seq::HDR_BAD_MSB, 1'b0);
        send_good(4);

        drain();
        phase.drop_objection(this);
    endtask
endclass