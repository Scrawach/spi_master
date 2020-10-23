// ------------
// Interface for connecting between
// DUT and testbench's classes
interface bus_if ( input bit clk );

  bit [7:0] data;
    
endinterface : bus_if
// ------------
