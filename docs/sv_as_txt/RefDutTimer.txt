import design_params_pkg::*;

class RefDutTimer;

    // --- Properties ---
    BusTrans sb_tr;
    mailbox #(BusTrans) seq_ref_mb;
    mailbox #(BusTrans) ref_sb_mb;
    virtual bus_if vif;

    // --- Parameters ---
    localparam time CLK_PERIOD = 10ns;

    // --- Internal Registers ---
    logic [P_DATA_WIDTH-1:0] control;
    logic [P_DATA_WIDTH-1:0] load;
    logic [P_DATA_WIDTH-1:0] status;

    // --- Timer Logic Variables ---
    bit timer_active;       
    logic [15:0] count_cycles;
    time delay_ns;

    // --- Constructor ---
    function new(input mailbox #(BusTrans) i_seq_ref_mb, input mailbox #(BusTrans) i_ref_sb_mb ,input virtual bus_if i_vif);
        this.seq_ref_mb = i_seq_ref_mb;
        this.ref_sb_mb = i_ref_sb_mb;
        this.vif = i_vif;
        this.timer_active = 0;
        this.control = 0;
        this.load = 0;
        this.status = 0;
    endfunction 

    // --- Reset Task ---
    task reset_n();
        control = '0;
        load    = '0;
        status  = '0;
        count_cycles = '0;       
        timer_active = 0; 
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

task automatic counting_down();
        do begin
            count_cycles = (load == 0) ? 16'd1 : load[15:0];
            repeat(count_cycles) @(posedge vif.clk); // Clk sync
            if (timer_active) status = 1; // Set sticky
        end while (control[P_BIT_RELOAD_EN] && timer_active); // Reload loop, keep status
    endtask


    // --- Write Logic (Definition: 2 arguments) ---
    task automatic write_ref(input [P_ADDR_WIDTH-1:0] i_addr, input [P_DATA_WIDTH-1:0] i_data);
        sb_tr.m_addr = i_addr;
        sb_tr.m_data = i_data;
        sb_tr.m_write_en = 1;

        case (i_addr)
            P_ADDR_CONTROL: begin // 0x00
                logic [P_DATA_WIDTH-1:0] masked_data;
                // Masking: Only bits [2:0] are writable
                masked_data = i_data & 32'h0000_0007; 
                
                // 1. Enable/Start Timer
                if (masked_data[0]) begin 
                    timer_active = 0; 
                    fork 
                        begin
                            timer_active = 1;
                            counting_down();
                            timer_active = 0; 
                        end
                    join_none
                end else begin
                    timer_active = 0; 
                end

                // 2. Clear Status via Control
                if (masked_data[2]) begin
                     status = 0; 
                end
                
                control = masked_data;
            end

            P_ADDR_LOAD: begin // 0x04
                // Masking: Only bits [15:0] are writable
                load = i_data & 32'h0000_FFFF;
            end

            P_ADDR_STATUS: begin // 0x08
                // W1C support if needed
                if (i_data[0]) status[0] = 0;
            end
            
            default: begin
               // Writes to invalid addresses are ignored
            end
        endcase
    endtask

    // --- Read Logic (Definition: 1 argument) ---
    task automatic read_ref(input [P_ADDR_WIDTH-1:0] i_addr);
        sb_tr.m_addr = i_addr;
        sb_tr.m_write_en = 0;

        case(i_addr)
            P_ADDR_CONTROL: sb_tr.m_data = control;
            P_ADDR_LOAD:    sb_tr.m_data = load;
            P_ADDR_STATUS: begin
                sb_tr.m_data = status;
                status = 0; // Clear on Read (R5)
            end
            default: sb_tr.m_data = 32'h0; 
        endcase
    endtask

    // --- Main Run Task ---
    task automatic run();
        forever begin
            BusTrans seq_tr;
            seq_ref_mb.get(seq_tr);
            
            sb_tr = new();
            sb_tr.m_unique_id = seq_tr.m_unique_id; 
            sb_tr.m_kind      = seq_tr.m_kind;

            if(seq_tr.m_write_en) begin
                // קריאה עם 2 ארגומנטים (תואם להגדרה למעלה)
                write_ref(seq_tr.m_addr, seq_tr.m_data);
            end else begin
                // קריאה עם ארגומנט 1 (תואם להגדרה למעלה)
                read_ref(seq_tr.m_addr);
            end

            ref_sb_mb.put(sb_tr);
            sb_tr.display("REF_EXPECTED");
        end
    endtask 

endclass