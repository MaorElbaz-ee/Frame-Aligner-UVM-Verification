class frame_coverage extends uvm_component;

    `uvm_component_utils(frame_coverage)

    // Subscribes to the same analysis port the scoreboard uses.
    uvm_analysis_imp #(frame_report_s, frame_coverage) cov_imp;

    int unsigned samples; // clock cycles
	int unsigned lock_events;  // 0 -> 1 transitions
    int unsigned unlock_events; // 1 -> 0 transitions
	
	static const bit [7:0] H1_LSB = 8'hAA;
    static const bit [7:0] H1_MSB = 8'hAF;
    static const bit [7:0] H2_LSB = 8'h55;
    static const bit [7:0] H2_MSB = 8'hBA;
	
	typedef enum {RX_H1_LSB, RX_H1_MSB, RX_H2_LSB, RX_H2_MSB, RX_OTHER} rx_class_t;
	
	typedef enum {
        PAT_NONE, // nothing interesting ends on this byte
        PAT_HDR_1, // AA AF - a valid header 1 
        PAT_HDR_2, // 55 BA - a valid header 2
        PAT_HDR_CROSS, // AA BA / 55 AF - LSB of one, MSB of the other
        PAT_LSB_LSB, // AA AA / 55 55 - a second LSB after the first
        PAT_LSB_LSB_MSB, // AA AA AF - second LSB then a matching MSB
        PAT_CROSS_RETEST // AA 55 BA - the other LSB, then ITS MSB
    } pattern_t;
	
	rx_class_t rx_class; // class of the byte on the bus this cycle
	pattern_t  pattern; // what we can expect from this pattern
	
	bit cur_fd; // frame detect on this cycle
	bit prev_fd; // previous frame detect
	bit have_prev_fd; // need to give attention to frame detect ?
	bit [3:0] cur_pos; // fr_byte_pos on this cycle
	bit [3:0] prev_pos; // fr_byte_position on the previous cycle
	bit [7:0] byte_n1; // the byte from one cycle ago
    bit [7:0] byte_n2; // the byte from two cycles ago
    int unsigned history_depth; // bytes seen so far - guards the first cycles
	
	
	covergroup cg_bus;
		option.per_instance = 1; // count and report on each instantce seperate
		option.name = "cg_bus";

		cp_rx_class : coverpoint rx_class; // coverpoint on enum create by itself bins to each value.
	
		cp_frame_detect : coverpoint cur_fd {
			bins unlocked = {1'b0}; // frame detect = 0
			bins locked = {1'b1}; // frame detect = 1
		}
		
		cp_byte_pos : coverpoint cur_pos {
			bins pos[12] = {[0:11]}; // there are 12 bytes pos , the rest from the 4 bit (12-15) are invalid , so we dont count them as part of the 100%
			illegal_bins invalid = {[12:15]};
		}
		
		cp_pos_wrap : coverpoint {prev_pos, cur_pos} {
			bins wrap_11_to_0 = {8'hB0}; //11 -> 0
			bins step_0_to_1 = {8'h01}; //0 -> 1
			bins hold_0_to_0 = {8'h00}; //0 -> 0
		}
		
		// checking if we get a header values when frame detect = 1
		x_hdr_byte_while_locked : cross cp_rx_class, cp_frame_detect {
            ignore_bins not_a_header = binsof(cp_rx_class) intersect {RX_OTHER};
        }
	
		// checking if we get header values at what position in the frame
		x_hdr_byte_vs_pos : cross cp_rx_class, cp_byte_pos {
            ignore_bins not_a_header = binsof(cp_rx_class) intersect {RX_OTHER};
        }
	endgroup
	
	
	function rx_class_t classify_byte(bit [7:0] b);
        case (b)
            H1_LSB : return RX_H1_LSB;
            H1_MSB : return RX_H1_MSB;
            H2_LSB : return RX_H2_LSB;
            H2_MSB : return RX_H2_MSB;
            default: return RX_OTHER;
        endcase
    endfunction
	
	
	function pattern_t classify_pattern(bit [7:0] b);
		if(history_depth >= 2) begin
			// --- LSB -> LSB -> MSB ---
			if((byte_n2 == H1_LSB) && (byte_n1 == H1_LSB) && (b == H1_MSB)) return PAT_LSB_LSB_MSB;
			if((byte_n2 == H2_LSB) && (byte_n1 == H2_LSB) && (b == H2_MSB)) return PAT_LSB_LSB_MSB;
			
			if(( byte_n2 == H1_LSB) && (byte_n1 == H2_LSB) && (b == H2_MSB)) return PAT_CROSS_RETEST;
			if(( byte_n2 == H2_LSB) && (byte_n1 == H1_LSB) && (b == H1_MSB)) return PAT_CROSS_RETEST;			
		end
		
		if(history_depth >= 1) begin
			if ((byte_n1 == H1_LSB) && (b == H1_MSB)) return PAT_HDR_1;
            if ((byte_n1 == H2_LSB) && (b == H2_MSB)) return PAT_HDR_2;
			
			//mismatch - not header
			if ((byte_n1 == H1_LSB) && (b == H2_MSB)) return PAT_HDR_CROSS;
            if ((byte_n1 == H2_LSB) && (b == H1_MSB)) return PAT_HDR_CROSS;

            if ((byte_n1 == H1_LSB) && (b == H1_LSB)) return PAT_LSB_LSB;
            if ((byte_n1 == H2_LSB) && (b == H2_LSB)) return PAT_LSB_LSB;
		end
		return PAT_NONE;
	endfunction
	
	covergroup cg_pattern;
		option.per_instance = 1;
		option.name = "cg_pattern";
		
		cp_pattern : coverpoint pattern {
			ignore_bins uninteresting = {PAT_NONE};
		}	
		
		// we duplicate it from anither covergruop
		cp_pat_lock : coverpoint cur_fd {
            bins unlocked = {1'b0};
            bins locked   = {1'b1};
        }
		
		x_pattern_vs_lock : cross cp_pattern, cp_pat_lock;
	endgroup
	
	
	covergroup cg_events;
		option.per_instance = 1;
		option.name = "cg_events";
		
		cp_fd_edge : coverpoint {prev_fd, cur_fd}{
			bins acquire = {2'b01}; // frame detect moved from 0 to 1
			bins lose = {2'b10}; // frame detect moved from 1 to 0
			ignore_bins stable  = {2'b00, 2'b11};
		}
		
		// frame_detect rises with fr_byte_position = 2 and falls with fr_byte_position = 0
		cp_edge_pos : coverpoint cur_pos {
			bins pos_0 = {0};
			bins pos_2 = {2};
			ignore_bins other = {1, [3:11]};
		}

		x_edge_vs_pos : cross cp_fd_edge, cp_edge_pos {
			ignore_bins acq_at_0  = binsof(cp_fd_edge.acquire) && binsof(cp_edge_pos.pos_0);
			ignore_bins lose_at_2 = binsof(cp_fd_edge.lose) && binsof(cp_edge_pos.pos_2);
		}
	endgroup	
	
	function new(string name = "frame_coverage", uvm_component parent = null);
        super.new(name, parent);
        cov_imp = new("cov_imp", this);
        cg_bus  = new();
		cg_pattern = new();
		cg_events  = new();
    endfunction
	
	
	virtual function void write(frame_report_s item);
	
		samples++;
		
		// loading the sampled values
		rx_class = classify_byte(item.rx_data);
		pattern  = classify_pattern(item.rx_data);
		cur_fd = item.frame_detect;
		cur_pos = item.fr_byte_position;
		
		// sample
		cg_bus.sample();
		cg_pattern.sample();
		
		if (have_prev_fd && (prev_fd != cur_fd)) begin
            if (cur_fd) lock_events++;
            else unlock_events++;
            cg_events.sample();
        end
		
		// shift the history
		prev_pos     = cur_pos;
        prev_fd      = cur_fd;
        have_prev_fd = 1'b1;
        byte_n2  = byte_n1;
        byte_n1  = item.rx_data;
        if (history_depth < 3) history_depth++;
	endfunction
	
	
	virtual function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("COV_SUMMARY",
            $sformatf({"\n  cycles observed  : %0d",
                       "\n  cg_bus           : %0.2f %%",
                       "\n      cp_rx_class     : %0.2f %%",
                       "\n      cp_frame_detect : %0.2f %%",
                       "\n      cp_byte_pos     : %0.2f %%",
                       "\n      cp_pos_wrap     : %0.2f %%",
                       "\n      x_hdr_while_locked : %0.2f %%",
                       "\n      x_hdr_vs_pos       : %0.2f %%",
                       "\n  cg_pattern       : %0.2f %%",
                       "\n      cp_pattern      : %0.2f %%",
                       "\n      cp_pat_lock     : %0.2f %%",
                       "\n      x_pattern_vs_lock : %0.2f %%",
                       "\n  cg_events        : %0.2f %%",
                       "\n      cp_fd_edge      : %0.2f %%",
                       "\n      cp_edge_pos     : %0.2f %%",
                       "\n      x_edge_vs_pos   : %0.2f %%",
                       "\n  ----",
                       "\n  lock events   (0->1) : %0d",
                       "\n  unlock events (1->0) : %0d"},
                      samples,
                      cg_bus.get_inst_coverage(),
                      cg_bus.cp_rx_class.get_inst_coverage(),
                      cg_bus.cp_frame_detect.get_inst_coverage(),
                      cg_bus.cp_byte_pos.get_inst_coverage(),
                      cg_bus.cp_pos_wrap.get_inst_coverage(),
                      cg_bus.x_hdr_byte_while_locked.get_inst_coverage(),
                      cg_bus.x_hdr_byte_vs_pos.get_inst_coverage(),
                      cg_pattern.get_inst_coverage(),
                      cg_pattern.cp_pattern.get_inst_coverage(),
                      cg_pattern.cp_pat_lock.get_inst_coverage(),
                      cg_pattern.x_pattern_vs_lock.get_inst_coverage(),
                      cg_events.get_inst_coverage(),
                      cg_events.cp_fd_edge.get_inst_coverage(),
                      cg_events.cp_edge_pos.get_inst_coverage(),
                      cg_events.x_edge_vs_pos.get_inst_coverage(),
                      lock_events, unlock_events), UVM_LOW)

		// empty bin is a number on the log
		if (samples == 0)
			`uvm_warning("COV_NO_SAMPLES",
				"the collector was never called - mon_port is not connected to cov_imp, or no clock was driven.")

		if (lock_events == 0)
			`uvm_warning("COV_NO_ACQUIRE",
				"no 0->1 frame_detect transition was observed - the stimulus never achieved alignment, so nothing downstream of the lock was exercised.")

		if (unlock_events == 0)
			`uvm_warning("COV_NO_LOSE",
				"no 1->0 frame_detect transition was observed - no stimulus drove 48 consecutive non-aligned bytes, so the loss-of-alignment path is unverified.")
    endfunction
	
endclass