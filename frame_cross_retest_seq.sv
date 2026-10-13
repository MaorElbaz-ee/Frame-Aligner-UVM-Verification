class frame_cross_retest_seq extends frame_base_seq;

    `uvm_object_utils(frame_cross_retest_seq)

    // 0 : AA 55 BA (pattern 1 LSB -> pattern 2 LSB -> pattern 2 MSB)
    // 1 : 55 AA AF (pattern 2 LSB -> pattern 1 LSB -> pattern 1 MSB)
    bit swap = 1'b0;

    function new(string name = "frame_cross_retest_seq");
        super.new(name);
        num_frames = 1;
    endfunction

    virtual task send_frame();
        frame_item item;
        bit [15:0] hdr;
        bit [7:0]  third_byte;

        // header_val[7:0] goes on the wire FIRST
        if (!swap) begin
            hdr = 16'h55AA; // wire: AA then 55
            third_byte = 8'hBA;// closes BA55
        end
        else begin
            hdr = 16'hAA55;// wire: 55 then AA
            third_byte = 8'hAF;// closes AFAA
        end

        item = frame_item::type_id::create("item");
        start_item(item);
        if (!item.randomize() with {
                header_type == frame_item::ILLEGAL; // neither AFAA nor BA55
                header_val == local::hdr;
                payload.size() == 10;
                payload[0] == local::third_byte;
                // keep the rest of the payload free of header LSBs so that no other acquisition opportunity contaminates the result
                foreach (payload[i]) {
                    (i > 0) -> !(payload[i] inside {8'hAA, 8'h55});
                }
            })
            `uvm_fatal("SEQ", "Randomization failed!")
        finish_item(item);
    endtask

endclass
