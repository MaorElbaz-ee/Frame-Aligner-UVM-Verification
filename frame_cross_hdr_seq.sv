class frame_cross_hdr_seq extends frame_base_seq;

    `uvm_object_utils(frame_cross_hdr_seq)
    
    bit[15:0] cross_header = 16'hBAAA;

    function new(string name = "frame_cross_hdr_seq");
        super.new(name);
        num_frames = 1;
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type == ILLEGAL;
                header_val == local::cross_header;
                payload.size() == 10;
                foreach (payload[i]) !(payload[i] inside {8'hAA, 8'h55});
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask
endclass