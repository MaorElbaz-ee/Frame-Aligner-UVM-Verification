class frame_lsb_in_msb_seq extends frame_base_seq;

    `uvm_object_utils(frame_lsb_in_msb_seq)

    bit extra_lsb = 1'b0;

    function new(string name = "frame_lsb_in_msb_seq");
        super.new(name);
        num_frames = 1;
    endfunction

    virtual task send_frame();
        frame_item item;
        item = frame_item::type_id::create("item");
        start_item(item);

        if (!item.randomize() with {
            header_type == frame_item:: ILLEGAL;
            header_val ==16'hAAAA;
            payload.size() == 10;
            
            // case for LSB LSB LSB MSB
            if(local::extra_lsb) {
                payload[0] == 8'hAA;
                payload[1] == 8'hAF;
                foreach (payload[i]) {
                    (i > 1) -> !(payload[i] inside {8'hAA, 8'h55});
                }
            }
            // case for  LSB LSB MSB
            else {
                payload[0] == 8'hAF;
                    foreach (payload[i]) {
                        (i > 0) -> !(payload[i] inside {8'hAA, 8'h55});
                    }
                }
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask


endclass