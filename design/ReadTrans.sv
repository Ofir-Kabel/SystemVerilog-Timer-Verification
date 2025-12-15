//-----------------------------------------------------------------------
// FILE: ReadTrans.sv
//
// DESCRIPTION:
//   Read transaction class derived from BusTrans. Specialized for read
//   operations on the bus.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// CLASS: ReadTrans
//
// DESCRIPTION:
//   Extends BusTrans for read-specific transactions. Automatically sets
//   write_en to 0 and kind to READ.
//-----------------------------------------------------------------------
class ReadTrans extends BusTrans;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for ReadTrans. Calls parent constructor and sets
	//   read-specific fields.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function new();
		super.new();
		m_kind = READ;
		m_write_en = 0;
	endfunction

	//-----------------------------------------------------------------------
	// FCN: display
	//
	// DESCRIPTION:
	//   Displays read transaction information for debugging.
	//
	// PARAMETERS:
	//   i_name - (input) Component name for identification
	//-----------------------------------------------------------------------
	virtual function void display(string i_name);
		$display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h  WR_EN:%0d", $time, i_name, m_kind,
		         m_unique_id, m_addr, m_data, m_write_en);
	endfunction

endclass
