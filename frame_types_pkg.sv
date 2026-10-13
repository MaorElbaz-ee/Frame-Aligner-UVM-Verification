package frame_types_pkg;

    typedef struct packed {
        logic [7:0] rx_data;
        logic [3:0] fr_byte_position;
        logic       frame_detect;
    } frame_report_s;

endpackage : frame_types_pkg