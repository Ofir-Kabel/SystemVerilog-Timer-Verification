import design_params_pkg::*;

class Coverage;

  BusTrans tr;

  // --- Covergroup Definition ---
  covergroup trans_cg;
    option.per_instance = 1;  // מאפשר לראות כיסוי פר מופע ב-GUI
    option.comment = "Bus Transaction Coverage";

    // 1. Operation Kind (READ / WRITE)
    kind_cp: coverpoint tr.m_kind {
      bins write = {WRITE}; bins read = {READ};
    }

    // 2. Address Coverage
    addr_cp: coverpoint tr.m_addr {
      bins control_addr = {P_ADDR_CONTROL};
      bins load_addr = {P_ADDR_LOAD};
      bins status_addr = {P_ADDR_STATUS};
      // כיסוי לכתובות חוקיות אחרות בטווח, אך לא הכתובות המיוחדות
      bins other_valid  = {[0:63]} with (!(item inside {P_ADDR_CONTROL, P_ADDR_LOAD, P_ADDR_STATUS}));
      bins out_of_range = {[64 : $]};  // כל מה שמעבר לטווח הזיכרון
    }

    // 3. Data Values Coverage (Low / High ranges)
    data_cp: coverpoint tr.m_data {
      bins low_range = {[0 : 32'h0000_FFFF]}; bins high_range = {[32'h0001_0000 : 32'hFFFF_FFFF]};
    }

    // 4. Reload Enable (Bit 1 in Control Register)
    // שים לב לשימוש ב-iff: נדגום רק אם הכתובת היא CONTROL והפעולה היא כתיבה
    reload_en_cp: coverpoint tr.m_data[1] iff (tr.m_addr == P_ADDR_CONTROL && tr.m_kind == WRITE) {
      bins enabled = {1}; bins disabled = {0};
    }

    // 5. Expired Flag (Bit 0 in Status Register)
    // נדגום רק בקריאה מהסטטוס (כי אז אנחנו רואים אם הדגל דלוק או כבוי)
    expired_cp: coverpoint tr.m_data[0] iff (tr.m_addr == P_ADDR_STATUS && tr.m_kind == READ) {
      bins flag_set = {1}; bins flag_clear = {0};
    }

    // --- Cross Coverage ---

    // האם ביצענו קריאה וכתיבה לכל הכתובות החשוובות?
    kind_addr_cross: cross kind_cp, addr_cp{
      // מתעלמים מכתובות מחוץ לטווח בקרוס הזה
      ignore_bins ignore_invalid = binsof (addr_cp.out_of_range);
    }

    // האם בדקנו מצבי RELOAD (דלוק/כבוי) גם בכתיבה רגילה?
    // (מוודא ששילבנו סוגי טרנזקציות עם מצבי Reload)
    cross_kind_reload: cross kind_cp, reload_en_cp;

  endgroup

  // --- Constructor ---
  function new();
    trans_cg = new();
  endfunction

  // --- Sampling Method ---
  function void sample (input BusTrans i_tr);
    this.tr = i_tr;  // מעדכנים את המשתנה המקומי
    trans_cg.sample();  // דוגמים
  endfunction

endclass  // Coverage
