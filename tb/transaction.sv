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
    function new ( bit [7:0] data  );
        this.id   = id + 1;
        this.data = data;
    endfunction : new

    // ------------
    // Compare function
    function bit Compare ( transaction obj );
        return (obj.data == this.data);
    endfunction : Compare

    // Convert data to string
    function string ToString();
        return $sformatf("ID #%0d: Data = 0x%0h;", this.id, this.data);
    endfunction : ToString

endclass : transaction
// ------------