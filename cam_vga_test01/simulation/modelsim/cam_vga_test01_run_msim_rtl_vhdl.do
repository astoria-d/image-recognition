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


vcom "E:/daisuke/image-recognision/repo/cam_vga_test01/PLL_sim/PLL.vho"

vcom -93 -work work {E:/daisuke/image-recognision/repo/cam_vga_test01/cam_vga_test01.vhd}
vcom -93 -work work {E:/daisuke/image-recognision/repo/cam_vga_test01/cam_i2c.vhd}

vcom -93 -work work {E:/daisuke/image-recognision/repo/cam_vga_test01/simulation/modelsim/tb_cam_vga_test01.vhd}

vsim -t 1ps -L altera -L lpm -L sgate -L altera_mf -L altera_lnsim -L cyclonev -L rtl_work -L work -voptargs="+acc"  tb_cam_vga_test01

view structure
view signals

add wave -label pi_clk_50m sim:/tb_cam_vga_test01/sim_board/pi_clk_50m
add wave -label pi_rst_n sim:/tb_cam_vga_test01/sim_board/pi_rst_n

add wave -divider app

add wave -label usr_mode sim:/tb_cam_vga_test01/sim_board/usr_mode

#set show_i2c true
set show_i2c false

if $show_i2c {
	add wave -divider i2c

	add wave -label ce sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/ce
	add wave -label we sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/we

	add wave -label out_cnt -radix unsigned     sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/out_cnt

	add wave -label out_cnt_3_1 -radix unsigned  {sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/out_cnt(3 downto 1)}

	add wave -label cur_state sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/cur_state
	#add wave -label next_state sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/next_state

	add wave -label dev_addr -radix hex    sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/dev_addr
	add wave -label reg_addr -radix hex    sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/reg_addr
	add wave -label set_reg -radix hex   sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/set_reg
	add wave -label read_reg -radix hex   sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/read_reg



	add wave -label i2c_clk_div -radix unsigned     sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/i2c_clk_div
	add wave -label i2c_clk_div -radix binary       sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/i2c_clk_div


	add wave -label scl sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/scl
	add wave -label sda sim:/tb_cam_vga_test01/sim_board/cm_i2c_inst/sda
}

add wave -divider pll
add wave -label po_cam_xvclk sim:/tb_cam_vga_test01/sim_board/po_cam_xvclk

add wave -divider cam
add wave -label pi_cam_pclk sim:/tb_cam_vga_test01/sim_board/pi_cam_pclk

add wave -label pi_cam_vsync sim:/tb_cam_vga_test01/sim_board/pi_cam_vsync
add wave -label pi_cam_href sim:/tb_cam_vga_test01/sim_board/pi_cam_href


#run 1us

run 1500us
wave zoom full

#run 1500us
run 100ms


