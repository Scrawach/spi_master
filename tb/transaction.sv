// ------------
// TRANSACTION PACKET CLASS
class transaction;

  // ------------
  // Packet ID number
  static int id;

  // ------------
  // Randomization values
  rand bit [7:0] data;

  // ------------
  // Initialization
  function new();
    this.id   = id + 1;
  endfunction : new

  // ------------
  // Base class copy function
  virtual function transaction Copy ( transaction to = null );
    if ( to == null ) Copy = new;
    else              Copy = to;
    this.CopyData(Copy);    
  endfunction : Copy

  // Copy data from class to another class
  virtual function void CopyData ( transaction to );
    to.data = this.data;
  endfunction : CopyData
  
  // Compare function
  virtual function bit Compare ( transaction obj );
    return (obj.data == this.data);
  endfunction : Compare

  // Convert data to string
  virtual function string ToString();
    return $sformatf("ID #%0d: Data = 0x%0h;", this.id, this.data);
  endfunction : ToString

  // Display function
  virtual function void Display(string message = "\t");
    $display("============");
    $display("%s", message);
    $display("Transaction ID: %0d", this.id);
    $display("Data: 0x%h", this.data);
    $display("============");
  endfunction : Display
  // ------------ 

endclass : transaction
// ------------

// ------------
// TRANSACTION ERROR PACKET CLASS
class bad_transaction extends transaction;

  // Random bit ERROR
  rand bit error;

  // ------------
  // Extend deep copy function
  virtual function transaction Copy ( transaction to = null );
    bad_transaction bad;
    if ( to == null ) bad = new;
    else              $cast(bad, to);
    this.CopyData(bad);
    return bad;
  endfunction : Copy

  // Extend copy data function
  virtual function void CopyData ( transaction to );
    bad_transaction bad;
    // Copy parent base class data:
    super.CopyData(to);
    $cast(bad, to);
    // Copy extended class data:
    bad.error = this.error;
  endfunction : CopyData

  // Extend Display function
  virtual function void Display(string message = "\t");
    $display("============");
    $display("%s", message);
    $display("Transaction ID: %0d", this.id);
    $display("Data: 0x%h\tError: %0b", this.data, this.error);
    $display("============");
  endfunction : Display
  // ------------ 
  
endclass : bad_transaction
// ------------
