class TbEnv;

    mailbox #(BusTrans) seq_drv_mb, seq_ref_mb, ref_sb_mb, mon_sb_mb;
    Driver drv;
    RefDutTimer ref_model;
    Scoreboard sb;
    Monitor mon;
    virtual bus_if vif;

    //constractor
    function new(input virtual bus_if i_vif);
        vif = i_vif;
        seq_drv_mb  = new(1);
        seq_ref_mb  = new(1);
        ref_sb_mb= new(1);
        mon_sb_mb= new(1);

        mon = new( vif , mon_sb_mb);
        drv = new( vif , seq_drv_mb, mon);
        ref_model = new( seq_ref_mb , ref_sb_mb ,i_vif);
        sb = new( ref_sb_mb , mon_sb_mb);
 

    endfunction //new()


    task automatic reset();
        begin
            $display("[%0t]: ENV reset",$time);
            // drv.m_bus_vif.driver_cb.req <= 0;
            drv.reset_interface();
            ref_model.reset_n();
        end
    endtask //automatic


    task automatic run();
            $display("[%0t]: ENV start running..",$time);
            fork
                drv.run();
                ref_model.run();
                sb.run();
                mon.run();
            join
    endtask //automatic


endclass //className