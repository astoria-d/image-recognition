library IEEE;
use IEEE.std_logic_1164.all;
use ieee.std_logic_arith.all;

entity tb_cam_vga_test01 is
end tb_cam_vga_test01;

architecture stimulus of tb_cam_vga_test01 is 
component cam_vga_test01
port (
	-- input clock 50 mhz
	pi_clk_50m 	: in std_logic;
	-- reset button
	pi_rst_n     	: in std_logic;

	-- switch input
	sw_input     	: in std_logic_vector(6 downto 0);

	-- vga output
	po_h_sync_n		: out std_logic;
	po_v_sync_n		: out std_logic;
	po_r			: out std_logic_vector(3 downto 0);
	po_g			: out std_logic_vector(3 downto 0);
	po_b			: out std_logic_vector(3 downto 0);

	-- camera interface
	po_cam_scl		: out std_logic;
	pio_cam_sda		: inout std_logic;

	po_cam_xvclk	: out std_logic;
	po_cam_rst		: out std_logic;
	po_cam_pwdn		: out std_logic;

	pi_cam_href		: in std_logic;
	pi_cam_vsync	: in std_logic;
	pi_cam_pclk		: in std_logic;

	pi_cam_y		: in std_logic_vector(1 downto 0);
	pi_cam_d		: in std_logic_vector(7 downto 0)
);
end component;

signal base_clk		: std_logic;
signal reset_input	: std_logic;

signal h_sync_n		: std_logic;
signal v_sync_n		: std_logic;
signal r			: std_logic_vector(3 downto 0);
signal g			: std_logic_vector(3 downto 0);
signal b			: std_logic_vector(3 downto 0);

signal cam_scl			: std_logic;
signal cam_sda			: std_logic;
signal cam_href			: std_logic;
signal cam_vsync		: std_logic;
signal cam_xvclk			: std_logic;
signal cam_pclk			: std_logic;
signal cam_y			: std_logic_vector(1 downto 0);
signal cam_d			: std_logic_vector(7 downto 0);
signal cam_rst			: std_logic;
signal cam_pwdn			: std_logic;

signal dbg_base_clk		: std_logic;


constant powerup_time   : time := 2 us;
constant reset_time     : time := 890 ns;

-- device address  = 0x21
constant sw_input		: std_logic_vector(6 downto 0) := "0100001";

--DE1 base clock = 50 MHz
constant base_clock_time : time := 20 ns;

begin

	sim_board : cam_vga_test01 port map (
		base_clk, reset_input, sw_input,
		h_sync_n, v_sync_n, r, g, b, 
		cam_scl, cam_sda,
		cam_xvclk, cam_rst, cam_pwdn,
		cam_href, cam_vsync,
		cam_pclk, cam_y, cam_d);

	--- input reset.
	reset_p: process
	begin
		reset_input <= '1';
		wait for powerup_time;

		reset_input <= '0';
		wait for reset_time;

		reset_input <= '1';
		wait;
	end process;

	--- generate base clock.
	clock_p: process
	begin
		base_clk <= '1';
		wait for base_clock_time / 2;
		base_clk <= '0';
		wait for base_clock_time / 2;
	end process;

end stimulus;

