// ------------
// Simple generator class (factory pattern)
class generator #(type T = transaction);

  // Mailbox, transmit data to driver
  mailbox gen2drv;

  // Reference (GOLD) transaction item for generate values
  T blueprint;

  // Number of transactions
  int     num;

  // ------------
  // Initialization
  function new ( mailbox gen2drv, int num = 1 );
    this.gen2drv = gen2drv;
    this.num     = num;
    this.build();
  endfunction : new

  // Build function
  virtual function void build();
    blueprint = new();
  endfunction : build

  // Main task with creating new thread
  task run();
    fork
      begin
        T trans;

        for ( int i = 0; i < num; i++ ) begin
          assert ( blueprint.randomize() ) else $error("%0t: [GENERATOR] randomize failed!", $time);
          trans = blueprint.copy();
          gen2drv.put(trans);
        end
      end
    join_none
  endtask : run
  
endclass : generator
// ------------   
