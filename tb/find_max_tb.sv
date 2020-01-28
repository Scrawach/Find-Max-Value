////////////////////////////////
// ----------
// Module : find_max.sv
// Date   : January 28, 2020
// ----------
// Description:
// ----------
// Simple testbench for find_max module.
////////////////////////////////
module find_max_tb;

   // ----------
   // Internal logic variables
   logic       rst_n;
   logic       clk;
   logic       start;
   logic [7:0] in;
   wire        done;
   wire  [7:0] max_val;

   // ----------
   // Device under test
   find_max #(8) dut( .* );

   // ---------
   // Global signal assigment
   initial begin : global_clock
      clk <= 1'b0;
      forever #10 clk = ~clk;
   end

   initial begin : global_reset
      rst_n <= 1'b0;
      #15;
      rst_n <= 1'b1;
   end

   // ----------
   // Main test design
   initial begin : main

      start = 1'b0;
      in = 'b0;

      @ ( posedge rst_n );

      send_random_data(3);
      send_random_data(4);
      send_random_data(10);
      send_random_data(100);

      #10;
      $finish;
      
   end

   // ----------
   // Task's for test 
   // SEND RANDOM DATA
   // usage: - cycle - number of random values for comparison
   // example: send_random_data(5);
   task send_random_data;
      input integer cycle;
      logic [7:0]   tmp;
      begin
	 tmp = 0;
	 
	 @ ( negedge clk );
	 start = 1'b1;

	 repeat (cycle) begin
	    in = $urandom();
	    
	    if ( in > tmp )
	      tmp = in;
	    
	    @ ( posedge clk );
	 end

	 @ ( negedge clk );
	 start = 1'b0;

	 if ( max_val == tmp )
	   $display("OK!");
	 else
	   begin
	      $display("ERROR!");
	      $stop;
	   end
      end
   endtask // send_data
   
endmodule // find_max_tb
