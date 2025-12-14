`timescale 1ns/1ns

import design_params_pkg::*;

interface bus_if(
    input logic clk,
    input logic rst_n
);

//interface signals
logic req;
logic gnt;
logic [P_ADDR_WIDTH-1:0] addr;
logic [P_DATA_WIDTH-1:0] wdata;
logic [P_DATA_WIDTH-1:0] rdata;
logic write_en;

//TB cklocking blocks
clocking driver_cb @(posedge clk);
    default input #1step output #2ns;
    input gnt;
    output req;
    output addr;
    output wdata;
    input rdata;
    output write_en;
endclocking

clocking monitor_cb @(posedge clk);
    default input #1step output #2ns;
    input gnt;
    input req;
    input addr;
    input wdata;
    input rdata;
    input write_en;
endclocking

//modports
modport driver_md(clocking driver_cb);
modport monitor_md(clocking monitor_cb);
//modport sva_md(clocking monitor_cb);

modport slave_md(
input req,addr,wdata,write_en,
output gnt,rdata
);

//SVA interface 

//STRAT OF TRANSACTION
//END OF TRANSACTION 
//NEW TRANSACTION AFTER ENDING PREVIOUS TRANSACTION

//gnt should be asserted within 3 cycles after req is asserted
property req_before_gnt_p;    
    @(posedge clk) disable iff(!rst_n)
    req |-> ##[0:3] gnt;
endproperty

IF_req_gnt_ack: assert property(req_before_gnt_p)
    else $error("[IF] GNT dont rise within 3 cycles after REQ");

//req and gnt should drop in sequence
property req_gnt_drops_p;
    @(posedge clk) disable iff(!rst_n) 
        (req && gnt) |=> !req && !gnt;
endproperty
IF_req_gnt_drops: assert property(req_gnt_drops_p)
    else $error("[IF] Handshake violation: REQ and GNT did not drop in simultaniously.");

//req cannot go high before gnt is lows
property req_low_p;
    @(posedge clk) disable iff(!rst_n) 
        gnt |-> !req;
endproperty
IF_req_low: assert property(req_low_p)
    else $error("[IF] Protocol violation: REQ deasserted immediately when GNT was asserted.");

//data stability during active handshake
property master_data_stability_p;
    @(posedge clk) disable iff(!rst_n)
        (req && gnt) |-> ##1 (
            $past(addr) == addr &&
            $past(wdata) == wdata &&
            $past(write_en) == write_en
        );
endproperty
IF_master_stability: assert property(master_data_stability_p)
    else $error("[IF] Master protocol violation: Address or data changed during active handshake.");


endinterface //bus_if








