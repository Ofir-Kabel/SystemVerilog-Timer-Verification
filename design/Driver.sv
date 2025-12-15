//-----------------------------------------------------------------------
// FILE: Driver.sv
//
// DESCRIPTION:
//   Driver component that drives stimulus from sequencer to DUT through
//   the virtual interface. Handles bus protocol and timing.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

//-----------------------------------------------------------------------
// CLASS: Driver
//
// DESCRIPTION:
//   Drives the signals to the DUT through the bus interface. Receives
//   transactions from sequencer mailbox and performs bus protocol.
//-----------------------------------------------------------------------
class Driver;
	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local virtual bus_if.driver_md m_bus_vif;
	local mailbox #(BusTrans) m_seq_drv_mb;
	local BusTrans m_drv_trans;
	local Monitor m_mon;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for Driver class. Initializes interface and mailbox.
	//
	// PARAMETERS:
	//   i_bus_vif - (input) Virtual interface to DUT
	//   i_seq_drv_mb - (input) Sequencer to driver mailbox
	//   i_mon - (input) Monitor reference for intended transaction tracking
	//-----------------------------------------------------------------------
	function new(virtual bus_if.driver_md i_bus_vif, mailbox#(BusTrans) i_seq_drv_mb, Monitor i_mon);
		this.m_bus_vif = i_bus_vif;
		this.m_seq_drv_mb = i_seq_drv_mb;
		this.m_mon = i_mon;
	endfunction

	//-----------------------------------------------------------------------
	// FCN: reset_interface
	//
	// DESCRIPTION:
	//   Resets all driver interface signals to default values.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	function void reset_interface();
		m_bus_vif.driver_cb.write_en <= 0;
		m_bus_vif.driver_cb.req <= 0;
		m_bus_vif.driver_cb.addr <= '0;
		m_bus_vif.driver_cb.wdata <= '0;
	endfunction

	//-----------------------------------------------------------------------
	// TASK: drv_write
	//
	// DESCRIPTION:
	//   Drives a write transaction to the bus. Follows handshake protocol.
	//
	// PARAMETERS:
	//   None (uses m_drv_trans internal transaction)
	//-----------------------------------------------------------------------
	task automatic drv_write();
		begin
			@(m_bus_vif.driver_cb);
			m_bus_vif.driver_cb.write_en <= m_drv_trans.m_write_en;
			m_bus_vif.driver_cb.req <= 1;
			m_bus_vif.driver_cb.addr <= m_drv_trans.m_addr;
			m_bus_vif.driver_cb.wdata <= m_drv_trans.m_data;
			wait (m_bus_vif.driver_cb.gnt);
			m_bus_vif.driver_cb.req <= 0;
			wait (!m_bus_vif.driver_cb.gnt);
			@(m_bus_vif.driver_cb);
		end
	endtask

	//-----------------------------------------------------------------------
	// TASK: drv_read
	//
	// DESCRIPTION:
	//   Drives a read transaction to the bus. Follows handshake protocol
	//   and captures returned data.
	//
	// PARAMETERS:
	//   None (uses m_drv_trans internal transaction)
	//-----------------------------------------------------------------------
	task automatic drv_read();
		begin
			@(m_bus_vif.driver_cb);
			m_bus_vif.driver_cb.write_en <= m_drv_trans.m_write_en;
			m_bus_vif.driver_cb.req <= 1;
			m_bus_vif.driver_cb.addr <= m_drv_trans.m_addr;
			wait (m_bus_vif.driver_cb.gnt);
			m_drv_trans.m_data = m_bus_vif.driver_cb.rdata;
			m_bus_vif.driver_cb.req <= 0;
			wait (!m_bus_vif.driver_cb.gnt);
			@(m_bus_vif.driver_cb);
		end
	endtask

	//-----------------------------------------------------------------------
	// TASK: run
	//
	// DESCRIPTION:
	//   Main driver loop. Gets transactions from mailbox and drives them.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic run();
		begin
			forever
			begin
				m_seq_drv_mb.get(m_drv_trans);
				m_drv_trans.display("DRV");
				m_mon.push_intended(m_drv_trans);
				if (m_drv_trans.m_write_en)
				begin
					drv_write();
				end
				else
				begin
					drv_read();
				end
			end
		end
	endtask

endclass
