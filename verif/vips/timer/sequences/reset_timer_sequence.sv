///////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:        MICRO-ELECTRONICS RESEARCH LABORATORY                                             //
//                                                                                                   //
// Engineers:      Auringzaib Sabir - Verification                                                   //
//                                                                                                   //
// Additional contributions by:                                                                      //
//                                                                                                   //
// Create Date:    05-JAN-2022                                                                       //
// Design Name:    TIMER                                                                             //
// Module Name:    reset_timer_sequence.sv                                                           //
// Project Name:   VIPs for different peripherals                                                    //
// Language:       SystemVerilog - UVM                                                               //
//                                                                                                   //
// Description:                                                                                      //
//       - Sequence can be one or many seqeunce items and the sequence is not the part of            //
//         component heirarchy                                                                       //
//       - Note that tx_sequnce is extended from uvm_sequnce base class                              //
//       - uvm_sequnce is define in uvm_pkg                                                          //
//       - UVM components are permanent because they are never destroyed, they are created at the    //
//         start of simulation and exist for the entire simulation                                   //
//       - Whereas stimulus are temporary because thousands of transactions are created and          //
//         destroyed during simulation                                                               //
//       - Components are hierarical i.e. they have fixed location in topology.                      //
//       - Transactions do not have fixed location because transaction move throught the components. //
//       - sequnce is parameterize class, as shown here the config_timer_sequence only send          // 
//         config_xactn_timer transaction                                                            //
//                                                                                                   //
//       This sequence will reset the timer by setting active low reset
//                                                                                                   //
// Revision Date:                                                                                    //
//                                                                                                   //
///////////////////////////////////////////////////////////////////////////////////////////////////////

class reset_timer_sequence extends uvm_sequence #(config_xactn_timer);
	// For sequence we have to register this object with uvm factory using macro uvm_object
  // Pass the class name to it
  `uvm_object_utils(reset_timer_sequence)

  /*
	Then declare reset_timer_sequence class constructor
	Since a class object has to be constructed before it exit in a memory
	The creation of class hierarchy in a system verilog testbench has to be initiated from a top module.
	Since a module is static object that is present at beginning of simulation 
	*/
  function new (string name="reset_timer_sequence");
    super.new(name);
    // In constructor this object can be randomize to set the block size, typicaly we don't randomize in constructor
    if(!this.randomize())
    	`uvm_fatal("FATAL_ID",$sformatf("Number of transaction is not randomized"))
  endfunction // new

  tx_agent_config tx_agent_config_h   ; // Declaration of agent configuraton object, for configuring sequence
  event           timer_activated_evnt;
  
  // Every sequence has a method called pre start which is called before body
  task pre_start();
  	if(!uvm_config_db#(tx_agent_config)::get(null/*instead to "this" reletive path use absolute path*/ /*this*/ /*You will get error if your write "this" because "this" means reset_timer_sequence which is transaction not a uvm_component and we need uvm component to pass*/, get_full_name() /*usually for get these commas are empty, but here we will define absolute path by get_full_name()*/, "tx_agent_config_h", tx_agent_config_h))
  		`uvm_fatal("NO AGENT CONFIG",$sformatf("No Agent configuration found in db"))
  endtask : pre_start
  
  // For generating random number of transactions. Just as single transaction can be randomize entire sequences can be randomize. This way you sequences act differently everytime it is run. 
  rand bit [15:0] num_of_xactn;
  constraint size {soft num_of_xactn inside {5,15};}
  
  // A sequence is a block of procedural code that have been wrapped in a method called body
  // Task can have delays
  // Note: Driver limits how fast the stimulus can be applied to the driver by sequence, since the sequence is connected to driver it can send a new transaction when driver is ready
  virtual task body();
    // transaction of type config_xactn_timer
    config_xactn_timer tx               ;
    bit [ 63:0]        data             ;
    bit                lower_data_en    ;
    bit [ 31:0]        upper_data       ;
    bit [ 31:0]        lower_data       ;
    bit [ 11:0]        prescale      = 0;
    bit [23:16]        step          = 0;
    string msg="";

    // reset_timer_sequence is going to generate 5 transactions of type config_xactn_timer
    repeat(2) begin
      `uvm_info("reset_timer_sequence::",$sformatf("reset_timer_sequence"), UVM_LOW)
      tx = config_xactn_timer::type_id::create("tx");            // Factory creation (body task create transactions using factory creation)
      start_item(tx);                                            // Waits for a driver to be ready
      if(!tx.randomize())                                        // It randomize the transaction
        `uvm_fatal("ID","transaction is not randomize")          // If it not randomize it will through fatal error
      // Reseting the timer
      tx.rst_ni    =  0 ;
      tx.reg_we    =  0 ;
      tx.reg_re    =  0 ;
      tx.reg_addr  = '0 ;
      tx.reg_wdata = '0 ;
      tx.reg_be    = '0 ;
      finish_item(tx);                                           // After randommize send it to the driver and waits for the response from driver to know when the driver is ready again to generate and send the new transaction and so on.
    end
  endtask // body
endclass // reset_timer_sequence
