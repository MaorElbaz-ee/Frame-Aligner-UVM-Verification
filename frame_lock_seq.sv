//--------- the goal of this seq - to check if it locks and hold it ------

class frame_lock_seq extends frame_base_seq;

    `uvm_object_utils(frame_lock_seq)

    function new(string name = "frame_lock_seq");
        super.new(name);
        num_frames = 6;// 3 to lock, 3 more to prove it holds
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type == HEAD_1;//header_type == frame_item::HEAD_1;
                payload.size() == 10;
                foreach (payload[i]) !(payload[i] inside {8'hAA, 8'h55});
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass