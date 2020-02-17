// ----------
// Parameterizable data packet
// for verification "find max" module
class Packet #(type T = bit [7:0]);

  // --------
  // Randomize variable's
  rand T    data[];
  rand int  how_many;

  // --------
  // Answer from DUT
  T max_val;
  
  // --------
  // Local variable's
  local int low;
  local int high;

  // --------
  // Constraints for randomization
  constraint amount_of_data { how_many inside {[low:high]}; }
  constraint array_size     { data.size == how_many;    }

  // --------
  // Initialization
  function new( int min_size = 2, int max_size = 15 );
    this.low  = min_size;
    this.high = max_size;
  endfunction : new
  
  // --------
  // Display max value in current data packet
  function void print ( string tag = "" );
    $display("%0t: %s max value = 0x%0h, data packet:", $time, tag, max_val);
    
    foreach ( data[i] ) begin
      $display("\t [%0d]: data = 0x%0h", i, data[i]);
    end
  endfunction : print
  
  // --------
  // Simple copy function from another packet class
  function void copy ( Packet tmp );
    this.data     = tmp.data;
    this.how_many = tmp.how_many;
    this.max_val  = tmp.max_val;
  endfunction : copy
  
endclass : Packet
// ----------

// ----------
// Generate rand data packet
// and transmit it to driver
class generator;

  // --------
  // Mailbox, that storage packet's
  // and event, signs end of one transaction
  mailbox drv_mbx;
  event   drv_done;

  // --------
  // Local variable's
  local int loop;

  // --------
  // Initialization
  function new ( mailbox mbx, event done, int num = 20 );
    this.drv_mbx  = mbx;
    this.drv_done = done;
    this.loop     = num;
  endfunction : new

  // --------
  // Run task for start generate process
  task run();
    $display("%0t: [GENERATOR] starting...", $time);

    for ( int i = 0; i < loop; i++ ) begin
      Packet pkt = new();
      assert ( pkt.randomize() ) else $error("%0t: [GENERATOR] randomize failed!", $time);
      $display("%0t: [GENERATOR] Loop: %0d/%0d. Create next packet.", $time, i+1, loop);
      drv_mbx.put(pkt);
      $display("%0t: [GENERATOR] Wait for driver to be done", $time);
      @(drv_done); 
    end
  endtask : run
  
endclass : generator
// ----------

// ----------
// Receive data packet from generator
// and transmit it to DUT
class driver;

  // --------
  // Virtual interface (DUT)
  virtual fm_if vif;

  // --------
  // Mailbox, that storage packet's
  // and event, signs end of one transaction
  mailbox drv_mbx;
  event   drv_done;

  // --------
  // Initialization
  function new ( mailbox mbx, event done, virtual fm_if vif);
    this.drv_mbx  = mbx;
    this.drv_done = done;
    this.vif      = vif;
  endfunction : new

  // --------
  // Run task for start driver
  task run();
    $display("%0t: [DRIVER] starting...", $time);

    forever begin
      Packet pkt;
      $display("%0t: [DRIVER] waiting for packet...", $time);
      drv_mbx.get(pkt);
      @ ( posedge vif.clk );
      pkt.print("[DRIVER]");

      foreach ( pkt.data[i] ) begin
        vif.start <= 1'b1;
        vif.data  <= pkt.data[i];
        @ ( posedge vif.clk );
      end

      vif.start <= 1'b0;
      
      // When transfet is over, raise the done event
      ->drv_done;
    end
  endtask : run

endclass : driver
// ----------

// ----------
// Monitor sees new transactions and
// send it to scoreboard using mailbox
class monitor;

  // --------
  // Virtual interface (DUT)
  virtual fm_if vif;

  // --------
  // Mailbox, that storage packet's
  mailbox scb_mbx;

  // --------
  // Initialization
  function new ( mailbox mbx, virtual fm_if vif );
    this.scb_mbx = mbx;
    this.vif     = vif;
  endfunction : new
  
  // --------
  // Run task for start monitor process
  task run();
    $display("%0t: [MONITOR] starting...", $time);

    forever begin
      @ ( posedge vif.clk );

      // Not reset and up start signs about transaction
      if ( vif.start ) begin
        Packet pkt = new();

        while ( vif.start ) begin
          pkt.how_many++;
          pkt.data    = {pkt.data, vif.data};
          @ ( posedge vif.clk );
          pkt.max_val = vif.max_val; 
        end

        $display("%0t: [MONITOR] transaction is over.", $time);
        scb_mbx.put(pkt);
      end
    end
  endtask : run
  
endclass : monitor
// ----------

// ----------
// The scorevoard check, that max value
// is valid for current transaction.
class scoreboard;

  // --------
  // Static variable's with testing result's
  static int err_num;
  static int tst_num;
  
  // --------
  // Virtual interface (DUT)
  virtual fm_if vif;
  
  // --------
  // Mailbox, that storage packet's
  mailbox scb_mbx;

  // --------
  // Initialization
  function new( mailbox mbx, virtual fm_if vif );
    this.scb_mbx = mbx;
    this.vif     = vif;
  endfunction : new

  // --------
  // Run task for start scoreboard
  task run();
    $display("%0t: [SCOREBOARD] starting...", $time);
    
    forever begin
      Packet pkt;
      Packet ref_pkt = new;
      
      scb_mbx.get(pkt);
      pkt.print("[SCOREBOARD]");

      // Deep copy contents from receved packet into
      // a new packet for get data values.
      ref_pkt.copy(pkt);

      // Find max value from packet
      foreach ( ref_pkt.data[i] ) begin
        if ( ref_pkt.data[i] > ref_pkt.max_val )
          ref_pkt.max_val = ref_pkt.data[i];
      end

      // Now max value can be compared
      if ( ref_pkt.max_val != pkt.max_val ) begin
        $display("%0t: [SCOREBOARD] ERROR! Max value's mismatch: expected/get = 0x%0h/0x%0h", $time, ref_pkt.max_val, pkt.max_val);
        err_num++;
      end else begin
        $display("%0t: [SCOREBOARD] PASS! Max value's match: expected/get = 0x%0h/0x%0h", $time, ref_pkt.max_val, pkt.max_val);
      end

      tst_num++;
    end
  endtask : run
  
endclass : scoreboard
// ----------

// ----------
// The enviroment contain object's for verification
class enviroment;

  // --------
  // Virtual interface (DUT)
  virtual fm_if vif;

  // --------
  // Classes for realize verification
  generator     gen0;     // generator handle
  driver        drv0;     // driver handle
  monitor       mon0;     // monitor handle
  scoreboard    scb0;     // scoreboard handle

  // --------
  // Variable's between classes
  mailbox       drv_mbx;  // Connect GEN & DRV
  mailbox       scb_mbx;  // Connect MON & SCB
  event         drv_done; // Indicate, when driver is done

  // --------
  // Initialization
  function new( virtual fm_if vif );
    this.vif = vif;

    drv_mbx  = new ();
    scb_mbx  = new ();
    
    gen0     = new ( drv_mbx, drv_done           );
    drv0     = new ( drv_mbx, drv_done, this.vif );
    mon0     = new ( scb_mbx, this.vif           );
    scb0     = new ( scb_mbx, this.vif           );  
  endfunction : new

  // --------
  // Run task for start verification
  virtual task run();
    fork
      gen0.run();
      drv0.run();
      mon0.run();
      scb0.run();
    join_any

    disable fork;
  endtask : run
  
endclass : enviroment
// ----------

// ----------
// Test class instantiates the enviroment and start it
class test;

  // --------
  // Control variable's
  int err_num;
  int tst_num;
  
  // --------
  // Local enviroment
  local enviroment env0;

  // --------
  // Initialization
  function new ( virtual fm_if vif );
    env0 = new ( vif );
  endfunction : new    

  // --------
  // Run task for start verification
  task run();
    env0.run();
    
    err_num = env0.scb0.err_num;
    tst_num = env0.scb0.tst_num;
  endtask : run
  
endclass : test
// ----------
