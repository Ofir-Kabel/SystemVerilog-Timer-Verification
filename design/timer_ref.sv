/*
`timescale 1ns/1ps


module timer_ref (
    bus_if.slave_md bus
);
//register map addr
localparam CONTROL_ADDR = 0;
localparam LOAD_ADDR    = 4;
localparam STATUS_ADDR  = 8;

logic [2:0] control_reg;        //[2]CLR_STATUS ,[1]RELOAD_EN ,START[1]
logic [15:0] load_reg,load_val;
logic status_reg;
logic has_been_read;

logic [DATA_WIDTH-1:0] counter;

typedef enum logic {IDLE,START,COUNTDOWN,FINISH} fsm_state;
fsm_state pst,nst;

//read/write block
always @(posedge bus.clk or negedge bus.rst_n)begin
    if(!bus.rst_n)begin
        bus.gnt <= 1'b0;
        bus.rdata <= 32'd0;
        has_been_read <= 1'b0;
    end else if (bus.req)begin
            bus.gnt <= 1'b1;
            has_been_read <= 1'b0;
        if (bus.write_en)begin
            if(bus.addr == CONTROL_ADDR && bus.gnt)begin
                control_reg <= bus.wdata[2:0];
            end else if(bus.addr == LOAD_ADDR && bus.gnt)begin
                load_reg <= bus.wdata[15:0];
            end
        end else begin               
            if(bus.addr == CONTROL_ADDR)begin
                bus.rdata <= {29'd0,control_reg};
            end else if(bus.addr == LOAD_ADDR)begin
                bus.rdata <= {16'd0,load_reg};
            end else if(bus.addr == STATUS_ADDR)begin
                bus.rdata <= {31'd0,status_reg};
                has_been_read <= 1'b1;
            end else
                bus.rdata <= 32'd0;
        end
    end else
        bus.gnt <= 0;
        has_been_read <= 0;
end

//CAPTUE TIMING page7
//registers block
always @(*) begin
    if(!bus.rst_n)
        status_reg = 0;
    else if (control_reg[2])
        status_reg = 0;
    else if(has_been_read)
        status_reg = 0;
    else if(count_done)
        status_reg = 1;
end    


//pst counter fsm block
always @(posedge bus.clk or negedge bus.rst_n)begin
    if(!bus.rst_n)
        pst <= IDLE;
    else
        pst <= nst;

end

//pst counter fsm block
always @(*)begin
    case(pst)
    IDLE: begin
        nst = (control_reg[0])? START:IDLE;
    end
    COUNTDOWN:begin
        //if(control_reg[0])
        nst = (counter == 0)? FINISH:COUNTDOWN;
    end
    FINISH:begin
        nst = (control_reg[1])? COUNTDOWN:IDLE;
    end
    default: nst = IDLE;
    endcase
end

//pst counter fsm block
always @(posedge bus.clk or negedge bus.rst_n)begin
    if(!bus.rst_n)begin
        counter <= 16'd1;
        count_done <= 0;
    end else case(nst)
    IDLE: begin
        counter <= (load_reg && control_reg[0])? load_reg:16'd1;
        count_done <= 0;
    end 
    COUNTDOWN:begin
        counter <= counter - 1;
        count_done <= 0;
    end
    FINISH:begin
        counter <= (load_reg && control_reg[1])? load_reg:16'h1;
        count_done <= 1;
    end
    default:begin
        counter <= 16'd1;
        count_done <= 0;
    end
    endcase
end


endmodule
*/