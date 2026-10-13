class frame_random_seq extends frame_base_seq;

    `uvm_object_utils(frame_random_seq)

    function new (string name = "frame_random_seq");
        super.new(name);
        num_frames = 50;
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize())
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass
