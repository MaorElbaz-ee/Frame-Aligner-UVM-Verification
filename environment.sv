class frame_env extends uvm_env;

    `uvm_component_utils(frame_env)

    my_agent agent;
    scoreboard scb;
    frame_coverage cov;

    function new(string name = "frame_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = my_agent::type_id::create("agent", this);
        scb = scoreboard::type_id::create("scb", this);
        cov = frame_coverage::type_id::create("cov", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.mon_port.connect(scb.item_imp);
        agent.monitor.mon_port.connect(cov.cov_imp);
    endfunction
endclass