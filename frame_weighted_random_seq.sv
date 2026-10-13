class frame_weighted_random_seq extends frame_random_seq;

    `uvm_object_utils(frame_weighted_random_seq)

    // payload length distribution 
    int unsigned size_10_weight  = 70;//12-byte frames
    int unsigned size_hi_weight  = 30;// [11:40]

    // payload byte distribution
    int unsigned hdr_byte_weight = 5;// each of AA, 55, AF, BA
    int unsigned other_weight    = 80; // any other value 0-255

    function new (string name = "frame_weighted_random_seq");
        super.new(name);
        num_frames = 50;
    endfunction

    virtual task send_frame();
        frame_item item;

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                payload.size() dist { 10 := local::size_10_weight,
                                      [11:40] :/ local::size_hi_weight };

                foreach (payload[i]) {
                    payload[i] dist { 8'hAA := local::hdr_byte_weight,
                                      8'h55 := local::hdr_byte_weight,
                                      8'hAF := local::hdr_byte_weight,
                                      8'hBA := local::hdr_byte_weight,
                                      [8'h00:8'hFF] :/ local::other_weight };
                }
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass
