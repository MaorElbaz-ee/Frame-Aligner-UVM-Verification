class frame_driver extends uvm_driver #(frame_item);    
    `uvm_component_utils(frame_driver)
    virtual frame_interface frame_vif;

    function new(string name = "frame_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual frame_interface)::get(this, "", "frame_vif", frame_vif)) begin
            `uvm_fatal("DRV", "Could not get frame_interface from uvm_config_db")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        frame_item tr;

        @(frame_vif.drv_cb);
        //frame_vif.drv_cb.rx_data <= 8'h00;// hadneld with === if on scb
        wait (frame_vif.reset === 1'b0);

        forever begin
            seq_item_port.get_next_item(tr);
            send_to_dut(tr);
            seq_item_port.item_done();
        end
    endtask

    virtual task send_to_dut(frame_item frame_data);
        foreach(frame_data.frame_bytes[i]) begin
            @(frame_vif.drv_cb);
            frame_vif.drv_cb.rx_data <= frame_data.frame_bytes[i];
        end
    endtask
endclass