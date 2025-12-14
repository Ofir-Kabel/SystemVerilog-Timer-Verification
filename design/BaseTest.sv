
class BaseTest;

    Sequencer m_seq;
    TbEnv m_env;
    virtual bus_if.bus_if m_vif;

    function new(input virtual bus_if.bus_if i_vif);
        
        //creating the interface and environment
        m_vif = i_vif;
        m_env = new(m_vif);
        //after creating the env we can access its mailboxes to connect to the sequencer
        m_seq = new(m_env.seq_drv_mb, m_env.seq_ref_mb);
    endfunction //new()

    task automatic reset();
        begin
            m_env.reset();
        end
    endtask //automatic

    task automatic Test1();
        begin
            m_seq.loading(32'h00000007);
            #50;
            m_seq.start_count_i_reload($urandom_range(0,1));
            #50;
            m_seq.checking_status();
            #50;
            m_seq.checking_status();
            #100;
            m_seq.status_reset();
        end
    endtask //automatic

    task automatic Test2();
        begin
            m_seq.specific_write(16'h0004, 32'h0000000F); 
            #300;
            m_seq.specific_read(16'h0004);
            #200;
            m_seq.specific_write(16'h0001, 32'h00000003); 
            #500;
            m_seq.specific_read(16'h0008);
            #200;
            m_seq.specific_read(16'h0008);
            #200;
        end
    endtask
            
    task automatic Test3();
        begin
            m_seq.loading(32'h00000007);
            #50;
            m_seq.start_count_i_reload($urandom_range(0,1));
            #50;
            reset();
            #10;
            m_seq.checking_status();
            m_seq.loading(32'h0000000A);
            #50;
            m_seq.start_count_i_reload($urandom_range(0,1));
            #20;
            m_seq.loading(32'h00000003);
            #50;
            m_seq.start_count_i_reload($urandom_range(0,1));
            #50;
            m_seq.checking_status();
            #100;
            m_seq.status_reset();
        end
    endtask //automatic


//----------------------------------------
//
//              MAIN TEST
//
//----------------------------------------
task automatic test_run();

    this.reset();
    fork
        // Process 1: Start the environment components (Driver, Monitor, Scoreboard)
        m_env.run(); 
        
        begin 
            $display("\n-------STARTING_TEST_1---------\n");
            Test1();
            #1000;
            $display("\n-------STARTING_TEST_2---------\n");
            Test2();
        end 
            
    join_none 
    #1000ns; 
    $finish;
endtask //test_run()

endclass //BaseTest