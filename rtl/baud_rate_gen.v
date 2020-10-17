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
  wire       ref_clk;
  // ------------
  // Internal registers
  reg [2:0] cnt, cnt_nxt;
  reg [2:0] sel_cnt;
  reg       strobe;
  reg       ref_cpha_0; // reference 50% duty cycle clock by selected strobes (pha = 0)
  reg       ref_cpha_1; // reference 50% duty cycle clock by selected strobes (pha = 1)

  
  // ------------
  // MODULE IMPLEMENTATION

  // ------------
  // Useful assigns
  assign cpol = mode[1];
  assign cpha = mode[0];

  // ------------
  // COUNTER FOR CLOCK DIVIDE
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      cnt <= 3'h0;
    end else begin
      cnt <= cnt_nxt;
    end
  end

  always @ ( * ) begin
    if ( strobe      ) begin
      cnt_nxt = 3'h0;
    end else if ( en ) begin
      cnt_nxt = cnt + 3'b1;
    end else begin
      cnt_nxt = 3'h0;
    end
  end
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
  end 

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      ref_cpha_1 <= 1'b0;
    end else if ( strobe ) begin
      ref_cpha_1 <= ref_cpha_0;
    end
  end
  // ------------

  // ------------
  // SPI CLOCK GENERATE
  assign ref_clk = cpha ? ref_cpha_1 : ref_cpha_0;
  assign sclk = cpol ? ref_clk : !ref_clk;
  assign fall =  ref_cpha_0 && strobe;
  assign rise = !ref_cpha_0 && strobe;
  // ------------

  /*
  reg [2:0] clk_cnt;
  reg [2:0] sel_cnt;
  
  reg       clk_en;
  reg       tmp;
  reg       strobe_r;
        
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      clk_cnt <= 3'h0;
    end else if ( strobe ) begin
      clk_cnt <= 3'h0;
    end else if ( en   ) begin
      clk_cnt <= clk_cnt + 3'h1;
    end
  end

  always @ ( * ) begin
    case ( sel )
      3'b000 : sel_cnt = 3'h7;
      3'b001 : sel_cnt = 3'h5;
      3'b010 : sel_cnt = 3'h3;
      3'b011 : sel_cnt = 3'h1;
      default : sel_cnt = 3'h0;
    endcase // case ( sel )
  end

  assign strobe_w = ( clk_cnt == sel_cnt );

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      strobe_r <= 1'b0;
    end else begin
      strobe_r <= strobe_w;
    end
  end

  assign strobe = strobe_r;
  

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      sclk_reg <= 1'b0;
    end else if ( sclk_en && strobe ) begin
      sclk_reg <= !sclk_reg;
    end
  end

  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      tmp <= cpol;
    end else if ( strobe ) begin
      tmp <= sclk_w;
    end
  end
        

  assign sclk_w = cpol ? !sclk_reg : sclk_reg;
  assign sclk   = cpha ? sclk_w : tmp;
  
  assign fall = sclk_reg && strobe;
  assign rise = !sclk_reg && strobe;*/
  // ------------

endmodule // baud_rate_gen
// ------------   
