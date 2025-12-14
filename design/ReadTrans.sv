class ReadTrans extends BusTrans;

    //constructor    
    function new();
        super.new();
        m_kind = READ;
    endfunction //new()

virtual function void display(string name);
    $display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h",$time,name,m_kind,m_unique_id,m_addr,m_data);
endfunction

endclass //ReadTrans