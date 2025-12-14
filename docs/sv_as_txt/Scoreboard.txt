class Scoreboard;

  mailbox #(BusTrans) ref_sb_mb;
  mailbox #(BusTrans) mon_sb_mb;

  BusTrans ref_expected_tr[int];  // Associative array for expected refs by ID

  // Constructor
  function new(input mailbox #(BusTrans) i_ref_score_mb, input mailbox #(BusTrans) i_mon_score_mb);
    this.ref_sb_mb = i_ref_score_mb;
    this.mon_sb_mb = i_mon_score_mb;
  endfunction  //new()

  // New: Display queue status
  task display_queue(string label);
    $display("[%0t]: Scoreboard Queue Status (%0s) - Size: %0d", $time, label, ref_expected_tr.size());
    foreach (ref_expected_tr[id]) begin
      $display("            ID: %0d | ADDR: %0h | DATA: %0h | KIND: %0s",
               id, ref_expected_tr[id].m_addr, ref_expected_tr[id].m_data, ref_expected_tr[id].m_kind);
    end
  endtask

  task automatic collect_expected();
    forever begin
      BusTrans ref_tr;
      ref_sb_mb.get(ref_tr);  // Wait for transaction from Reference Model
      ref_expected_tr[ref_tr.m_unique_id] = ref_tr;
      ref_expected_tr[ref_tr.m_unique_id].display("SB_REF");  // Debug print
      display_queue("After Add");  // Call after change
    end
  endtask  //collect_expected()

  task automatic match_actual(input BusTrans mon_tr, input BusTrans ref_tr);
    begin
      // Compare transactions
      if (mon_tr.m_unique_id != ref_tr.m_unique_id) begin
        $display("[%0t]: Error[SB]: Transaction ID Mismatch! Ref ID: %0d, Mon ID: %0d",
                 $time, ref_tr.m_unique_id, mon_tr.m_unique_id);
      end else if ((ref_tr.m_addr !== mon_tr.m_addr) ||
                   (ref_tr.m_data !== mon_tr.m_data) ||
                   (ref_tr.m_kind !== mon_tr.m_kind)) begin
        $display("[%0t]: Error[SB] => Scoreboard Mismatch Detected!", $time);
        $display("[%0t]: Reference Transaction - ID:%0d ADDR: %0h, DATA: %0h, KIND: %0s",
                 $time, ref_tr.m_unique_id, ref_tr.m_addr, ref_tr.m_data, ref_tr.m_kind);
        $display("[%0t]: Monitor Transaction - ID:%0d ADDR: %0h, DATA: %0h, KIND: %0s",
                 $time, mon_tr.m_unique_id, mon_tr.m_addr, mon_tr.m_data, mon_tr.m_kind);
      end else begin
        $display("[%0t]: Scoreboard Match: Transactions ID:%0d are consistent.",
                 $time, ref_tr.m_unique_id);
      end
    end
  endtask  //match_actual()

  task automatic run();
    begin
      $display("[%0t]: Scoreboard start running..", $time);
      fork
        collect_expected();
        forever begin
          BusTrans mon_tr;
          mon_sb_mb.get(mon_tr);  // Wait for transaction from Monitor
          if (ref_expected_tr.exists(mon_tr.m_unique_id)) begin
            match_actual(mon_tr, ref_expected_tr[mon_tr.m_unique_id]);
            ref_expected_tr.delete(mon_tr.m_unique_id);  // Free after match
            display_queue("After Delete");  // Call after change
          end
        end
      join
    end
  endtask  //automatic

endclass  //Scoreboard