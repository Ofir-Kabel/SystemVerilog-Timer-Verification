class RefDutTimer;

    //transaction properties
    BusTrans sb_tr;
    mailbox #(BusTrans) seq_ref_mb;
    mailbox #(BusTrans) ref_sb_mb;

    //parameters
    localparam time CLK_PERIOD = 10ns;

    //internal registers
    logic [P_DATA_WIDTH-1:0] control;
    logic [P_DATA_WIDTH-1:0] load;
    logic [P_DATA_WIDTH-1:0] status;

    //countdown variables
    bit timer_active; // Flag to control active timer (for cancellation)
    logic [15:0] count_cycles;
    time delay_ns;

    //constructor
    function new(input mailbox #(BusTrans) i_seq_ref_mb, input mailbox #(BusTrans) i_ref_sb_mb);
        this.seq_ref_mb = i_seq_ref_mb;
        this.ref_sb_mb = i_ref_sb_mb;
        timer_active = 0; // Initialize flag
    endfunction //new()

// class RefDutTimer;
//     // ... 
//     virtual bus_if vif;  // Add this
//     function new(..., virtual bus_if i_vif);
//         this.vif = i_vif;
//         // ...
//     endfunction

//     task automatic counting_down();
//         forever begin  // For reload
//             repeat(count_cycles) @(posedge vif.clk);
//             if (timer_active) status = 1;
//             if (!control[P_BIT_RELOAD_EN]) break;
//             count_cycles = load[15:0] ? load[15:0] : 1;  // Reload
//         end
//     endtask


    //reset function
    task reset_n(input int clk_cycles);
        begin
            control = '0;
            load    = '0;
            status  = '0;
            count_cycles = '0;       
            timer_active = 0; // Cancel any active timer
            repeat(clk_cycles) #CLK_PERIOD; //clk period
        end
    endtask//reset()

    task automatic write_ref(input [P_ADDR_WIDTH-1:0] i_addr,input [P_DATA_WIDTH-1:0] i_data, input bit i_write_en); 
    begin
        sb_tr.m_addr = i_addr;
        sb_tr.m_data = i_data;
        sb_tr.m_write_en = i_write_en;
        if(i_write_en) begin
            if( (i_addr == P_ADDR_CONTROL))begin
            //start counting & self clearing
                if (i_data[P_BIT_START]) begin
                    timer_active = 0; // Cancel any previous timer
                    fork
                        begin
                            timer_active = 1;
                            counting_down();
                            timer_active = 0;
                        end
                    join_none
                end
                //clear status bit & self clearing
                if (i_data[P_BIT_CLR_STATUS]) begin
                    status = 0; 
                end
                //enable auto-reload
                control[P_BIT_RELOAD_EN] = i_data[P_BIT_RELOAD_EN];

            end else if (i_addr == P_ADDR_LOAD)
                load = {16'h00,i_data[15:0]};
        end
    end
    endtask

    //reading reference model
    task automatic read_ref(input [P_ADDR_WIDTH-1:0] i_addr, input bit i_write_en);
    begin
        sb_tr.m_write_en = i_write_en;
        sb_tr.m_addr = i_addr;
        if(!i_write_en)begin
            sb_tr.m_addr = i_addr;
            case(i_addr)
                P_ADDR_CONTROL:begin
                    sb_tr.m_data = control;
                end 
                P_ADDR_LOAD: sb_tr.m_data = load;
                P_ADDR_STATUS:begin
                    sb_tr.m_data = status;
                    status = 0; //clear status after read;
                end 
                default: ;      //do nothing     
            endcase
        end else
            $display("[%0t]: Error[REF] => read_ref called with write_en high",$time);
    end
    endtask

    task automatic counting_down();
        do begin
            if(load == 0) count_cycles = 16'd1; // Set status immediately if load is zero
            else count_cycles = load[15:0];
            delay_ns = count_cycles * CLK_PERIOD;  
            #(delay_ns); 
            if (timer_active) status = 1;
        end while (control[P_BIT_RELOAD_EN] && timer_active); 
    endtask

    // task automatic run();
    //     $display("[%0t]: RefModel start running..",$time);
    //     forever begin
    //         BusTrans seq_tr;
    //         seq_ref_mb.get(seq_tr); // Waits for a transaction from the Monitor

    //         sb_tr.m_unique_id = seq_tr.m_unique_id;  // Add: Copy ID
    //         sb_tr.m_kind = seq_tr.m_kind;  // Add: Copy kind (though may need explicit set below)

    //         if(seq_tr.m_write_en) begin
    //             write_ref(seq_tr.m_addr, seq_tr.m_data, seq_tr.m_write_en);
    //         end else begin
    //             read_ref(seq_tr.m_addr, seq_tr.m_write_en);
    //         end
    //         ref_sb_mb.put(sb_tr); // Sends the processed transaction to the Scoreboard
    //         sb_tr.display("REF");
    //         $monitor("[%0t]: [REF] status = %0b",$time,status);
    //     end
    // endtask //run()

        task automatic run();
        $display("[%0t]: RefModel start running..",$time);
        forever begin
            BusTrans seq_tr;
            seq_ref_mb.get(seq_tr); // Waits for a transaction from the Monitor
            sb_tr = new();
            sb_tr.m_unique_id = seq_tr.m_unique_id;  // Add: Copy ID
            sb_tr.m_kind = seq_tr.m_kind;  // Add: Copy kind (though may need explicit set below)

            if(seq_tr.m_write_en) begin
                write_ref(seq_tr.m_addr, seq_tr.m_data, seq_tr.m_write_en);
            end else begin
                read_ref(seq_tr.m_addr, seq_tr.m_write_en);
            end
            ref_sb_mb.put(sb_tr); // Sends the processed transaction to the Scoreboard
            sb_tr.display("REF");
        end
    endtask //run()


endclass //RefDutTimer