//-----------------------------------------------------------------------
// FILE: RefDutTimer.sv
//
// DESCRIPTION:
//   Reference model for timer peripheral. Implements expected behavior
//   for comparison with DUT outputs.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

import design_params_pkg::*;

//-----------------------------------------------------------------------
// CLASS: RefDutTimer
//
// DESCRIPTION:
//   Golden reference model that mimics timer peripheral behavior.
//   Processes read/write transactions and generates expected responses.
//-----------------------------------------------------------------------
class RefDutTimer;

	//-----------------------------------------------------------------------
	// Properties (Class Members)
	//-----------------------------------------------------------------------
	local BusTrans m_sb_tr;
	local mailbox #(BusTrans) m_seq_ref_mb;
	local mailbox #(BusTrans) m_ref_sb_mb;
	local virtual bus_if m_vif;

	//-----------------------------------------------------------------------
	// Parameters
	//-----------------------------------------------------------------------
	localparam time CLK_PERIOD = 10ns;

	//-----------------------------------------------------------------------
	// Internal Registers
	//-----------------------------------------------------------------------
	local logic [P_DATA_WIDTH-1:0] m_control;
	local logic [P_DATA_WIDTH-1:0] m_load;
	local logic [P_DATA_WIDTH-1:0] m_status;

	//-----------------------------------------------------------------------
	// Timer Logic Variables
	//-----------------------------------------------------------------------
	local bit m_timer_active;
	local logic [15:0] m_count_cycles;
	local time m_delay_ns;

	//-----------------------------------------------------------------------
	// FCN: new
	//
	// DESCRIPTION:
	//   Constructor for RefDutTimer class.
	//
	// PARAMETERS:
	//   i_seq_ref_mb - (input) Sequencer to reference mailbox
	//   i_ref_sb_mb - (input) Reference to scoreboard mailbox
	//   i_vif - (input) Virtual interface for clock synchronization
	//-----------------------------------------------------------------------
	function new(input mailbox #(BusTrans) i_seq_ref_mb, input mailbox #(BusTrans) i_ref_sb_mb, input virtual bus_if i_vif);
		this.m_seq_ref_mb = i_seq_ref_mb;
		this.m_ref_sb_mb = i_ref_sb_mb;
		this.m_vif = i_vif;
		this.m_timer_active = 0;
		this.m_control = 0;
		this.m_load = 0;
		this.m_status = 0;
	endfunction

	//-----------------------------------------------------------------------
	// TASK: reset_n
	//
	// DESCRIPTION:
	//   Resets all internal registers and timer state.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task reset_n();
		m_control = '0;
		m_load = '0;
		m_status = '0;
		m_count_cycles = '0;
		m_timer_active = 0;
	endtask

    // // --- Countdown Logic ---
    // task automatic counting_down();
    //     if(load == 0) count_cycles = 16'd1; 
    //     else count_cycles = load[15:0];
            
    //     delay_ns = count_cycles * CLK_PERIOD; 
        
    //     do begin
    //         #(delay_ns); 
    //         if (timer_active) begin
    //             status[0] = 1; // Set Expired Bit
    //         end
    //     end while (control[1] && timer_active); 
    // endtask

	//-----------------------------------------------------------------------
	// TASK: counting_down
	//
	// DESCRIPTION:
	//   Implements countdown timer logic with auto-reload support.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic counting_down();
		do
		begin
			m_count_cycles = (m_load == 0) ? 16'd1 : m_load[15:0];
			repeat(m_count_cycles) @(posedge m_vif.clk);
			if (m_timer_active) m_status = 1;
		end
		while (m_control[P_BIT_RELOAD_EN] && m_timer_active);
	endtask


	//-----------------------------------------------------------------------
	// TASK: write_ref
	//
	// DESCRIPTION:
	//   Processes write transactions to timer registers.
	//
	// PARAMETERS:
	//   i_addr - (input) Register address
	//   i_data - (input) Data to write
	//-----------------------------------------------------------------------
	task automatic write_ref(input [P_ADDR_WIDTH-1:0] i_addr, input [P_DATA_WIDTH-1:0] i_data);
		m_sb_tr.m_addr = i_addr;
		m_sb_tr.m_data = i_data;
		m_sb_tr.m_write_en = 1;

		case (i_addr)
			P_ADDR_CONTROL:
			begin
				logic [P_DATA_WIDTH-1:0] masked_data;
				masked_data = i_data & 32'h0000_0007;
				
				if (masked_data[0])
				begin
					m_timer_active = 0;
					fork
						begin
							m_timer_active = 1;
							counting_down();
							m_timer_active = 0;
						end
					join_none
				end
				else
				begin
					m_timer_active = 0;
				end

				if (masked_data[2])
				begin
					m_status = 0;
				end
				
				m_control = masked_data;
			end

			P_ADDR_LOAD:
			begin
				m_load = i_data & 32'h0000_FFFF;
			end

			P_ADDR_STATUS:
			begin
				if (i_data[0]) m_status[0] = 0;
			end
			
			default:
			begin
			end
		endcase
	endtask

	//-----------------------------------------------------------------------
	// TASK: read_ref
	//
	// DESCRIPTION:
	//   Processes read transactions from timer registers.
	//
	// PARAMETERS:
	//   i_addr - (input) Register address to read
	//-----------------------------------------------------------------------
	task automatic read_ref(input [P_ADDR_WIDTH-1:0] i_addr);
		m_sb_tr.m_addr = i_addr;
		m_sb_tr.m_write_en = 0;

		case(i_addr)
			P_ADDR_CONTROL: m_sb_tr.m_data = m_control;
			P_ADDR_LOAD: m_sb_tr.m_data = m_load;
			P_ADDR_STATUS:
			begin
				m_sb_tr.m_data = m_status;
				m_status = 0;
			end
			default: m_sb_tr.m_data = 32'h0;
		endcase
	endtask

	//-----------------------------------------------------------------------
	// TASK: run
	//
	// DESCRIPTION:
	//   Main reference model loop. Processes transactions and generates
	//   expected responses.
	//
	// PARAMETERS:
	//   None
	//-----------------------------------------------------------------------
	task automatic run();
		forever
		begin
			BusTrans seq_tr;
			m_seq_ref_mb.get(seq_tr);
			
			m_sb_tr = new();
			m_sb_tr.m_unique_id = seq_tr.m_unique_id;
			m_sb_tr.m_kind = seq_tr.m_kind;

			if(seq_tr.m_write_en)
			begin
				write_ref(seq_tr.m_addr, seq_tr.m_data);
			end
			else
			begin
				read_ref(seq_tr.m_addr);
			end

			m_ref_sb_mb.put(m_sb_tr);
			m_sb_tr.display("REF_EXPECTED");
		end
	endtask

endclass
