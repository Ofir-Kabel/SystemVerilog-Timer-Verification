class ReadTrans extends BusTrans;

  //constructor    
  function new();
    super.new();
    m_kind = READ;
    m_write_en = 0;
  endfunction  //new()

  virtual function void display(string name);
    $display("[%0t]: [%0s - %0s] ID:%0d   ADDR:%0h   DATA:%0h  WR_EN:%0d", $time, name, m_kind,
             m_unique_id, m_addr, m_data, m_write_en);
  endfunction

endclass  //ReadTrans
