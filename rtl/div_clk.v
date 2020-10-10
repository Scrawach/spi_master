// ------------
// CLOCK DIVIDER (SHIFT REGISTER used)
// Parameters: DIVIDER - number by which frequence is diveded
// Example: if clk = 16MHz, but needed 4MHz, then DIVIDER = 4.
module div_clk
  #(parameter DIVIDER = 4)
  (
   input  rst_n,  // global reset
   input  clk,    // global clock
   input  en,     // enable for divide
   output div_clk // output divided clock
   );

  // ------------
  // Internal register's
  reg [DIVIDER - 1: 0] div_reg, div_reg_nxt; // shift-register

  // ------------
  // MODULE IMPLEMENTATION
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 )
      div_reg <= {(DIVIDER){1'b0}};
    else if ( div_clk )
      div_reg <= {(DIVIDER){1'b0}};
    else
      div_reg <= {div_reg[DIVIDER - 2: 0], en};
  end // always @ ( posedge clk or negedge rst_n ) 

  assign div_clk = div_reg[DIVIDER - 1];
  // ------------

endmodule // div_clk
// ------------
