// ----------
// Define settings
`define CLK_PERIOD 20

// ----------
// Top (Testbench) module
module testbench;

  // --------
  // Main clock signal
  bit clk;

  // --------
  // Instance's verification parts
  test  t0;
  fm_if _if (clk);

  // --------
  // Device under test
  find_max dut( .clk     ( clk         ),
                .rst_n   ( _if.rst_n   ),
                .start   ( _if.start   ),
                .in      ( _if.data    ),
                .max_val ( _if.max_val ),
                .done    ( _if.done    ));

  // --------
  // Generate global signals
  initial begin : clock
    clk <= 1'b0;
    forever #(`CLK_PERIOD/2) clk = ~clk;
  end

  initial begin : reset
    _if.data  <=  'b0;
    _if.start <= 1'b0;
    _if.rst_n <= 1'b0;
    repeat (2) @ ( negedge clk );
    _if.rst_n <= 1'b1;
  end
  // --------

  // --------
  // Simple cover group with
  // automatic (implicit) bins 
  covergroup cg @ ( posedge clk );
    coverpoint _if.start;
    coverpoint _if.done;
    coverpoint _if.rst_n;
    coverpoint _if.data;
    coverpoint _if.max_val;
    coverpoint dut.state;
  endgroup // cg
  // --------

  // --------
  // Main initial block
  initial begin : main
    // Initialization cover group
    cg cg_inst = new();
    t0 = new ( _if );

    wait ( _if.rst_n );

    // Run test while cover group not equal 100%
    while ( cg_inst.get_inst_coverage() != 100 ) begin
      t0.run();
    end
    
    #50;
    $finish;   
  end // initial begin
  // --------

  // --------
  // Final block with 
  // amount of error's
  final begin : fin
    $display("%0t: TEST END!", $time);
    $display("Total errors = %0d,  Total test packets =  %0d.", t0.err_num, t0.tst_num);
  end
  // --------
  
endmodule : testbench
// ----------
