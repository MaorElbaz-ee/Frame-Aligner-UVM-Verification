import uvm_pkg::*;
`include "uvm_macros.svh"
import frame_types_pkg::*;

class scoreboard extends uvm_scoreboard;

    `uvm_component_utils(scoreboard)
    uvm_analysis_imp #(frame_report_s, scoreboard) item_imp;    

    static const bit [7:0] H1_LSB = 8'hAA;
    static const bit [7:0] H1_MSB = 8'hAF;
    static const bit [7:0] H2_LSB = 8'h55;
    static const bit [7:0] H2_MSB = 8'hBA;


    // ---- reference model state (flag based, no FSM) ----
    int frame_pos = 0;// the current position of the frame , need it when we are sync and then get a bad header
    bit expect_msb = 1'b0;  // this byte must be checked as the MSB
    bit bad_frame = 1'b0; 
    logic [7:0] header_lsb_samp = 8'h00;// hold of the prev byte - the lsb header

    bit expected_frame_detect = 1'b0;
    int expected_fr_byte_position = 0;// output , the prev byte
    int expected_legal_frame_counter = 0;
    int expected_na_frame_counter = 0;

    int cycle = 0;


    int frame_detect_errors = 0;
    int byte_position_errors = 0;
    int lfc3_count = 0;
    int lost_sync_count = 0;

    function new(string name = "scoreboard", uvm_component parent = null);
        super.new(name, parent);
        item_imp = new("item_imp", this);
    endfunction

    virtual function void write(frame_report_s item);
        cycle ++;

        `uvm_info("SCB_TRACE",
            $sformatf("cyc=%0d rx=%02h | DUT: pos=%0d fd=%0b | MODEL: pos=%0d fd=%0b fp=%0d bad=%0b lfc=%0d na=%0d",
                      cycle, item.rx_data,
                      item.fr_byte_position, item.frame_detect,
                      expected_fr_byte_position, expected_frame_detect,
                      frame_pos, bad_frame,
                      expected_legal_frame_counter, expected_na_frame_counter),
            UVM_HIGH)

            
        check_outputs(item);
        update_ref_model(item);
    endfunction
    
//--------------------------------------------------------------------------

    virtual function void check_outputs(frame_report_s item);

        // Check frame_detect
       if (item.frame_detect !== expected_frame_detect) begin
            frame_detect_errors++;
            `uvm_error("SCB_FD_MISMATCH",
                $sformatf("frame_detect mismatch @cycle %0d! Expected: %0b, Got: %0b | frame_pos=%0d bad=%0b lfc=%0d na=%0d",
                          cycle, expected_frame_detect, item.frame_detect,
                          frame_pos, bad_frame, expected_legal_frame_counter, expected_na_frame_counter))
        end

        // check byte position
        if (item.fr_byte_position !== expected_fr_byte_position) begin
            byte_position_errors++;
            `uvm_error("SCB_POS_MISMATCH",
                $sformatf("fr_byte_position mismatch @cycle %0d! Expected: %0d, Got: %0d | frame_pos=%0d rx_data=0x%02h",
                          cycle, expected_fr_byte_position, item.fr_byte_position,
                          frame_pos, item.rx_data))
        end
    endfunction

//--------------------------------------------------------------------------

    virtual function void update_ref_model(frame_report_s item);
        bit        lsb_valid, msb_valid, pos_rst, retest;
        bit        na_inc, na_rst, lfc_rst, lfc_inc, keep_lsb, msb_fail;
        int        next_frame_pos;// we checked now lsb and its valid - next clk need to check msb
        bit        next_expect_msb, next_bad_frame;
        
        lsb_valid = (item.rx_data === H1_LSB) || (item.rx_data === H2_LSB);
        msb_valid = ((header_lsb_samp === H1_LSB) && (item.rx_data === H1_MSB)) ||
                    ((header_lsb_samp === H2_LSB) && (item.rx_data === H2_MSB));


        na_inc = 0; na_rst = 0; lfc_rst = 0; lfc_inc = 0; keep_lsb = 0; retest = 0; msb_fail = 0;
        next_frame_pos  = frame_pos;
        next_expect_msb = 1'b0;
        next_bad_frame  = bad_frame;

        // ------------------------------ frame detect now is low-------------------------------

        if(!expected_frame_detect) begin // if we are nog aligned - looking for lsb every clk unless we find already header
            next_bad_frame = 1'b0;

            if(expect_msb) begin
                if(msb_valid) begin
                    lfc_inc = 1'b1;
                    next_frame_pos  = 2;
                end
               else begin // msb valid = 0
                    lfc_rst = 1'b1;
                    if(lsb_valid) begin
                        keep_lsb        = 1'b1;
                        retest          = 1'b1;  // this byte becomes the new Head_0
                        next_expect_msb = 1'b1;
                        next_frame_pos  = 1;
                    end
                    else begin
                        msb_fail = 1'b1;
                        next_frame_pos = 0;
                    end

                end
            end

            else if(frame_pos == 0) begin // if we are on pos 0 => header's lsb
                if(lsb_valid) begin
                    keep_lsb = 1'b1;
                    next_expect_msb = 1'b1;
                    next_frame_pos = 1;
                end    
                else begin //lsb valid = 0
                    next_frame_pos = 0;// still looking for valid lsb header every clk
                    lfc_rst = 1'b1;// legal frame count restart - maybe found header
                end
            end

            else begin// we are in lfc > 0 and ingoring payload
                next_frame_pos = (frame_pos == 11) ? 0 : frame_pos + 1;
            end
        end
        // ------------------------------ frame detect now is high-------------------------------
        
        else begin// frame detect = 1

            if(frame_pos == 0) begin
                na_inc = 1'b1;
                if(lsb_valid) begin
                    keep_lsb = 1'b1;
                    next_expect_msb = 1'b1;
                    next_frame_pos  = 1;
                end
                else begin
                    lfc_rst = 1'b1;
                    next_bad_frame = 1'b1;
                    next_frame_pos = 1;
                end
            end

            else if(expect_msb) begin
                if(msb_valid) begin
                    lfc_inc = 1'b1;
                    na_rst = 1'b1;
                    next_frame_pos = 2;
                    next_bad_frame = 1'b0;
                end
                else begin//msb_valid = 0
                    lfc_rst = 1'b1;
                    na_inc = 1'b1;
                    next_frame_pos = 2;
                    next_bad_frame = 1'b1;
                end
            end

            else begin // frame pos and fr byte pos are bigger than 1
                if(bad_frame) begin
                    na_inc = 1'b1;
                end
                if(frame_pos == 11) begin
                    next_frame_pos = 0;
                    next_bad_frame = 1'b0;
                end
                else begin
                    next_frame_pos = frame_pos + 1;
                end
            end
        end

        if(expected_legal_frame_counter == 3) begin
            // Count the TRANSITION, not the cycles. The condition stays true for
            // as long as the model is locked, so an unguarded ++ here counts
            // clocks and reports hundreds of "lock events" for a single lock.
            if(!expected_frame_detect) lfc3_count++;
            expected_frame_detect = 1'b1;
        end

        else if(expected_na_frame_counter == 47) begin
            if(expected_frame_detect) lost_sync_count++;
           expected_frame_detect = 1'b0;
        end
        
        // fr byte position logic
        pos_rst = ((frame_pos == 0) || bad_frame || retest || msb_fail);
        expected_fr_byte_position = pos_rst ? 0 : (expected_fr_byte_position + 1) % 12;
        
        // expected legal frame counter logic
        if(lfc_rst) begin
            expected_legal_frame_counter = 0;
        end
        else if((lfc_inc) && expected_legal_frame_counter < 3 ) begin
            expected_legal_frame_counter++;
        end
        
        if(na_rst) begin
            expected_na_frame_counter = 0;
        end
        else if(na_inc) begin
            expected_na_frame_counter = (expected_na_frame_counter == 47) ? 0 : expected_na_frame_counter + 1;
        end

        if(keep_lsb) begin
            header_lsb_samp = item.rx_data;
        end

        frame_pos = next_frame_pos;
        bad_frame = next_bad_frame;
        expect_msb = next_expect_msb;
    endfunction

    //--------------------------------------------------------------------------

    virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);

        `uvm_info("SCB_SUMMARY",
            $sformatf({"\n  cycles checked       : %0d",
                       "\n  frame_detect errors  : %0d",
                       "\n  byte position errors : %0d",
                       "\n  lock events          : %0d",
                       "\n  unlock events        : %0d"},
                      cycle, frame_detect_errors, byte_position_errors, lfc3_count, lost_sync_count), UVM_LOW)

        if(lfc3_count == 0)
            `uvm_warning("SCB_NO_LOCK",
                "frame_detect never asserted - the stimulus never achieved alignment, so nothing downstream of the lock was verified.")

        if(lost_sync_count == 0)
            `uvm_warning("SCB_NO_UNLOCK",
                "frame_detect never de-asserted - no test drove 48 consecutive non-aligned bytes, so the entire unlock path is unverified.")
    endfunction


endclass