//-----------------------------------------------------------------------
// FILE: WriteTrans.sv
//
// DESCRIPTION:
//   Write transaction class derived from BusTrans. Specialized for write
//   operations on the bus.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// CLASS: WriteTrans
//
// DESCRIPTION:
//   Extends BusTrans for write-specific transactions. Automatically sets
//   write_en to 1 and kind to WRITE.
//-----------------------------------------------------------------------
class WriteTrans extends BusTrans;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for WriteTrans. Calls parent constructor and sets
	//   write-specific fields.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function new();
		super.new();
		m_kind = WRITE;
		m_write_en = 1;
	endfunction

	//-----------------------------------------------------------------------
	// FCN: display
	//
	// DESCRIPTION:
	//   Displays write transaction information for debugging.
	//
	// PARAMETERS:
	//   i_name - (input) Component name for identification
	//-----------------------------------------------------------------------
	virtual function void display(string i_name);
		$display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h  WR_EN:%0d", $time, i_name, m_kind,
		         m_unique_id, m_addr, m_data, m_write_en);
	endfunction

endclass

