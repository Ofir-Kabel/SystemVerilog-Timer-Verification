//-----------------------------------------------------------------------
// FILE: Coverage.sv
//
// DESCRIPTION:
//   Functional coverage collector for bus transactions. Tracks operation
//   types, addresses, data values, and control bits.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: Coverage
//
// DESCRIPTION:
//   Collects functional coverage on bus transactions including address,
//   data, operation kind, and control register fields.
//-----------------------------------------------------------------------
class Coverage;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local BusTrans m_tr;

	//-----------------------------------------------------------------------
	// Covergroup Definition
	//-----------------------------------------------------------------------
	covergroup trans_cg;
		option.per_instance = 1;
		option.comment = "Bus Transaction Coverage";

		// Operation Kind (READ / WRITE)
		kind_cp: coverpoint m_tr.m_kind {
			bins write = {WRITE};
			bins read = {READ};
		}

		// Address Coverage
		addr_cp: coverpoint m_tr.m_addr {
			bins control_addr = {P_ADDR_CONTROL};
			bins load_addr = {P_ADDR_LOAD};
			bins status_addr = {P_ADDR_STATUS};
			bins other_valid = {[0:63]} with (!(item inside {P_ADDR_CONTROL, P_ADDR_LOAD, P_ADDR_STATUS}));
			bins out_of_range = {[64 : $]};
		}

		// Data Values Coverage (Low / High ranges)
		data_cp: coverpoint m_tr.m_data {
			bins low_range = {[0 : 32'h0000_FFFF]};
			bins high_range = {[32'h0001_0000 : 32'hFFFF_FFFF]};
		}

		// Reload Enable (Bit 1 in Control Register)
		reload_en_cp: coverpoint m_tr.m_data[1] iff (m_tr.m_addr == P_ADDR_CONTROL && m_tr.m_kind == WRITE) {
			bins enabled = {1};
			bins disabled = {0};
		}

		// Expired Flag (Bit 0 in Status Register)
		expired_cp: coverpoint m_tr.m_data[0] iff (m_tr.m_addr == P_ADDR_STATUS && m_tr.m_kind == READ) {
			bins flag_set = {1};
			bins flag_clear = {0};
		}

		// Cross Coverage: Operation kind with addresses
		kind_addr_cross: cross kind_cp, addr_cp {
			ignore_bins ignore_invalid = binsof (addr_cp.out_of_range);
		}

		// Cross Coverage: Operation kind with reload enable
		cross_kind_reload: cross kind_cp, reload_en_cp;

	endgroup

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for Coverage class. Instantiates covergroup.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function new();
		trans_cg = new();
	endfunction

	//-----------------------------------------------------------------------
	// FCN: sample
	//
	// DESCRIPTION:
	//   Samples coverage from a bus transaction.
	//
	// PARAMETERS:
	//   i_tr - (input) Transaction to sample for coverage
	//-----------------------------------------------------------------------
	function void sample(input BusTrans i_tr);
		this.m_tr = i_tr;
		trans_cg.sample();
	endfunction

endclass
