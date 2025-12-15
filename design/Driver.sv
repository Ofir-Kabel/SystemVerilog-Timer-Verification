//-----------------------------------
//          CLASS: DRIVER
//
// DESCRIPTION:
//  drives the signals to the DUT through our interface
//-----------------------------------
class Driver;
  //-----------------------------------
  //properties
  local virtual bus_if.driver_md m_bus_vif;
  local mailbox #(BusTrans) seq_drv_mb;
  local BusTrans m_drv_trans;
  local Monitor m_mon;
  //-----------------------------------
  // FCN: constructor
  //
  // DESCRIPTION:
  //  constructor for the class
  //
  // PARAMETERS:
  //  i_bus_vif - (input) the virtual interface connecting between the driver to the DUT
  //  i_seq_drv_mb - (input) sequencer driver mailbox
  //  i_mon - (input) Monitor    
  //------------------------------------

  
  function new(virtual bus_if.driver_md i_bus_vif, mailbox#(BusTrans) i_seq_drv_mb, Monitor i_mon);
    this.m_bus_vif = i_bus_vif;
    this.seq_drv_mb = i_seq_drv_mb;
    this.m_mon = i_mon;
  endfunction  //new()

  function void reset_interface();
    m_bus_vif.driver_cb.write_en <= 0;
    m_bus_vif.driver_cb.req <= 0;
    m_bus_vif.driver_cb.addr <= '0;
    m_bus_vif.driver_cb.wdata <= '0;
  endfunction

  task automatic drv_write();
    begin
      @(m_bus_vif.driver_cb);  //check this line
      m_bus_vif.driver_cb.write_en <= m_drv_trans.m_write_en;
      m_bus_vif.driver_cb.req <= 1;
      m_bus_vif.driver_cb.addr <= m_drv_trans.m_addr;
      m_bus_vif.driver_cb.wdata <= m_drv_trans.m_data;
      wait (m_bus_vif.driver_cb.gnt);
      m_bus_vif.driver_cb.req <= 0;
      wait (!m_bus_vif.driver_cb.gnt);
      @(m_bus_vif.driver_cb);
    end
  endtask  //automatic

  task automatic drv_read();
    begin
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
