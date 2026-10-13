
//a seq for a few senario test - to check how the dut respond to a fake hdr in payload
class frame_payload_hdr_seq extends frame_base_seq;

    `uvm_object_utils(frame_payload_hdr_seq)

    typedef enum {HDR_VALID, HDR_BAD_LSB, HDR_BAD_MSB} hdr_kind;

    hdr_kind hdr_kind_h = HDR_BAD_LSB;
    int unsigned payload_location = 3;// index in payload
    bit plant_pair = 1'b1;
    //cyclic_location=1 -> payload_location is picked cyclically from 0 to 9 (each value once per cycle).
    // location 9 = last payload byte, only AA is planted there (no room for AF) -> AA right before the next header
    bit cyclic_location = 1'b0;
    int unsigned loc_q[$];

    function new(string name = "frame_payload_hdr_seq");
        super.new(name);
        num_frames = 1;

    endfunction

    virtual task send_frame();
        frame_item item;
        bit [15:0] hold_header_value;
        frame_item::header_type_t hold_header_kind;

        // cyclic pick: refill and shuffle when the cycle is done.
        if (cyclic_location) begin
            if (loc_q.size() == 0) begin
                for (int unsigned i = 0; i <= 9; i++) loc_q.push_back(i);
                loc_q.shuffle();
            end
            payload_location = loc_q.pop_front();
            `uvm_info("SEQ", $sformatf("planted location = %0d (%s)", payload_location, (payload_location == 9) ? "single AA at payload end" : "AA AF pair"), UVM_LOW)
        end

        // location 9 allowed only as single AA
        if (payload_location > 9) `uvm_fatal("SEQ", $sformatf("payload_location=%0d, must be <= 9", payload_location))

        case(hdr_kind_h)
            HDR_VALID: begin
                hold_header_value = 16'hAFAA;
                hold_header_kind = frame_item::HEAD_1;
            end

            HDR_BAD_LSB: begin
                hold_header_value = 16'h1234;
                hold_header_kind = frame_item::ILLEGAL;
            end

           HDR_BAD_MSB: begin
                hold_header_value = 16'h12AA;
                hold_header_kind = frame_item::ILLEGAL;
            end
        endcase
            

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type == local::hold_header_kind;
                header_val == local::hold_header_value;
                payload.size() == 10;
                // [edit] location 9: single AA only, the next frame's header follows right after it
                if (local::plant_pair && local::payload_location == 9) {
                    payload[9] == 8'hAA;
                    foreach (payload[i]) (i != 9) -> !(payload[i] inside {8'hAA, 8'h55});
                }
                else if (local::plant_pair) {// to prove that the plant caused the fail
                    payload[local::payload_location]     == 8'hAA;
                    payload[local::payload_location + 1] == 8'hAF;
                    foreach (payload[i]) {
                        (i != local::payload_location && i != local::payload_location + 1)
                            -> !(payload[i] inside {8'hAA, 8'h55});
                    }
                }
                else {
                    foreach (payload[i]) !(payload[i] inside {8'hAA, 8'h55});
                }
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask
endclass