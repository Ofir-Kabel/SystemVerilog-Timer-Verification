//-----------------------------------------------------------------------
// FILE: design_pkg.sv
//
// DESCRIPTION:
//   Main design package that includes all verification classes.
//
// AUTHOR: Ofir Kabel
// DATE: 2025-12-15
//-----------------------------------------------------------------------

`timescale 1ns/1ns

import design_params_pkg::*;

package design_pkg;
    `include "BusTrans.sv"
    `include "WriteTrans.sv"
    `include "ReadTrans.sv"
    `include "RefDutTimer.sv"
    `include "Coverage.sv"
    `include "Monitor.sv"
    `include "Driver.sv"
    `include "Sequencer.sv"
    `include "Scoreboard.sv"
    `include "TbEnv.sv"
    `include "BaseTest.sv"
endpackage
