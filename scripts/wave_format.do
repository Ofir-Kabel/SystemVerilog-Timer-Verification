onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/clk
add wave -noupdate /tb_top/rst_n
add wave -noupdate /tb_top/bus_if/monitor_cb/req
add wave -noupdate /tb_top/bus_if/monitor_cb/gnt
add wave -noupdate /tb_top/bus_if/monitor_cb/write_en
add wave -noupdate /tb_top/bus_if/monitor_cb/addr
add wave -noupdate /tb_top/bus_if/monitor_cb/rdata
add wave -noupdate /tb_top/bus_if/monitor_cb/wdata
add wave -noupdate /tb_top/timer_inst/clk
add wave -noupdate /tb_top/timer_inst/reset_n
add wave -noupdate /tb_top/timer_inst/req
add wave -noupdate /tb_top/timer_inst/gnt
add wave -noupdate /tb_top/timer_inst/write_en
add wave -noupdate /tb_top/timer_inst/addr
add wave -noupdate /tb_top/timer_inst/wdata
add wave -noupdate /tb_top/timer_inst/rdata
add wave -noupdate /tb_top/timer_inst/m_load
add wave -noupdate /tb_top/timer_inst/m_reload_en
add wave -noupdate /tb_top/timer_inst/m_expired
add wave -noupdate /tb_top/timer_inst/m_counter
add wave -noupdate /tb_top/timer_inst/m_running
add wave -noupdate /design_pkg::BusTrans::m_counter_id
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {404507 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 238
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1017544 ps}
