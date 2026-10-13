
class frame_item extends uvm_sequence_item;

    typedef enum bit [1:0] {HEAD_1, HEAD_2, ILLEGAL} header_type_t;

    rand byte payload[];// dynamic array - dynamic amount of bytes for each sequence.
    rand header_type_t header_type;// to randomize between the 2 headers
    rand bit [15:0] header_val;// the binary value of the header

    byte frame_bytes[$]; // this is waht the driver actually sends

    `uvm_object_utils_begin(frame_item)
        `uvm_field_enum(header_type_t, header_type, UVM_DEFAULT)
        `uvm_field_int(header_val, UVM_HEX)
        `uvm_field_array_int(payload, UVM_HEX)
        `uvm_field_queue_int(frame_bytes, UVM_HEX)
    `uvm_object_utils_end

    constraint payload_size_c {// acording to the spec
        payload.size() inside {[10:40]};
    }

    constraint header_dist {
        header_type dist {HEAD_1 := 40, HEAD_2 := 40, ILLEGAL := 20};
        solve header_type before header_val;
    }

    function new(string name = "frame_item");
        super.new(name);
    endfunction

    constraint header_val_c {
        (header_type == HEAD_1)  -> (header_val == 16'hAFAA);
        (header_type == HEAD_2)  -> (header_val == 16'hBA55);
        (header_type == ILLEGAL) -> !(header_val inside {16'hAFAA, 16'hBA55});
    }
    
    function void post_randomize();
        frame_bytes.delete();
        frame_bytes.push_back(header_val[7:0]);
        frame_bytes.push_back(header_val[15:8]);
        foreach (payload[i])
            frame_bytes.push_back(payload[i]);
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("header_type=%s, header=0x%04h, payload_len=%0d, payload=[",
                      header_type.name(), header_val, payload.size());
        foreach (payload[i])
            s = {s, $sformatf("0x%02h ", payload[i])};
        return {s, "]"};
    endfunction
endclass