library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_cam_vga_test01 is
end tb_cam_vga_test01;

architecture stimulus of tb_cam_vga_test01 is 
component cam_vga_test01
port (
	-- input clock 50 mhz
	pi_clk_50m 	: in std_logic;

	-- reset button
	pi_rst_n     	: in std_logic;
	-- push button 0 - 3
	pi_btn	     	: in std_logic_vector(3 downto 0);
	-- switch input
	pi_switch		: in std_logic_vector(6 downto 0);

	-- vga output
	po_h_sync_n		: out std_logic;
	po_v_sync_n		: out std_logic;
	po_r				: out std_logic_vector(3 downto 0);
	po_g				: out std_logic_vector(3 downto 0);
	po_b				: out std_logic_vector(3 downto 0);

	-- camera interface
	po_cam_scl		: out std_logic;
	pio_cam_sda		: inout std_logic;

	-- xclk 24 MHz
	po_cam_xvclk	: out std_logic;
	-- active low reset
	po_cam_rst		: out std_logic;
	-- active high power down
	po_cam_pwdn		: out std_logic;

	pi_cam_href		: in std_logic;
	pi_cam_vsync	: in std_logic;
	pi_cam_pclk		: in std_logic;

	pi_cam_y			: in std_logic_vector(1 downto 0);
	pi_cam_d			: in std_logic_vector(7 downto 0);

	--7 seg LED 0
	po_svn_seg0		: out std_logic_vector(6 downto 0);
	po_svn_seg1		: out std_logic_vector(6 downto 0);
	po_svn_seg2		: out std_logic_vector(6 downto 0);
	po_svn_seg3		: out std_logic_vector(6 downto 0);
	po_svn_seg4		: out std_logic_vector(6 downto 0);
	po_svn_seg5		: out std_logic_vector(6 downto 0);

	--logic analyzer reference clock
	jtag_clk		: out std_logic
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
signal cam_xvclk		: std_logic;
signal cam_pclk			: std_logic;
signal cam_y			: std_logic_vector(1 downto 0);
signal cam_d			: std_logic_vector(7 downto 0);
signal cam_rst			: std_logic;
signal cam_pwdn			: std_logic;

signal dbg_base_clk		: std_logic;

signal btn_input		: std_logic_vector(3 downto 0) := "0000";
signal svn_seg0			: std_logic_vector(6 downto 0);
signal svn_seg1			: std_logic_vector(6 downto 0);
signal svn_seg2			: std_logic_vector(6 downto 0);
signal svn_seg3			: std_logic_vector(6 downto 0);
signal svn_seg4			: std_logic_vector(6 downto 0);
signal svn_seg5			: std_logic_vector(6 downto 0);

signal jtag_clk			: std_logic;

constant powerup_time   : time := 2 us;
constant reset_time     : time := 890 ns;

-- device address  = 0x21
constant sw_input		: std_logic_vector(6 downto 0) := "0110000";

--DE1 base clock = 50 MHz
constant base_clock_time : time := 20 ns;

-- OV2640 pixcel clock = 36 MHz
constant pclock_time  : time := 27.78 ns;

constant pline : integer := 1922;
constant vlines : integer := 1248;
constant pframe : integer := vlines * pline;

signal pcnt	: integer := 0;
signal hcnt	: integer := 0;
signal vcnt	: integer := 0;

begin

	sim_board : cam_vga_test01 port map (
		base_clk,
		reset_input, btn_input, sw_input,
		h_sync_n, v_sync_n, r, g, b, 
		cam_scl, cam_sda,
		cam_xvclk, cam_rst, cam_pwdn,
		cam_href, cam_vsync,
		cam_pclk, cam_y, cam_d,
		svn_seg0, svn_seg1, svn_seg2, svn_seg3, svn_seg4, svn_seg5,
		jtag_clk);

	--- input reset.
	reset_p: process
	begin
		reset_input <= '1';
		btn_input(0) <= '1';
		wait for powerup_time;

		reset_input <= '0';
		btn_input(0) <= '0';
		wait for reset_time;

		reset_input <= '1';
		btn_input(0) <= '1';
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


	--- input switch
	mode_set_p: process
	begin
		btn_input(1) <= '1';
		wait for powerup_time;
		wait for reset_time * 2;

		btn_input(1) <= '0';
		wait for reset_time;
		btn_input(1) <= '1';

		wait;
	end process;

	-- generate pclk.
	pclock_p: process
	begin
		cam_pclk <= '1';
		wait for pclock_time / 2;
		cam_pclk <= '0';
		wait for pclock_time / 2;
	end process;

	-- counter
	cam_cnt_p: process
	begin
		wait until falling_edge(cam_pclk);
		-- pcnt
		if (pcnt < pframe - 1) then
			pcnt <= pcnt + 1;
		else
			pcnt <= 0;
		end if;

		-- vsync
		if (pcnt < 4 * pline - 1) then
			cam_vsync <= '1';
		else
			cam_vsync <= '0';
		end if;

		-- hcnt, vcnt and href
		if (pcnt < 4 * pline + 27193 - 1 or pcnt > pframe - 57697 - 1) then
			cam_href <= '0';
			hcnt <= 0;
			vcnt <= 0;
		else
			if (hcnt < 1600 + 322 - 1) then
				if (hcnt < 1600 - 1) then
					cam_href <= '1';
				else
					cam_href <= '0';
				end if;
				hcnt <= hcnt + 1;
			else
				if (vcnt < 1200 - 1) then
					vcnt <= vcnt + 1;
				else
					vcnt <= 0;
				end if;
				cam_href <= '0';
				hcnt <= 0;
			end if;
		end if;
	end process;

	-- pixcel data
	cam_pix_p: process
	variable dmy : unsigned(7 downto 0) := "00000000";
	begin
		wait until falling_edge(cam_pclk);
		cam_d <= std_logic_vector(dmy);
		dmy := dmy + 1;
	end process;

end stimulus;

