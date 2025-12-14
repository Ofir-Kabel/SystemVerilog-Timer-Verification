class Sequencer;

  mailbox #(BusTrans) seq_drv_mb, seq_ref_mb;
  BusTrans bus_tr;

  //constructor
  function new(mailbox#(BusTrans) i_seq_drv_mb, mailbox#(BusTrans) i_seq_ref_mb);
    seq_drv_mb = i_seq_drv_mb;
    seq_ref_mb = i_seq_ref_mb;
  endfunction  //new()

  task automatic rand_read_write(input int num_transactions);
    $display("[%0t] Sequencer: Rand RD/WR start for %0d transactions\n", $time, num_transactions);
    repeat (num_transactions) begin
      if ($urandom_range(0, 1)) begin
        automatic WriteTrans new_write_trans = new();
        assert (new_write_trans.randomize())
        else $error("[%0t] Sequencer Error: randomization failed in write_trans\n", $time);
        bus_tr = new_write_trans;
      end else begin
        automatic ReadTrans new_read_trans = new();
        assert (new_read_trans.randomize())
        else $error("[%0t] Sequencer Error: randomization failed in read_trans\n", $time);
        bus_tr = new_read_trans;
      end
      bus_tr.ID_increment();
      seq_drv_mb.put(bus_tr);
      seq_ref_mb.put(bus_tr);
      bus_tr.display("SEQ");
    end
  endtask  //automatic

  task automatic rand_read(input int num_transactions);
    $display("[%0t] Sequencer: Rand RD start for %0d transactions\n", $time, num_transactions);
    repeat (num_transactions) begin
      automatic ReadTrans new_read_trans = new();
      assert (new_read_trans.randomize())
      else $error("[%0t] Sequencer Error: randomization failed in read_trans\n", $time);
      bus_tr = new_read_trans;
      bus_tr.ID_increment();
      seq_drv_mb.put(bus_tr);
      seq_ref_mb.put(bus_tr);
      bus_tr.display("SEQ");
    end
  endtask  //automatic

  task automatic write_than_read(input [P_ADDR_WIDTH-1:0] i_addr, input [P_DATA_WIDTH-1:0] i_data);
    begin
      automatic WriteTrans new_write_trans = new();
      automatic ReadTrans  new_read_trans = new();
      $display("[%0t]: Sequencer Write than Read transactions", $time);
      new_write_trans.m_data = i_data;
      new_write_trans.m_addr = i_addr;
      new_write_trans.m_write_en = 1'b1;
      bus_tr = new_write_trans;
      bus_tr.ID_increment();
      seq_drv_mb.put(bus_tr);
      seq_ref_mb.put(bus_tr);
      bus_tr.display("SEQ");
      new_read_trans.m_addr = i_addr;
      new_read_trans.m_write_en = 1'b0;
      bus_tr = new_read_trans;
      bus_tr.ID_increment();
      seq_drv_mb.put(bus_tr);
      seq_ref_mb.put(bus_tr);
      bus_tr.display("SEQ");
    end
  endtask  //automatic

  task automatic rand_write(input int num_transactions);
    $display("[%0t]: Sequencer Rand WR start for %0d transactions", $time, num_transactions);
    repeat (num_transactions) begin
      automatic WriteTrans new_write_trans = new();
      assert (new_write_trans.randomize())
      else $error("[%0t]: Error[SEQ] => randomization failed in write_trans", $time);
      bus_tr = new_write_trans;
      bus_tr.ID_increment();
      seq_drv_mb.put(bus_tr);
      seq_ref_mb.put(bus_tr);
      bus_tr.display("SEQ");
    end
  endtask  //automatic

  task automatic specific_read(input [P_ADDR_WIDTH-1:0] i_addr);
    ReadTrans new_read_trans = new();
    $display("[%0t]: Sequencer Specific RD start transaction", $time);
    new_read_trans.m_addr = i_addr;  //specific address
    new_read_trans.m_write_en = 1'b0;
    bus_tr = new_read_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic specific_write(input [P_ADDR_WIDTH-1:0] i_addr, input [P_DATA_WIDTH-1:0] i_data);
    WriteTrans new_write_trans = new();
    $display("[%0t]: Sequencer Specific WR start transactions", $time);
    new_write_trans.m_addr = i_addr;  //specific address
    new_write_trans.m_data = i_data;  //specific data
    new_write_trans.m_write_en = 1'b1;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic basic_operation(input [P_DATA_WIDTH-1:0] i_control_data,
                                 input [P_DATA_WIDTH-1:0] i_load_data);
    WriteTrans new_write_trans = new();
    ReadTrans  new_read_trans = new();
    $display("[%0t]: Sequencer: basic operation WR start", $time);
    $display("[%0t]: Sequencer: writing to Load reg", $time);
    new_write_trans.m_addr = 4;  //specific address
    new_write_trans.m_data = i_load_data;  //specific data
    new_write_trans.m_write_en = 1'b1;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
    $display("[%0t]: Sequencer: writing to Control reg", $time);
    new_write_trans.m_addr = 0;  //specific address
    new_write_trans.m_data = i_control_data;  //specific data
    new_write_trans.m_write_en = 1'b1;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
    $display("[%0t]: Sequencer: reading the Status reg", $time);
    new_read_trans.m_addr = 8;  //specific address
    new_read_trans.m_write_en = 1'b0;
    bus_tr = new_read_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic checking_status();
    automatic ReadTrans new_read_trans = new();
    $display("[%0t]: Sequencer checking status", $time);
    new_read_trans.m_addr = 8;
    new_read_trans.m_write_en = 0;
    bus_tr = new_read_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic loading(input [P_DATA_WIDTH-1:0] i_load_data);
    automatic WriteTrans new_write_trans = new();
    $display("[%0t]: Sequencer loading", $time);
    new_write_trans.m_addr = 4;
    new_write_trans.m_data = i_load_data;
    new_write_trans.m_write_en = 1;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic start_count_i_reload(input i_control_data);
    automatic WriteTrans new_write_trans = new();
    if (i_control_data) begin
      $display("[%0t]: Sequencer start countdown without reload", $time);
      new_write_trans.m_data = 32'h00000001;
    end else begin
      $display("[%0t]: Sequencer start countdown with reload", $time);
      new_write_trans.m_data = 32'h00000003;
    end
    new_write_trans.m_addr = 0;
    new_write_trans.m_write_en = 1;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

  task automatic status_reset();
    automatic WriteTrans new_write_trans = new();
    $display("[%0t]: Sequencer status reset", $time);
    new_write_trans.m_addr = 0;
    new_write_trans.m_write_en = 1;
    new_write_trans.m_data = 32'd4;
    bus_tr = new_write_trans;
    bus_tr.ID_increment();
    seq_drv_mb.put(bus_tr);
    seq_ref_mb.put(bus_tr);
    bus_tr.display("SEQ");
  endtask  //automatic

endclass
