//-----------------------------------------------------------------------
// FILE: Monitor.sv
//
// DESCRIPTION:
//   Monitor component that observes bus transactions and provides them
//   to scoreboard for checking. Also collects functional coverage.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// CLASS: Monitor
//
// DESCRIPTION:
//   Passively monitors bus interface, captures actual transactions,
//   and sends them to scoreboard. Maintains queue of intended transactions
//   from driver for ID matching.
//-----------------------------------------------------------------------
class Monitor;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local virtual bus_if.monitor_md m_bus_vif;
	local mailbox #(BusTrans) m_mon_sb_mb;
	local Coverage m_mon_cov;
	local BusTrans m_mon_trans_queue[$];
	local BusTrans m_intended_tr;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for Monitor class. Initializes interface, mailbox,
	//   and coverage collector.
	//
	// PARAMETERS:
	//   i_bus_vif - (input) Virtual interface for monitoring
	//   i_mon_sb_mb - (input) Monitor to scoreboard mailbox
	//-----------------------------------------------------------------------
	function new(virtual bus_if.monitor_md i_bus_vif, mailbox#(BusTrans) i_mon_sb_mb);
		this.m_bus_vif = i_bus_vif;
		this.m_mon_sb_mb = i_mon_sb_mb;
		m_mon_cov = new();
	endfunction

	//-----------------------------------------------------------------------
	// TASK: run
	//
	// DESCRIPTION:
	//   Main monitor loop. Observes bus transactions every clock cycle,
	//   captures actual data, and sends to scoreboard with coverage sampling.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic run();
		begin
			$display("[%0t]: Monitor start running...", $time);
			forever
			@(m_bus_vif.monitor_cb)
			begin
				if (m_bus_vif.monitor_cb.req & m_bus_vif.monitor_cb.gnt)
				begin
					// Ensure there is an intended transaction to match
					wait (m_mon_trans_queue.size() > 0);
					m_intended_tr = m_mon_trans_queue.pop_front();
					
					// Create actual transaction based on operation type
					if (m_bus_vif.monitor_cb.write_en)
					begin
						WriteTrans actual_write_tr = new();
						actual_write_tr.m_write_en = 1;
						actual_write_tr.m_addr = m_bus_vif.monitor_cb.addr;
						actual_write_tr.m_data = m_bus_vif.monitor_cb.wdata;
						actual_write_tr.m_unique_id = m_intended_tr.m_unique_id;
						actual_write_tr.display("MON");
						m_mon_sb_mb.put(actual_write_tr);
						m_mon_cov.sample(actual_write_tr);
					end
					else
					begin
						ReadTrans actual_read_tr = new();
						actual_read_tr.m_write_en = 0;
						actual_read_tr.m_addr = m_bus_vif.monitor_cb.addr;
						actual_read_tr.m_data = m_bus_vif.monitor_cb.rdata;
						actual_read_tr.m_unique_id = m_intended_tr.m_unique_id;
						actual_read_tr.display("MON");
						m_mon_sb_mb.put(actual_read_tr);
						m_mon_cov.sample(actual_read_tr);
					end
				end
			end
		end
	endtask

	//-----------------------------------------------------------------------
	// FCN: push_intended
	//
	// DESCRIPTION:
	//   Driver interface to push intended transaction info for ID tracking.
	//
	// PARAMETERS:
	//   i_tr - (input) Intended transaction from driver
	//-----------------------------------------------------------------------
	function void push_intended(input BusTrans i_tr);
		this.m_mon_trans_queue.push_back(i_tr);
	endfunction

endclass
