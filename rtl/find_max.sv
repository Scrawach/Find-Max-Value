////////////////////////////////
// ----------
// Module : find_max.sv
// Date   : January 28, 2020
// ----------
// Description:
// ----------
// FIND MAXIMUM VALUE:
// Given the value on every clock after set signal Start,
// return maximum value from inputs after reset Start.
// Also it create signal Done for next clock.
////////////////////////////////
module find_max
#( parameter WIDTH = 8 )
(
 input  logic 		  rst_n,  // global reset signal, active LOW
 input  logic 		  clk,    // global clock signal
 input  logic 		  start,  // for start comparison
 input  logic [WIDTH-1:0] in,     // input values
 output logic 		  done,   // signs, that comparison is done
 output logic [WIDTH-1:0] max_val // maximum values from inputs
 );

   // ----------
   // Local typedef for state machine
   typedef enum logic
		{IDLE = 1'b0,
		 WORK = 1'b1} state_t;

   // ----------
   // Internal logic variable's
   logic 	clear;
   logic 	load;
   state_t      state;
   state_t      next_state;

   // ----------
   // Finite-state machine for control data path
   always_ff @ ( posedge clk or negedge rst_n )
     if ( ~rst_n )
       state <= IDLE;
     else
       state <= next_state;

   always_comb begin
      case ( state )
	IDLE: next_state <=  start ? WORK : IDLE;
	WORK: next_state <= ~start ? IDLE : WORK;
      endcase // case ( state )
   end

   assign done  = ~start & ( state == WORK );
   // ----------
   
   // ----------
   // Register, that storage max value
   assign clear = ~start;
   assign load  = in > max_val;
   
   always_ff @ ( posedge clk or negedge rst_n )
     if ( ~rst_n )
       max_val <= 'b0;
     else if ( clear )
       max_val <= 'b0;
     else if ( load )
       max_val <= in;
   // ----------

endmodule // find_max
