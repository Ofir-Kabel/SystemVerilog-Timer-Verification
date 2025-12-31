//-----------------------------------------------------------------------
// FILE: TbEnv.sv
//
// DESCRIPTION:
//   Testbench environment that instantiates and connects all verification
//   components (driver, monitor, scoreboard, reference model).
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// CLASS: TbEnv
//
// DESCRIPTION:
//   Top-level verification environment. Creates and connects all
//   components through mailboxes and virtual interface.
//-----------------------------------------------------------------------
class TbEnv;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local mailbox #(BusTrans) m_seq_drv_mb;
	local mailbox #(BusTrans) m_seq_ref_mb;
	local mailbox #(BusTrans) m_ref_sb_mb;
	local mailbox #(BusTrans) m_mon_sb_mb;
	local Driver m_drv;
	local RefDutTimer m_ref_model;
	local Scoreboard m_sb;
	local Monitor m_mon;
	local virtual bus_if m_vif;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for TbEnv class. Creates all components and mailboxes.
	//
	// PARAMETERS:
	//   i_vif - (input) Virtual interface to DUT
	//-----------------------------------------------------------------------
	function new(input virtual bus_if i_vif);
		m_vif = i_vif;
		m_seq_drv_mb = new(1);
		m_seq_ref_mb = new(1);
		m_ref_sb_mb = new(1);
		m_mon_sb_mb = new(1);

		m_mon = new(m_vif, m_mon_sb_mb);
		m_drv = new(m_vif, m_seq_drv_mb, m_mon);
		m_ref_model = new(m_seq_ref_mb, m_ref_sb_mb, i_vif);
		m_sb = new(m_ref_sb_mb, m_mon_sb_mb);
	endfunction

	//-----------------------------------------------------------------------
	// TASK: reset
	//
	// DESCRIPTION:
	//   Resets all environment components.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic reset();
		begin
			$display("[%0t]: ENV reset", $time);
			m_drv.reset_interface();
			m_ref_model.reset_n();
		end
	endtask

	//-----------------------------------------------------------------------
	// Accessor Methods (Getters)
	//-----------------------------------------------------------------------
	function mailbox #(BusTrans) get_seq_drv_mb();
		return m_seq_drv_mb;
	endfunction

	function mailbox #(BusTrans) get_seq_ref_mb();
		return m_seq_ref_mb;
	endfunction


	//-----------------------------------------------------------------------
	// TASK: run
	//
	// DESCRIPTION:
	//   Starts all environment components in parallel.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic run();
		$display("[%0t]: ENV start running..", $time);
		fork
			m_drv.run();
			m_ref_model.run();
			m_sb.run();
			m_mon.run();
		join
	endtask

endclass
