//-----------------------------------------------------------------------
// FILE: Scoreboard.sv
//
// DESCRIPTION:
//   Scoreboard component that compares expected transactions from reference
//   model with actual transactions from monitor.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: Scoreboard
//
// DESCRIPTION:
//   Receives expected transactions from reference model and actual
//   transactions from monitor. Compares them and reports matches/mismatches.
//-----------------------------------------------------------------------
class Scoreboard;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local mailbox #(BusTrans) m_ref_sb_mb;
	local mailbox #(BusTrans) m_mon_sb_mb;
	local BusTrans m_ref_expected_tr[int];

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for Scoreboard class.
	//
	// PARAMETERS:
	//   i_ref_score_mb - (input) Reference model to scoreboard mailbox
	//   i_mon_score_mb - (input) Monitor to scoreboard mailbox
	//-----------------------------------------------------------------------
	function new(input mailbox #(BusTrans) i_ref_score_mb, input mailbox #(BusTrans) i_mon_score_mb);
		this.m_ref_sb_mb = i_ref_score_mb;
		this.m_mon_sb_mb = i_mon_score_mb;
	endfunction

	//-----------------------------------------------------------------------
	// TASK: display_queue
	//
	// DESCRIPTION:
	//   Displays current scoreboard queue status for debugging.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task display_queue();
		$display("[%0t]: ---- Scoreboard Queue Status ----\n[%0t]: Size: %0d", $time, $time, m_ref_expected_tr.size());
		foreach (m_ref_expected_tr[id])
		begin
			m_ref_expected_tr[id].display("QUEUE");
		end
	endtask


	//-----------------------------------------------------------------------
	// TASK: collect_expected
	//
	// DESCRIPTION:
	//   Collects expected transactions from reference model.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic collect_expected();
		forever
		begin
			BusTrans ref_tr;
			m_ref_sb_mb.get(ref_tr);
			m_ref_expected_tr[ref_tr.m_unique_id] = ref_tr;
		end
	endtask

	//-----------------------------------------------------------------------
	// TASK: match_actual
	//
	// DESCRIPTION:
	//   Compares actual monitored transaction with expected transaction.
	//
	// PARAMETERS:
	//   i_mon_tr - (input) Actual transaction from monitor
	//   i_ref_tr - (input) Expected transaction from reference model
	//-----------------------------------------------------------------------
	task automatic match_actual(input BusTrans i_mon_tr, input BusTrans i_ref_tr);
		bit match;
		
		match = 1;
		if (i_ref_tr.m_addr !== i_mon_tr.m_addr) match = 0;
		if (i_ref_tr.m_data !== i_mon_tr.m_data) match = 0;
		if (i_ref_tr.m_kind !== i_mon_tr.m_kind) match = 0;
		
		$display("[%0t]: ---- Scoreboard MATCH Status ----", $time);
		if (match)
		begin
			$display("[%0t]: [SB]  MATCH! ID:%0d", $time, i_mon_tr.m_unique_id);
			i_ref_tr.display("SB(REF)");
			i_mon_tr.display("SB(MON)");
		end
		else
		begin
			$display("[%0t]: [SB]  MISMATCH! ID:%0d", $time, i_mon_tr.m_unique_id);
			i_ref_tr.display("SB(REF)");
			i_mon_tr.display("SB(MON)");
		end
	endtask

	//-----------------------------------------------------------------------
	// TASK: run
	//
	// DESCRIPTION:
	//   Main scoreboard loop. Forks collection and comparison tasks.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic run();
		$display("[%0t]: [SB] Scoreboard Started.", $time);
		
		fork
			collect_expected();

			forever
			begin
				BusTrans mon_tr;
				m_mon_sb_mb.get(mon_tr);
				display_queue();
				
				if (m_ref_expected_tr.exists(mon_tr.m_unique_id))
				begin
					match_actual(mon_tr, m_ref_expected_tr[mon_tr.m_unique_id]);
					m_ref_expected_tr.delete(mon_tr.m_unique_id);
				end
				else
				begin
					$display("[%0t]: [SB]  ERROR: Unexpected Transaction from Monitor!", $time);
					mon_tr.display("SB(MON)");
				end
			end
		join
	endtask

endclass
