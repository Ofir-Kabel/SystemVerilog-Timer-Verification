`timescale 1ns/1ns

import design_pkg::*;

module tb_top;

    logic clk;
    logic rst_n;

    // VIF Declaration
    bus_if bus_if(.clk(clk), .rst_n(rst_n));
   // Inside tb_top module

    timer_periph timer_inst (
        .clk        (clk),             
        .reset_n    (rst_n),          
        .req        (bus_if.req),     
        .gnt        (bus_if.gnt),     
        .addr       (bus_if.addr),   
        .wdata      (bus_if.wdata),  
        .rdata      (bus_if.rdata),        
        .write_en   (bus_if.write_en) 
    );

    // Test Instantiation
    virtual bus_if.bus_if bus_vif_handle = bus_if;
    BaseTest test_inst;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Reset generation
    initial begin
        rst_n = 0;
        #50;
        rst_n = 1;
    end

    // Test run
    initial begin
        test_inst = new(bus_vif_handle);
        test_inst.test_run();
    end

endmodule