//-----------------------------------
// CLASS: DRIVER
//
// DESCRIPTION:
//  this class drives the signals through th DUT
//-----------------------------------
class Driver;
  //-----------------------------------
  //properties
  virtual bus_if.driver_md m_bus_vif;
  mailbox #(BusTrans) seq_drv_mb;
  BusTrans m_drv_trans;
  Monitor m_mon;
  //internal properties
  local logic m_ready;  //*****what for????
  //-----------------------------------
  // FCN: constructor
  //
  // DESCRIPTION:
  //  constructor for the class
  //
  // PARAMETERS:
  //  i_bus_vif - (input) the virtual interface connecting between the driver to the DUT
  //  i_sem - (input) semaphore key
  //  i_mb - (input) mailbox connection    
  //  i_tr - (input) transaction data 
  //
  //------------------------------------
  function new(virtual bus_if.driver_md i_bus_vif, mailbox#(BusTrans) i_seq_drv_mb, Monitor i_mon);
    this.m_bus_vif = i_bus_vif;
    this.seq_drv_mb = i_seq_drv_mb;
    this.m_mon = i_mon;
  endfunction  //new()

  task automatic drv_write();
    begin
      $display("[%0t]: Driver is writing..", $time);
      @(m_bus_vif.driver_cb);  //check this line
      m_bus_vif.driver_cb.write_en <= m_drv_trans.m_write_en;
      m_bus_vif.driver_cb.req <= 1;
      m_bus_vif.driver_cb.addr <= m_drv_trans.m_addr;
      m_bus_vif.driver_cb.wdata <= m_drv_trans.m_data;
      wait (m_bus_vif.driver_cb.gnt);
      @(m_bus_vif.driver_cb);
      m_bus_vif.driver_cb.req <= 0;
      wait (!m_bus_vif.driver_cb.gnt);
      @(m_bus_vif.driver_cb);
    end
  endtask  //automatic

  task automatic drv_read();
    begin
      $display("[%0t]: Driver is reading..", $time);
      @(m_bus_vif.driver_cb);
      m_bus_vif.driver_cb.write_en <= m_drv_trans.m_write_en;
      m_bus_vif.driver_cb.req <= 1;
      m_bus_vif.driver_cb.addr <= m_drv_trans.m_addr;
      wait (m_bus_vif.driver_cb.gnt);
      m_drv_trans.m_data = m_bus_vif.driver_cb.rdata;
      m_bus_vif.driver_cb.req <= 0;
      wait (!m_bus_vif.driver_cb.gnt);
      @(m_bus_vif.driver_cb);
    end
  endtask  //automatic

  task automatic run();
    begin
      $display("[%0t]: Driver start running..", $time);
      forever begin
        seq_drv_mb.get(m_drv_trans);
        m_drv_trans.display("DRV");
        m_mon.push_intended(m_drv_trans);
        if (m_drv_trans.m_write_en) begin
          drv_write();

        end else begin
          drv_read();
        end
      end
    end
  endtask  //run()

endclass  //Driver
