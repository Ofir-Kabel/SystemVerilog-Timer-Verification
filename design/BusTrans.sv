//-----------------------------------------------------------------------
// FILE: BusTrans.sv
//
// DESCRIPTION:
//   Base transaction class for bus operations. Supports both read and write
//   transactions with unique ID tracking for scoreboard matching.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: BusTrans
//
// DESCRIPTION:
//   Base transaction class containing address, data, and control fields.
//   Each transaction has a unique ID for tracking through the verification
//   environment. Derived classes (WriteTrans, ReadTrans) specialize behavior.
//-----------------------------------------------------------------------
class BusTrans;

	//-----------------------------------------------------------------------
	// Parameters
	//-----------------------------------------------------------------------
	parameter int ADDR_WIDTH = 8;
	parameter int DATA_WIDTH = 32;
	typedef enum logic {WRITE, READ} kind_s;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	rand logic m_write_en;
	rand logic [ADDR_WIDTH-1:0] m_addr;
	rand logic [DATA_WIDTH-1:0] m_data;
	rand kind_s m_kind;
	int m_unique_id;
	static int m_counter_id;

	//-----------------------------------------------------------------------
	// Constraints
	//-----------------------------------------------------------------------
	// constraint addr_c { m_addr inside {P_ADDR_CONTROL,P_ADDR_LOAD,P_ADDR_STATUS}; }
	// constraint data_c { m_data inside {[0:255]}; }
	// constraint reserved_ctrl_c { if (m_addr == P_ADDR_CONTROL) m_data[31:3] == 0; }
	// constraint reserved_load_c { if (m_addr == P_ADDR_LOAD) m_data[31:16] == 0; }
	// constraint reserved_status_c { if (m_addr == P_ADDR_STATUS) m_data[31:1] == 0; }

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for BusTrans. Assigns unique ID from static counter.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function new();
		m_unique_id = this.m_counter_id;
	endfunction

	//-----------------------------------------------------------------------
	// FCN: display
	//
	// DESCRIPTION:
	//   Displays transaction information for debugging.
	//
	// PARAMETERS:
	//   i_name - (input) Component name for identification
	//-----------------------------------------------------------------------
	virtual function void display(string i_name);
		$display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h  WR_EN:%0d", $time, i_name, m_kind,
		         m_unique_id, m_addr, m_data, m_write_en);
	endfunction

	//-----------------------------------------------------------------------
	// FCN: ID_increment
	//
	// DESCRIPTION:
	//   Increments the static transaction ID counter.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function void ID_increment();
		m_counter_id = m_counter_id + 1;
		$display("[%0t]: ID counter:%0d", $time, m_unique_id);
	endfunction

endclass





