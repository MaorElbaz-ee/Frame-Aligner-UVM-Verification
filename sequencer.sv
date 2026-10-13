class frame_sequencer extends uvm_sequencer #(frame_item);

    `uvm_component_utils(frame_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass
