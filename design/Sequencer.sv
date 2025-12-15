//-----------------------------------------------------------------------
// FILE: Sequencer.sv
//
// DESCRIPTION:
//   Sequencer component that generates and sends transactions to driver
//   and reference model. Includes directed and random test scenarios.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: Sequencer
//
// DESCRIPTION:
//   Generates stimulus for verification. Provides both directed test
//   sequences and constrained-random generation capabilities.
//-----------------------------------------------------------------------
class Sequencer;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local mailbox #(BusTrans) m_seq_drv_mb;
	local mailbox #(BusTrans) m_seq_ref_mb;
	local BusTrans m_bus_tr;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for Sequencer class.
	//
	// PARAMETERS:
	//   i_seq_drv_mb - (input) Sequencer to driver mailbox
	//   i_seq_ref_mb - (input) Sequencer to reference model mailbox
	//-----------------------------------------------------------------------
	function new(mailbox#(BusTrans) i_seq_drv_mb, mailbox#(BusTrans) i_seq_ref_mb);
		m_seq_drv_mb = i_seq_drv_mb;
		m_seq_ref_mb = i_seq_ref_mb;
	endfunction

	//-----------------------------------------------------------------------
	// TASK: send_trans
	//
	// DESCRIPTION:
	//   Helper task to send transaction to driver and reference model.
	//   Centralizes ID increment, mailbox put, and display logic.
	//
	// PARAMETERS:
	//   i_tr - (input) Transaction to send
	//-----------------------------------------------------------------------
	task automatic send_trans(BusTrans i_tr);
		i_tr.ID_increment();
		m_seq_drv_mb.put(i_tr);
		m_seq_ref_mb.put(i_tr);
		i_tr.display("SEQ");
	endtask

    // =================================================================
    //  RANDOM STIMULUS (VPlan Slide 2 & 5: Random_RW)
    // =================================================================
    
    // Generates mixed Read and Write transactions based on constraints
    task automatic rand_read_write(input int num_transactions);
        $display("\n[%0t]: [SEQ] START: Random Read/Write (%0d transactions)", $time, num_transactions);
        
        repeat (num_transactions) begin
            // Randomly choose Read (0) or Write (1)
            if ($urandom_range(0, 1)) begin
                automatic WriteTrans new_write_trans = new();
                if (!new_write_trans.randomize()) 
                    $error("[%0t]: [SEQ] Error: Randomization failed for WriteTrans", $time);
                new_write_trans.m_write_en = (new_write_trans.m_kind == WRITE) ? 1 : 0; // Sync
                send_trans(new_write_trans);
            end else begin
                automatic ReadTrans new_read_trans = new();
                if (!new_read_trans.randomize()) 
                    $error("[%0t]: [SEQ] Error: Randomization failed for ReadTrans", $time);
                new_read_trans.m_write_en = (new_read_trans.m_kind == WRITE) ? 1 : 0; // Sync
                send_trans(new_read_trans);
            end
        end
    endtask 

    // =================================================================
    //  DIRECTED TASKS (VPlan Slide 5: Test Support)
    // =================================================================

    // --- Loading the Timer (Address 0x04) ---
    // Supports VPlan R4: Writing 0 to LOAD_VAL
    task automatic loading(input [P_DATA_WIDTH-1:0] i_load_data);
        automatic WriteTrans new_write_trans = new();
        $display("[%0t]: [SEQ] Loading Timer with value: 0x%0h", $time, i_load_data);
        
        new_write_trans.m_addr = 32'h04; // LOAD register
        new_write_trans.m_data = i_load_data;
        new_write_trans.m_write_en = 1'b1;
        
        send_trans(new_write_trans);
    endtask 

    // --- Start Countdown / Reload Config (Address 0x00) ---
    // i_reload_en: 0 = One-Shot, 1 = Auto-Reload
    task automatic start_count_i_reload(input bit i_reload_en);
        automatic WriteTrans new_write_trans = new();
        
        new_write_trans.m_addr = 32'h00; // CONTROL register
        new_write_trans.m_write_en = 1'b1;

        if (i_reload_en) begin
            $display("[%0t]: [SEQ] Start Countdown: Auto-Reload Mode (ENABLE=1, RELOAD=1)", $time);
            new_write_trans.m_data = 32'h00000003; // Bits [1:0] = 11
        end else begin
            $display("[%0t]: [SEQ] Start Countdown: One-Shot Mode (ENABLE=1, RELOAD=0)", $time);
            new_write_trans.m_data = 32'h00000001; // Bits [1:0] = 01
        end
        
        send_trans(new_write_trans);
    endtask 

    // --- Check Status (Address 0x08) ---
    // VPlan R5: Reading STATUS should clear the EXPIRED flag
    task automatic checking_status();
        automatic ReadTrans new_read_trans = new();
        $display("[%0t]: [SEQ] Reading STATUS register (Expect Read-to-Clear)", $time);
        
        new_read_trans.m_addr = 32'h08; // STATUS register
        new_read_trans.m_write_en = 1'b0;
        
        send_trans(new_read_trans);
    endtask 

    // --- Specific Write (Generic) ---
    // Used in Test2
    task automatic specific_write(input [P_ADDR_WIDTH-1:0] i_addr, input [P_DATA_WIDTH-1:0] i_data);
        automatic WriteTrans new_write_trans = new();
        $display("[%0t]: [SEQ] Specific Write: Addr=0x%h, Data=0x%h", $time, i_addr, i_data);
        
        new_write_trans.m_addr = i_addr;
        new_write_trans.m_data = i_data;
        new_write_trans.m_write_en = 1'b1;
        
        send_trans(new_write_trans);
    endtask 

    // --- Specific Read (Generic) ---
    // Used in Test2
    task automatic specific_read(input [P_ADDR_WIDTH-1:0] i_addr);
        automatic ReadTrans new_read_trans = new();
        $display("[%0t]: [SEQ] Specific Read: Addr=0x%h", $time, i_addr);
        
        new_read_trans.m_addr = i_addr;
        new_read_trans.m_write_en = 1'b0;
        
        send_trans(new_read_trans);
    endtask

    // --- Stop/Reset Timer via Control ---
    task automatic status_reset();
        automatic WriteTrans new_write_trans = new();
        $display("[%0t]: [SEQ] Stopping Timer (Writing 0 to Control)", $time);
        
        new_write_trans.m_addr = 32'h00; // CONTROL
        new_write_trans.m_data = 32'h00; // Disable
        new_write_trans.m_write_en = 1'b1;
        
        send_trans(new_write_trans);
    endtask

    // =================================================================
    //  COVERAGE CLOSURE TASKS (Targeting Missing Bins)
    // =================================================================
    
    // Purpose: Perform specific operations to hit the remaining coverage holes.
    // 1. Write to STATUS (Address 0x08) - Should be ignored/safe.
    // 2. Read from CONTROL (Address 0x00) - Should return current config.
    task automatic coverage_closure_test();
        $display("\n[%0t]: [SEQ] START: Coverage Closure (Targeting Holes)", $time);

        // 1. Write to STATUS (0x08)
        // This targets the bin <write, status_addr> in kind_addr_cross
        specific_write(32'h08, 32'hFFFFFFFF); 

        #50;

        // 2. Read from CONTROL (0x00)
        // This targets the bin <read, control_addr> in kind_addr_cross
        specific_read(32'h00);

        #50;
    endtask

endclass