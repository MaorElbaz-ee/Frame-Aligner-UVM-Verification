
class frame_illegal_seq extends frame_base_seq;

    `uvm_object_utils(frame_illegal_seq)

    function new(string name = "frame_illegal_seq");
        super.new(name);
        num_frames = 4;// 3 to lock
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type    == ILLEGAL;
                payload.size() == 10;
                 !(header_val[7:0]  inside {8'hAA, 8'h55});
                foreach (payload[i]) !(payload[i] inside {8'hAA, 8'h55});// blocking both header's lsb
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass