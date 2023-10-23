transcript on
if ![file isdirectory cam_vga_test01_iputf_libs] {
	file mkdir cam_vga_test01_iputf_libs
}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

###### Libraries for IPUTF cores 
###### End libraries for IPUTF cores 
###### MIF file copy and HDL compilation commands for IPUTF cores 


vcom "../../PLL_sim/PLL.vho"

vcom -93 -work work {../../cam_i2c.vhd}
vcom -93 -work work {../../cam_vga.vhd}
vcom -93 -work work {../../cam_vga_test01.vhd}

vcom -93 -work work {./tb_cam_vga_test02.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  tb_cam_vga_test02

view structure
view signals

add wave -label pi_clk_50m sim:/tb_cam_vga_test02/sim_board/pi_clk_50m
add wave -label pi_rst_n sim:/tb_cam_vga_test02/sim_board/pi_rst_n
add wave -label jtag_clk sim:/tb_cam_vga_test02/sim_board/jtag_clk

add wave -divider app

add wave -label usr_mode sim:/tb_cam_vga_test02/sim_board/usr_mode

#set show_i2c true
set show_i2c false

if $show_i2c {
	add wave -divider i2c

	add wave -label ce sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/ce
	add wave -label we sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/we

	add wave -label out_cnt -radix unsigned     sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/out_cnt

	add wave -label out_cnt_3_1 -radix unsigned  {sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/out_cnt(3 downto 1)}

	add wave -label cur_state sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/cur_state
	#add wave -label next_state sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/next_state

	add wave -label dev_addr -radix hex    sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/dev_addr
	add wave -label reg_addr -radix hex    sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/reg_addr
	add wave -label set_reg -radix hex   sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/set_reg
	add wave -label read_reg -radix hex   sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/read_reg



	add wave -label i2c_clk_div -radix unsigned     sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/i2c_clk_div
	add wave -label i2c_clk_div -radix binary       sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/i2c_clk_div


	add wave -label scl sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/scl
	add wave -label sda sim:/tb_cam_vga_test02/sim_board/cm_i2c_inst/sda
}

add wave -divider pll
add wave -label po_cam_xvclk sim:/tb_cam_vga_test02/sim_board/po_cam_xvclk

add wave -divider "dummy camera device"
add wave -label pi_cam_pclk sim:/tb_cam_vga_test02/sim_board/pi_cam_pclk

add wave -label pcnt sim:/tb_cam_vga_test02/pcnt
add wave -label hcnt sim:/tb_cam_vga_test02/hcnt
add wave -label vcnt sim:/tb_cam_vga_test02/vcnt


add wave -label pi_cam_vsync sim:/tb_cam_vga_test02/sim_board/pi_cam_vsync
add wave -label pi_cam_href sim:/tb_cam_vga_test02/sim_board/pi_cam_href
add wave -label pi_cam_d -radix unsigned   sim:/tb_cam_vga_test02/sim_board/pi_cam_d


add wave -divider "==="
add wave -divider "==="
add wave -divider "==="
add wave -divider "camera module"

add wave -label pi_cam_href sim:/tb_cam_vga_test02/sim_board/pi_cam_href
add wave -label pi_cam_vsync sim:/tb_cam_vga_test02/sim_board/pi_cam_vsync
add wave -label cm_h_cnt -radix unsigned   sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/cm_h_cnt
add wave -label cm_v_cnt -radix unsigned   sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/cm_v_cnt

add wave -label cm_r -radix hex sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/cm_r
add wave -label cm_g -radix hex sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/cm_g
add wave -label cm_b -radix hex sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/cm_b


add wave -label vga_h_cnt -radix unsigned   sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/vga_h_cnt
add wave -label vga_v_cnt -radix unsigned   sim:/tb_cam_vga_test02/sim_board/cm_vga_inst/vga_v_cnt

add wave -label po_h_sync_n sim:/tb_cam_vga_test02/sim_board/po_h_sync_n
add wave -label po_v_sync_n sim:/tb_cam_vga_test02/sim_board/po_v_sync_n


add wave -label po_r -radix unsigned   sim:/tb_cam_vga_test02/sim_board/po_r
add wave -label po_g -radix unsigned   sim:/tb_cam_vga_test02/sim_board/po_g
add wave -label po_b -radix unsigned   sim:/tb_cam_vga_test02/sim_board/po_b


#run 1us

run 1500us
wave zoom full

#run 1500us

#run 100ms


