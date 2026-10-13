
// same idea like the lsb lsb lsb test - now we are mixing the headers

class frame_cross_retest_test extends frame_base_test;

    `uvm_component_utils(frame_cross_retest_test)

    bit swap_direction = 1'b0;

    function new(string name = "frame_cross_retest_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        // +swap=1 runs the 55 AA AF direction without a rebuild
        void'($value$plusargs("swap=%b", swap_direction));

        // The mismatch persists for every cycle after the model acquiress
        set_report_max_quit_count(200);
    endfunction

    task send_cross_retest();
        frame_cross_retest_seq seq;
        seq = frame_cross_retest_seq::type_id::create("seq");
        seq.swap = swap_direction;
        seq.start(env.agent.sequencer);
    endtask

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        `uvm_info("XRETEST",
                  $sformatf("stimulus: %s repeated x4",
                            swap_direction ? "55 AA AF" : "AA 55 BA"), UVM_LOW)

        send_cross_retest();
        send_cross_retest();
        send_cross_retest(); // the model acquires here
        send_cross_retest(); // and holds

        drain();
        phase.drop_objection(this);
    endtask

endclass
