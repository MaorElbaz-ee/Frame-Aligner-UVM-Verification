interface frame_interface (
    input logic clk,
    input logic reset
);

    logic [7:0] rx_data;

    logic [3:0] fr_byte_position;
    logic       frame_detect;
    
    clocking mon_cb @(posedge clk);
        default input #1step output #1ns;
        input rx_data;
        input fr_byte_position;
        input frame_detect;
    endclocking

    clocking drv_cb @(posedge clk);
        default input #1step output #1ns;
        output rx_data;
    endclocking

    modport drv (clocking drv_cb, input clk, reset);
    modport mon (clocking mon_cb, input clk, reset);


    property p_max_byte_pos;
        @(posedge clk) disable iff (reset)
        (fr_byte_position <= 4'd11);
    endproperty

    a_max_byte_pos: assert property (p_max_byte_pos)
    else $error("[SVA ERROR] fr_byte_position exceeded 11! Current Value = %0d", $sampled(fr_byte_position));


    // after reset frame_detect = 0
    property p_reset_state;
        @(posedge clk)
        reset |-> (frame_detect == 1'b0);
    endproperty
    
    a_reset_state: assert property (p_reset_state)
    else $error("[SVA ERROR] frame_detect active during reset!");


endinterface