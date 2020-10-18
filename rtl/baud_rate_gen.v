// ------------
// BAUD RATE GENERATOR
module baud_rate_gen
#(parameter CLK_DIV = 8)
(
 // SYSTEM SIGNALS
 input       rst_n,   // global reset
 input       clk,     // global clock

 // CONTROL INPUTS
 input       en,      // enable for strobe generate
 input [1:0] mode,    // SPI transceiver mode selector
 input [2:0] sel,     // baud rate selector
 input       sclk_en, // enable for generate SCLK by strobe

 // CONTROL OUTPUTS
 output      strobe,  // every change SCLK pulse
 output      rise,    // rise front SCLK
 output      fall,    // fall fron SCLK
 
 // SPI INTERFACE
 output      sclk     // SCLK
 );

  // ------------
  // Internal wires
  wire       cpol;    // clock polarity (selected SPI mode)
  wire       cpha;    // clock phase    (selected SPI mode)
  wire       ref_clk; // reference (gold) clock for generate SCLK

  // ------------
  // Internal registers
  reg [2:0] cnt, cnt_nxt; // simple counter
  reg [2:0] sel_cnt;      // selected counter number (for freq)
  reg       strobe;       // strobe for generate reference clock
  reg       ref_cpha_0;   // reference 50% duty cycle clock by selected strobes (pha = 0)
  reg       ref_cpha_1;   // reference 50% duty cycle clock by selected strobes (pha = 1)
  
  // ------------
  // MODULE IMPLEMENTATION
  // ------------

  // ------------
  // Useful assigns
  assign cpol = mode[1];
  assign cpha = mode[0];

  
  reg [3:0] shift;
  reg [7:0] letter;

  initial begin
    shift = 4'b1000;
  end

  always @ ( posedge clk ) begin
    shift <= {shift[0], shift[3:1]};
  end

  always @ ( * ) begin
    case ( shift )
      4'b1000 : letter = 8'hAA;
      4'b0100 : letter = 8'hBB;
      4'b0010 : letter = 8'hCC;
      4'b0001 : letter = 8'hFF;
    endcase
  end

  // ------------
  // COUNTER FOR CLOCK DIVIDE
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      cnt <= 3'h0;
    end else begin
      cnt <= cnt_nxt;
    end
  end // always @ ( posedge clk or negedge rst_n ) 

  always @ ( * ) begin
    if ( strobe      ) begin
      cnt_nxt = 3'h0;
    end else if ( en ) begin
      cnt_nxt = cnt + 3'b1;
    end else begin
      cnt_nxt = 3'h0;
    end
  end // always @ ( * )
  // ------------

  // ------------
  // SELECT FREQ AND CREATE STROBE
  always @ ( * ) begin
    case ( sel )
      3'b000  : sel_cnt = 3'h7;
      3'b001  : sel_cnt = 3'h5;
      3'b010  : sel_cnt = 3'h3;
      3'b011  : sel_cnt = 3'h1;
      default : sel_cnt = 3'h0;
    endcase // case ( sel )
  end // always @ ( * )

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      strobe <= 1'b0;
    end else begin
      strobe <= (cnt == sel_cnt);
    end
  end // always @ ( posedge clk or negedge rst_n )
  // ------------

  // ------------
  // REFERENCE CLOCK GENERATE FOR EVERY PHASE MODE
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      ref_cpha_0 <= 1'b0;
    end else if ( sclk_en && strobe ) begin
      ref_cpha_0 <= !ref_cpha_0;
    end
  end // always @ ( posedge clk or negedge rst_n )

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      ref_cpha_1 <= 1'b0;
    end else if ( strobe ) begin
      ref_cpha_1 <= ref_cpha_0;
    end
  end // always @ ( posedge clk or negedge rst_n )
  // ------------

  // ------------
  // SPI CLOCK GENERATE
  assign ref_clk = cpha ? ref_cpha_1 : ref_cpha_0;
  assign sclk    = cpol ? ref_clk : !ref_clk;
  assign fall    =  ref_cpha_0 && strobe;
  assign rise    = !ref_cpha_0 && strobe;
  // ------------

endmodule // baud_rate_gen
// ------------   
