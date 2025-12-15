class Monitor;

  //properties
  virtual bus_if.monitor_md bus_vif;
  mailbox #(BusTrans) mon_sb_mb;
  Coverage mon_cov;
  BusTrans mon_trans_queue[$];
  BusTrans intended_tr;

  //constructor
  function new(virtual bus_if.monitor_md tb_bus_vif, mailbox#(BusTrans) tb_mon_sb_mb);
    this.bus_vif = tb_bus_vif;
    this.mon_sb_mb = tb_mon_sb_mb;
    mon_cov = new();
  endfunction

  //this automatic task running non stop and will display every clk cycle the bus status is this good?
  task automatic run();
    begin
      $display("[%0t]: Monitor start running...", $time);
      forever
      @(bus_vif.monitor_cb) begin
        if (bus_vif.monitor_cb.req & bus_vif.monitor_cb.gnt) begin
          wait (mon_trans_queue.size() > 0);  // Ensure there is an intended transaction to match
          intended_tr = mon_trans_queue.pop_front();  // to hold the intended transaction ID
          // Create actual transaction based on the type of operation
          if (bus_vif.monitor_cb.write_en) begin
            WriteTrans actual_write_tr = new();
            actual_write_tr.m_write_en = 1;
            actual_write_tr.m_addr = bus_vif.monitor_cb.addr;
            actual_write_tr.m_data = bus_vif.monitor_cb.wdata;
            actual_write_tr.m_unique_id = intended_tr.m_unique_id; // assign the intended ID to the actual transaction
            actual_write_tr.display("MON");
            mon_sb_mb.put(actual_write_tr);
            mon_cov.sample(actual_write_tr);
            // $display("[%0t]: Monitor observed DUT output write: ID:%0d  ADDR=0x%0h DATA=0x%0h",
            //          $time, actual_write_tr.m_unique_id, bus_vif.monitor_cb.addr,
            //          bus_vif.monitor_cb.wdata);
          end else begin
            ReadTrans actual_read_tr = new();
            actual_read_tr.m_write_en = 0;
            actual_read_tr.m_addr = bus_vif.monitor_cb.addr;
            actual_read_tr.m_data = bus_vif.monitor_cb.rdata;
            actual_read_tr.m_unique_id = intended_tr.m_unique_id; // assign the intended ID to the actual transaction
            actual_read_tr.display("MON");
            mon_sb_mb.put(actual_read_tr);

            mon_cov.sample(actual_read_tr);
            // $display("[%0t]: Monitor observed DUT output read: ID:%0d  ADDR=0x%0h DATA=0x%0h",
            //          $time, actual_read_tr.m_unique_id, bus_vif.monitor_cb.addr,
            //          bus_vif.monitor_cb.rdata);
          end
        end
      end
    end
  endtask

  //DRIVER INTERFACE TO PUSH INTENDED TRANSACTION INFO
  function void push_intended(input BusTrans tr);
    // Add the intended transaction (which holds the ID) to the back of the queue
    this.mon_trans_queue.push_back(tr);

  endfunction

endclass  //monitor
