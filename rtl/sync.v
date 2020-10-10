// ------------
// SYNC MODULE
// Parameters: NUM_SYNC_CHAINS - nums of flip-flop triggers for sync
module sync
#(parameter NUM_SYNC_CHAINS = 2)
(
    input rst_n,    // global reset, active LOW
    input clk,      // global clock
    input async,    // async data input
    output sync     // sync with this clock domain data output
);

// ------------
// Internal reg's
reg [NUM_SYNC_CHAINS - 1:0] shift_reg; // shift-register for sync

// ------------
// MODULE IMPLEMENTATION
always @ ( posedge clk or negedge rst_n ) begin
    if ( rst_n == 1'b0 )
        shift_reg <= {(NUM_SYNC_CHAINS){1'b0}};
    else
        shift_reg <= {shift_reg[NUM_SYNC_CHAINS - 2], async};
end

assign sync = shift_reg[NUM_SYNC_CHAINS - 1];
// ------------

endmodule
// ------------