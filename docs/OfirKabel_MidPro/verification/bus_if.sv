//-----------------------------------------------------------------------
// FILE: bus_if.sv
//
// DESCRIPTION:
//   Bus interface with clocking blocks for driver and monitor.
//   Includes SystemVerilog Assertions for protocol checking.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

`timescale 1ns/1ns

import design_params_pkg::*;

interface bus_if(
    input logic clk,
    input logic rst_n
);

    // --- Interface Signals ---
    logic req;
    logic gnt;
    logic [P_ADDR_WIDTH-1:0] addr;
    logic [P_DATA_WIDTH-1:0] wdata;
    logic [P_DATA_WIDTH-1:0] rdata;
    logic write_en;

    // --- Clocking Blocks ---
    
    // For Driver (Outputs driven, Inputs sampled)
    clocking driver_cb @(posedge clk);
        default input #1step output #2ns;
        input  gnt;
        output req;
        output addr;
        output wdata;
        input  rdata;
        output write_en;
    endclocking

    // For Monitor (Passive sampling)
    clocking monitor_cb @(posedge clk);
        default input #1step output #2ns;
        input gnt;
        input req;
        input addr;
        input wdata;
        input rdata;
        input write_en;
    endclocking

    // --- Modports ---
    modport driver_md (clocking driver_cb);
    modport monitor_md(clocking monitor_cb);
    
    modport slave_md(
        input  req, addr, wdata, write_en,
        output gnt, rdata
    );

    // =========================================================
    // SVA - ASSERTIONS & PROPERTIES
    // =========================================================
    
    // הגדרה גלובלית: כל האסרשנים מבוטלים בזמן Reset
    default disable iff (!rst_n);

    // ------------------------------------------
    // 1. Liveness: Response Time
    // ה-GNT חייב להגיע תוך 3 מחזורים מרגע ה-REQ
    // ------------------------------------------
    property req_before_gnt_p;
        @(posedge clk) req |-> ##[0:3] gnt;
    endproperty

    ASSERT_REQ_TIMEOUT: assert property(req_before_gnt_p)
        else $error("[SVA] Timeout: GNT did not assert within 3 cycles of REQ!");

    // ------------------------------------------
    // 2. Handshake Completion
    // כאשר יש REQ וגם GNT (סיום טרנזקציה), במחזור הבא שניהם צריכים לרדת
    // ------------------------------------------
    property req_gnt_drops_p;
        @(posedge clk) (req && gnt) |=> (!req && !gnt);
    endproperty

    ASSERT_HANDSHAKE_DROP: assert property(req_gnt_drops_p)
        else $error("[SVA] Protocol Violation: REQ and GNT did not drop simultaneously after handshake.");

    // ------------------------------------------
    // 3. Stability (Critical!)
    // ברגע שהמאסטר הרים REQ, המידע (Addr, Data, Control) חייב להישאר יציב
    // עד שהוא מקבל GNT. אסור לשנות דעה באמצע!
    // ------------------------------------------
    property master_data_stability_p;
        @(posedge clk) (req && !gnt) |=> 
            ($stable(addr) && $stable(wdata) && $stable(write_en));
    endproperty

    ASSERT_MASTER_STABILITY: assert property(master_data_stability_p)
        else $error("[SVA] Stability Violation: Address/Data changed while waiting for GNT.");

    // ------------------------------------------
    // 4. Unknown Checks (X/Z)
    // מוודא שאין ערכים לא חוקיים על קווי הבקרה הקריטיים
    // ------------------------------------------
    ASSERT_NO_X_ON_GNT: assert property (@(posedge clk) !$isunknown(gnt))
        else $error("[SVA] Error: GNT signal is X or Z!");

endinterface // bus_if