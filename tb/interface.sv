// Find max interface contains all signals that
// the module requires to operate.
interface fm_if ( input bit clk );

  logic       rst_n;
  logic       start;
  logic [7:0] data;
  logic       done;
  logic [7:0] max_val;
  
endinterface : fm_if 
