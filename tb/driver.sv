// ------------
// Simple driver class
class driver #(type VIF_TYPE = virtual bus_if);
  
  // Virtual interface, that connecting to DUT
  VIF_TYPE vif;
    
  // Mailbox, received data from generator
  mailbox gen2drv;

  // ------------
  // Initialization
  function new ( mailbox gen2drv );
    this.gen2drv = gen2drv;
  endfunction : new

  // Build function
  virtual function void build();
  endfunction : build

  // Main task with creating new thread
  virtual task run();
    transaction trans;
    
    fork
      forever begin
        gen2drv.get(trans);
        transmit(trans);
      end
    join_none
  endtask : run

  // Transmit transaction into DUT
  virtual task transmit ( transaction tr );
  endtask : transmit
  // ------------
  
endclass : driver
// ------------
