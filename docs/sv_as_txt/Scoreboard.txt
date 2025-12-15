import design_params_pkg::*;

class Scoreboard;

  mailbox #(BusTrans) ref_sb_mb;
  mailbox #(BusTrans) mon_sb_mb;

  // המאגר של הטרנזקציות הצפויות (ממתינות לבוא המוניטור)
  BusTrans ref_expected_tr[int]; 

  function new(input mailbox #(BusTrans) i_ref_score_mb, input mailbox #(BusTrans) i_mon_score_mb);
    this.ref_sb_mb = i_ref_score_mb;
    this.mon_sb_mb = i_mon_score_mb;
  endfunction 

  // New: Display queue status
  task display_queue();
    $display("[%0t]: ---- Scoreboard Queue Status ----\n[%0t]: Size: %0d", $time,$time, ref_expected_tr.size());
    foreach (ref_expected_tr[id]) begin
      ref_expected_tr[id].display("QUEUE");
    end
  endtask


  // --- Collector Task (From Reference Model) ---
  task automatic collect_expected();
    forever begin
      BusTrans ref_tr;
      ref_sb_mb.get(ref_tr);
      
      // שמירה במערך האסוציאטיבי לפי ID
      ref_expected_tr[ref_tr.m_unique_id] = ref_tr;
      //$display("[%0t] [SB] Added Expected Trans ID: %0d", $time, ref_tr.m_unique_id);
    end
  endtask 

  // --- Compare Logic ---
  task automatic match_actual(input BusTrans mon_tr, input BusTrans ref_tr);
      bit match = 1;
      
      // השוואת שדות
      if (ref_tr.m_addr !== mon_tr.m_addr) match = 0;
      if (ref_tr.m_data !== mon_tr.m_data) match = 0;
      if (ref_tr.m_kind !== mon_tr.m_kind) match = 0;
      $display("[%0t]: ---- Scoreboard MATCH Status ----",$time);
      if (match) begin
                 $display("[%0t]: [SB]  MATCH! ID:%0d", $time, mon_tr.m_unique_id);
                ref_tr.display("SB(REF)");
                mon_tr.display("SB(MON)"); 
      end else begin
          $display("[%0t]: [SB]  MISMATCH! ID:%0d", $time, mon_tr.m_unique_id);
                ref_tr.display("SB(REF)");
                mon_tr.display("SB(MON)"); 
      end
  endtask 

  // --- Main Run Task ---
  task automatic run();
    $display("[%0t]: [SB] Scoreboard Started.", $time);
    
    fork
        // תהליך 1: איסוף ציפיות מהמודל
        collect_expected();

        // תהליך 2: בדיקת דיווחים מהשטח (מוניטור)
        forever begin
            BusTrans mon_tr;
            mon_sb_mb.get(mon_tr); // מחכים לדיווח מהמוניטור
            display_queue();
            // האם הטרנזקציה הזו צפויה? (האם המודל חזה אותה?)
            if (ref_expected_tr.exists(mon_tr.m_unique_id)) begin
                match_actual(mon_tr, ref_expected_tr[mon_tr.m_unique_id]);
                
                // מחיקה מהתור כי סיימנו איתה
                ref_expected_tr.delete(mon_tr.m_unique_id);
            end 
            else begin
                $display("[%0t]: [SB]  ERROR: Unexpected Transaction from Monitor!", $time);
                mon_tr.display("SB(MON)");
            end
        end
    join
  endtask 

endclass