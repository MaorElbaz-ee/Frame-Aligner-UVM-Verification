class frame_clean_seq extends frame_base_seq;

    `uvm_object_utils(frame_clean_seq)

    function new(string name = "frame_clean_seq");
        super.new(name);
        num_frames  = 3;// the minimum that can acquire alignment
        payload_len = 10;// the only size that yields a 12-byte DUT frame
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type    == local::hdr_type;
                payload.size() == local::payload_len;
                foreach (payload[i]) !(payload[i] inside {8'hAA, 8'h55});
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass
