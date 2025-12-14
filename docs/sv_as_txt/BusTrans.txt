import design_params_pkg::*;

class BusTrans;
    
    //local parameters
    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 32;
    typedef enum logic {WRITE,READ} kind_s;

    //properties
    rand logic m_write_en;
    rand logic [ADDR_WIDTH-1:0] m_addr;
    rand logic [DATA_WIDTH-1:0] m_data;
    rand kind_s m_kind;
    int m_unique_id;
    static int m_counter_id;

    //constraints
    constraint addr_c { m_addr inside {P_ADDR_CONTROL,P_ADDR_LOAD,P_ADDR_STATUS}; }
    constraint data_c { m_data inside {[0:255]}; }


    //constructor
    function new();
        m_unique_id = this.m_counter_id;
    endfunction //new()


virtual function void display(string name);
    $display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h",$time,name,m_kind,m_unique_id,m_addr,m_data);
endfunction

function void ID_increment;
    m_counter_id = m_counter_id + 1;
    $display("[%0t]: ID counter:%0d",$time,m_unique_id);
endfunction

endclass //BusTrans





