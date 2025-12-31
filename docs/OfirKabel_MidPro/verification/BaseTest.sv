//-----------------------------------------------------------------------
// FILE: BaseTest.sv
//
// DESCRIPTION:
//   Base test class containing test scenarios and verification plan.
//   Includes functional tests, corner cases, and random stress tests.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: BaseTest
//
// DESCRIPTION:
//   Implements verification plan with directed tests, corner case tests,
//   and random stimulus generation.
//-----------------------------------------------------------------------
class BaseTest;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local Sequencer m_seq;
	local TbEnv m_env;
	local virtual bus_if.bus_if m_vif;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for BaseTest. Creates environment and sequencer.
	//
	// PARAMETERS:
	//   i_vif - (input) Virtual interface to DUT
	//-----------------------------------------------------------------------
	function new(input virtual bus_if.bus_if i_vif);
		m_vif = i_vif;
		m_env = new(m_vif);
		m_seq = new(m_env.get_seq_drv_mb(), m_env.get_seq_ref_mb());
	endfunction

    // --- Global Reset Task ---
    task automatic reset();
        $display("\n[%0t] [TEST] Applying Global Reset...", $time);
        m_env.reset(); 
    endtask 

    // =================================================================
    //  TEST SCENARIOS (From VPlan Slide 5)
    // =================================================================

    // -----------------------------------------------------------------
    // Test1: Basic Functional Countdown
    // Purpose: Load 7, start, wait for expire, check status.
    // -----------------------------------------------------------------
    task automatic Test1();
        $display("\n=== STARTING TEST 1: Basic Countdown (One-Shot) ===");
        m_seq.status_reset(); // Ensure safe start
        
        m_seq.loading(32'h00000007);
        #50;
        m_seq.start_count_i_reload(0); // 0 = One-shot
        
        // Wait for countdown (approx 7 * 10ns)
        #150; 
        
        m_seq.checking_status(); // Should read 1 (Expired) and clear it
        #50;
        m_seq.checking_status(); // Should read 0 (Already cleared)
        
        m_seq.status_reset();
    endtask 

    // -----------------------------------------------------------------
    // Test2: Specific Register Access
    // Purpose: Verify specific R/W to registers.
    // -----------------------------------------------------------------
    task automatic Test2();
        $display("\n=== STARTING TEST 2: Specific Register Access ===");
        
        // Write/Read LOAD register
        m_seq.specific_write(32'h04, 32'h0000000F); 
        #100;
        m_seq.specific_read(32'h04);
        
        // Write/Read CONTROL register
        #100;
        m_seq.specific_write(32'h00, 32'h00000003); 
        #100;
        // Read Status (Check if timer started)
        m_seq.specific_read(32'h08);
        #100;
    endtask
            
    // -----------------------------------------------------------------
    // Test3: Complex Sequences & Reset
    // Purpose: Multiple loads, reloading, and hardware reset check.
    // -----------------------------------------------------------------
    task automatic Test3();
        $display("\n=== STARTING TEST 3: Complex Sequences & Reset ===");
        
        // Start a cycle
        m_seq.loading(32'h00000005);
        m_seq.start_count_i_reload(1); // Auto-reload
        #200;
        
        // Assert Hardware Reset in middle of operation
        $display("[%0t] [TEST] Asserting Hardware Reset!", $time);
        reset(); 
        #50;
        
        // Check if registers cleared
        m_seq.checking_status(); 
        
        // Resume operation
        m_seq.loading(32'h0000000A);
        m_seq.start_count_i_reload(1);
        #300;
        
        // Change load value while running (Edge case)
        m_seq.loading(32'h00000003);
        #200;
        
        m_seq.status_reset();
    endtask 

    // -----------------------------------------------------------------
    // Load_Zero (Planned Test)
    // Purpose: Corner Case R4 - Loading 0 should behave as 1 cycle.
    // -----------------------------------------------------------------
    task automatic Load_Zero_Test();
        $display("\n=== STARTING TEST: Load Zero Corner Case ===");
        m_seq.status_reset();
        
        m_seq.loading(32'h0); // Load 0
        m_seq.start_count_i_reload(0); // One-shot
        
        // Should expire almost immediately (1 cycle)
        #50; 
        m_seq.checking_status();
        
        m_seq.status_reset();
    endtask

    // -----------------------------------------------------------------
    // Start_Mid_Count (Planned Test)
    // Purpose: Restarting timer while it is already running.
    // -----------------------------------------------------------------
    task automatic Start_Mid_Count_Test();
        $display("\n=== STARTING TEST: Start Mid-Count Restart ===");
        m_seq.status_reset();
        
        // 1. Start a long timer (20 cycles)
        m_seq.loading(32'd20);
        m_seq.start_count_i_reload(0);
        
        #50; // Let it run a bit
        
        // 2. Restart immediately with short timer (3 cycles)
        $display("[%0t] [TEST] Restarting with new value mid-count...", $time);
        m_seq.loading(32'd3);
        m_seq.start_count_i_reload(0);
        
        #60; // Wait for short timer to finish
        m_seq.checking_status(); // Should be expired
        
        m_seq.status_reset();
    endtask

    // -----------------------------------------------------------------
    // Random_RW (Planned Test)
    // Purpose: Constrained-Random coverage closure.
    // -----------------------------------------------------------------
    task automatic Random_RW_Test();
        $display("\n=== STARTING TEST: Random Read/Write Stress ===");
        m_seq.rand_read_write(50); // Run 50 random transactions
    endtask


    // =================================================================
    //  MAIN RUN TASK
    // =================================================================
    task automatic test_run();
        // 1. Initial Reset
        this.reset();
        
        // 2. Start Environment Components (Non-blocking)
        fork
            m_env.run();
        join_none
        
        // 3. Execute Test Plan Sequentially (Blocking)
        begin 
            // Phase 1: Directed Functional Tests
            Test1();
            #500;
            Test2();
            #500;
            Test3();
            #500;
            
            // Phase 2: Corner Cases
            Load_Zero_Test();
            #500;
            Start_Mid_Count_Test();
            #500;
            
            // Phase 3: Random Stress
            Random_RW_Test();
            #500;

            // Phase 4: Coverage Closure (NEW)
            $display("\n=== STARTING TEST: Coverage Closure ===");
            m_seq.coverage_closure_test();
            #500;
        end 
            
        #1000ns;
        $display("\n[TEST] All tests completed. Finishing simulation.");
        $finish;
    endtask 

endclass