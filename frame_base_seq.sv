class frame_base_seq extends uvm_sequence #(frame_item);

    `uvm_object_utils(frame_base_seq)

    int unsigned num_frames  = 6;
    frame_item::header_type_t hdr_type = frame_item::HEAD_1;
    int unsigned payload_len = 10;

    function new(string name = "frame_base_seq");
        super.new(name);
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type    == local::hdr_type;
                payload.size() == local::payload_len;
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

    virtual task body();
        repeat (num_frames) send_frame();
    endtask

endclass