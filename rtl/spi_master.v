// ------------
// SPI MASTER TRANSCEIVER CORE
// Description: SPI (Serial Peripheral Interface) Master
//
// Send bytes while tx_start is UP (HIGH).
// Receive bytes while rx_start is UP (HIGH).
//
// Can select SPI mode (cpol / cpha).
// About SPI mode: https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Mode_numbers
//
// Parameters: WIDTH       - transaction width (std is 8 bit's)
//             CLK_PER_BIT - frequence of SCLK (SPI CLK)
// -------------
module spi_master
  #(parameter WIDTH = 8)
  (
   input                 rst_n,        // global reset
   input                 clk,          // global clock
   // ------------
   input  [         1:0] mode,         // SPI transceiver mode
   input                 tx_start,     // start transmit
   input                 rx_start,     // start receive
   input  [WIDTH - 1: 0] data_in,      // parallel input data bus
   output [WIDTH - 1: 0] data_out,     // parallel output data bus
   output                tx_done,      // done transmit one transaction
   output                rx_done,      // done receive one transaction
   // ------------
   output                load,         // done load data from data_in bus
   output                read,         // start read data from spi_data_in (MISO)
   // ------------
   input                 spi_data_in,  // SDI (MISO)
   output                cs_n,         // chip select (slave select)
   output                spi_data_out, // SDO (MOSI)
   output                spi_clk       // SCLK
   );

  // ------------
  // Internal parameter's
  localparam
    IDLE     = 5'b00001, // IDLE state, nothing to do
    LOAD     = 5'b00010, // LOAD data from data_in bus
    TRANSMIT = 5'b00100, // Send data to SDI (MISO)
    ST_READ  = 5'b01000, // Start read data from SDO (MOSI)
    RECEIVE  = 5'b10000; // Read data from SDO (MOSI)

  localparam
    CNT_WIDTH = $clog2(WIDTH);        // WIDTH for bit counter

  // ------------
  // Internal wire's
  wire               spi_sync_in;  // sync MISO line
  wire               spi_strobe;   // strobe for clock (SCLK) generate
  wire               pha_clk_en;   // select clock enable phase
  wire               tx_clk_en;    // transmit clock enable
  wire               rx_clk_en;    // receive clock enable
  wire               cpol;         // clock polarity (for select SPI mode)
  wire               cpha;         // clock phase    (for select SPI mode)
  wire               is_last_bit;  // sign, that now is last bit
  wire               tx_done_cond; // condition for generate tx_done
  wire               rx_done_cond; // condition for generate rx_done
  
  // ------------
  // Internal register's
  reg [        4: 0] state, state_nxt;         // main FSM 
  reg [WIDTH - 1: 0] tx_buf, tx_buf_nxt;       // transmit buffer
  reg [WIDTH - 1: 0] rx_buf, rx_buf_nxt;       // receive shift-buffer
  reg [WIDTH - 1: 0] buf_out, buf_out_nxt;     // output received data buffer
  reg [CNT_WIDTH: 0] bit_cnt, bit_cnt_nxt;     // bit counter (in one transmit)
  reg [        1: 0] mode_reg, mode_reg_nxt;   // SPI mode storage

  reg                spi_clk_reg, spi_clk_nxt; // SCLK reg
  reg                spi_clk_en;               // enable for generate SCLK
  reg                spi_data_out_reg;         // SPI SDO reg

  reg                tx_done, tx_done_nxt;
  reg                rx_done, rx_done_nxt;
    
  // ------------
  // MODULE IMPLEMENTATION
  // SYNC MODULE BLOCK for input SPI data
  sync #(.NUM_SYNC_CHAINS(2)) sync_miso_inst ( .rst_n  ( rst_n       ),
                                               .clk    ( clk         ),
                                               .async  ( spi_data_in ),
                                               .sync   ( spi_sync_in ));

  // DIVIDE GLOBAL CLOCK for generate strobe SPI clock
  div_clk #(.DIVIDER(4)) div_clk_inst ( .rst_n   ( rst_n      ),
                                        .clk     ( clk        ),
                                        .en      ( busy       ),
                                        .div_clk ( spi_strobe ));

  // ------------
  // USEFUL wire's assign's
  assign busy         = ( state != IDLE );
  assign load         = ( state == LOAD );
  assign read         = ( state == ST_READ );

  assign is_last_bit  = ( bit_cnt == WIDTH );
  assign tx_done_cond = ( state == TRANSMIT ) && is_last_bit;
  assign rx_done_cond = ( state == RECEIVE  ) && is_last_bit;

  assign pha_clk_en   = (!cpha && spi_clk_en) ? !spi_clk_reg : spi_clk_reg;
  assign tx_clk_en    = spi_strobe && pha_clk_en;
  assign rx_clk_en    = spi_strobe && !pha_clk_en;

  assign {cpol, cpha} = mode_reg;
  assign spi_data_out = spi_data_out_reg;
  assign spi_clk      = cpol ? spi_clk_reg : !spi_clk_reg;
  
  assign data_out     = buf_out;
  assign cs_n         = !busy;
          
  // ------------
  // CLOCK ENABLE for shift clock phase (cpha)
  always @ ( posedge clk or negedge rst_n ) begin
    if      ( rst_n == 1'b0 ) spi_clk_en <= cpha;
    else if ( state == IDLE ) spi_clk_en <= cpha;
    else if ( spi_strobe    ) spi_clk_en <= 1'b1;
  end // always @ ( posedge clk or negedge rst_n )
          
  // ------------
  // GENERATE SPI CLK with 50% duty cycle
  always @ ( * ) begin
    case ( state )
      IDLE    : spi_clk_nxt = 1'b1;
      
      default : 
        if ( spi_clk_en && !( (tx_clk_en && tx_done_cond) || (rx_clk_en && rx_done_cond) ) )
          spi_clk_nxt = spi_strobe ? !spi_clk_reg : spi_clk_reg;
        else
          spi_clk_nxt = 1'b1;
    endcase // case ( state )
  end 
  
  // ------------
  // SPI MOSI
  always @ ( posedge clk or negedge rst_n ) begin
    if      ( rst_n == 1'b0 )               spi_data_out_reg <= 1'b1;
    else if ( tx_clk_en     ) begin
      if      ( tx_done_cond && !tx_start ) spi_data_out_reg <= 1'b1;
      else if ( state == TRANSMIT         ) spi_data_out_reg <= tx_buf[WIDTH - 1];
      else                                  spi_data_out_reg <= 1'b1;
    end
  end

  // ------------
  // SELECT SPI MODE
  always @ ( * ) begin
    case ( state )
      IDLE    : mode_reg_nxt = mode;
      default : mode_reg_nxt = mode_reg;
    endcase // case ( state )
  end
  
  // ------------
  // TRANSMIT DATA BUFFER
  always @ ( * ) begin
    case ( state )
      LOAD     : tx_buf_nxt = data_in;
      TRANSMIT : tx_buf_nxt = tx_clk_en ? tx_buf << 1 : tx_buf;
      default  : tx_buf_nxt = tx_buf;
    endcase // case ( state )
  end

  // ------------
  // RECEIVER DATA BUFFER
  always @ ( * ) begin
    case ( state )
      RECEIVE : rx_buf_nxt = rx_clk_en ? {rx_buf[WIDTH - 2: 0], spi_sync_in} : rx_buf;
      default : rx_buf_nxt = rx_buf;
    endcase // case ( state )
  end

  // ------------
  // OUTPUT BUFFER for DATA_OUT
  always @ ( * ) begin
    case ( state )
      RECEIVE : buf_out_nxt = ( is_last_bit ) ? rx_buf : buf_out;
      default : buf_out_nxt = buf_out;
    endcase // case ( state )
  end

  // ------------
  // BIT COUNTER
  always @ ( * ) begin
    case ( state )
      TRANSMIT : bit_cnt_nxt = tx_clk_en ? bit_cnt + 1'b1 : bit_cnt;
      RECEIVE  : bit_cnt_nxt = rx_clk_en ? bit_cnt + 1'b1 : bit_cnt;
      default  : bit_cnt_nxt = {(CNT_WIDTH + 1){1'b0}};
    endcase // case ( state )
  end

  // ------------
  // TX DONE
  always @ ( * ) begin
    if ( tx_done_cond ) begin
      tx_done_nxt = 1'b1;
    end else begin
      tx_done_nxt = 1'b0;
    end
  end

  // ------------
  // RX DONE
  always @ ( * ) begin
    if ( rx_done_cond ) begin
      rx_done_nxt = 1'b1;
    end else begin
      rx_done_nxt = 1'b0;
    end
  end
    
  // ------------
  // MAIN FSM IMPLEMENTATION
  always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 ) begin
      state       <= IDLE;
      tx_buf      <= {(WIDTH){1'b0}};
      rx_buf      <= {(WIDTH){1'b0}};
      bit_cnt     <= {(CNT_WIDTH){1'b0}};
      buf_out     <= {(WIDTH){1'b0}};
      mode_reg    <= 2'b00;
      spi_clk_reg <= 1'b0;
      tx_done     <= 1'b0;
      rx_done     <= 1'b0;    
    end
    else begin
      state       <= state_nxt;
      tx_buf      <= tx_buf_nxt;
      rx_buf      <= rx_buf_nxt;
      bit_cnt     <= bit_cnt_nxt;
      buf_out     <= buf_out_nxt;
      mode_reg    <= mode_reg_nxt;
      spi_clk_reg <= spi_clk_nxt;
      tx_done     <= tx_done_nxt;
      rx_done     <= rx_done_nxt;
    end
  end // always @ ( posedge clk or negedge rst_n )

  // STATE CHANGE's conditions
  always @ ( * ) begin
    case ( state )
      IDLE     :
        if      ( tx_start ) state_nxt = LOAD;
        else if ( rx_start ) state_nxt = ST_READ;
        else                 state_nxt = IDLE;

      LOAD     :
        state_nxt = TRANSMIT;

      TRANSMIT :
        if ( is_last_bit ) begin
          if      ( tx_start  ) state_nxt = LOAD;
          else if ( rx_start  ) state_nxt = ST_READ;
          else if ( tx_clk_en ) state_nxt = IDLE;
          else                  state_nxt = TRANSMIT;
        end else begin
          state_nxt = TRANSMIT;
        end

      ST_READ :
        state_nxt = rx_clk_en ? RECEIVE : ST_READ;
      
      RECEIVE  :
        if ( is_last_bit ) begin
          if      ( rx_start  ) state_nxt = ST_READ;
          else if ( rx_clk_en ) state_nxt = IDLE;
          else                  state_nxt = RECEIVE;
        end else begin
          state_nxt = RECEIVE;
        end

      default  :
        state_nxt = IDLE;
    endcase // case ( state )
  end 
  // ------------
  
endmodule // spi_master
// ------------
