

class Coverage; 
    BusTrans tr;

    covergroup trans_cg;
    kind_cp: coverpoint tr.m_kind{
        bins write = {WRITE};
        bins read  = {READ};
    }
    addr_cp: coverpoint tr.m_addr{
        bins control_addr = {P_ADDR_CONTROL};
        bins load_addr = {P_ADDR_LOAD};
        bins status_addr = {P_ADDR_STATUS};
        bins out_range_addr = {[0:63]}; //else
    }
    data_cp: coverpoint tr.m_data{
        bins in_range =  {[0:32'h0000_FFFF]};
        bins out_range = {[32'h0001_000:32'hFFFF_FFFF]};
    }    

    write_en_cp: coverpoint tr.m_write_en;
    kind_addr_cross: cross kind_cp , addr_cp;
    kind_data_cross: cross kind_cp , data_cp;
    addr_data_cross: cross addr_cp , data_cp;

    reload_en_cp: coverpoint (tr.m_addr == P_ADDR_CONTROL ? tr.m_data[1] : 0) {
        bins en = {1};   // Fixed: Use set {1}
        bins dis = {0};  // Fixed: Use set {0}
    }
    expired_cp: coverpoint (tr.m_addr == P_ADDR_STATUS ? tr.m_data[0] : 0) {
        bins set = {1};    // Fixed: Use set {1}
        bins clear = {0};  // Fixed: Use set {0}
    }
    cross_kind_reload: cross kind_cp, reload_en_cp;

    endgroup
    

    //constructor
    function new();
        trans_cg = new();
    endfunction //new()

    //sampling method
    function void sample(input BusTrans i_tr);
        this.tr = i_tr;
        trans_cg.sample();
    endfunction //sample()

endclass //Coverage
