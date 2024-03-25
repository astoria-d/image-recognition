library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cam_vga_test01 is
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
	-- user mode
	po_svn_seg0		: out std_logic_vector(6 downto 0);

	-- not in use
	po_svn_seg1		: out std_logic_vector(6 downto 0);

	-- input switch, i2c addr
	po_svn_seg2		: out std_logic_vector(6 downto 0);
	po_svn_seg3		: out std_logic_vector(6 downto 0);

	-- i2c read value
	po_svn_seg4		: out std_logic_vector(6 downto 0);
	po_svn_seg5		: out std_logic_vector(6 downto 0);

	-- LEDs
	po_led			: out std_logic_vector(9 downto 0);

	--logic analyzer reference clock
	jtag_clk		: out std_logic
);
end cam_vga_test01;

architecture rtl of cam_vga_test01 is

component PLL
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
end component;

component cam_i2c
	port (
		-- input clock 50 mhz
		pi_clk_50m 	: in std_logic;

		-- camera data interface
		ce				: in std_logic;
		we				: in std_logic;
		dev_addr		: in std_logic_vector(6 downto 0);
		reg_addr		: in std_logic_vector(7 downto 0);
		set_reg			: in std_logic_vector(7 downto 0);
		read_reg		: out std_logic_vector(7 downto 0);

		-- output i2c interface
		scl				: out std_logic;
		sda				: inout std_logic
	);
end component;

component cam_vga
	port (
		-- input clock 50 mhz
		pi_clk_50m,

		-- camera 36 mhz
		pi_cam_pclk 	: in std_logic;

		-- user reset signal
		usr_rst 			: std_logic;

		-- camera data interface
		pi_cam_href		: in std_logic;
		pi_cam_vsync	: in std_logic;
		pi_cam_y			: in std_logic_vector(1 downto 0);
		pi_cam_d			: in std_logic_vector(7 downto 0);

		-- vga output
		po_h_sync_n		: out std_logic;
		po_v_sync_n		: out std_logic;
		po_r				: out std_logic_vector(3 downto 0);
		po_g				: out std_logic_vector(3 downto 0);
		po_b				: out std_logic_vector(3 downto 0)
	);
end component;


type i2c_set_t is
record
	we		 : std_logic;
	reg_addr : std_logic_vector(7 downto 0);
	reg_value : std_logic_vector(7 downto 0);
	delay_cnt : integer;
end record;

constant INIT_DELAY : integer := 2500;
constant I2C_FRM_CNT : integer := 6400 * 4;
constant I2C_EN_CNT : integer := 5000 * 4;
--5msec delay for 50Mhz
constant DELAY_5MS : integer := 250000;

constant DEV_END_MARKER : std_logic_vector(7 downto 0) := "00000000";

type i2c_init_array is array (0 to 198) of i2c_set_t;


-- usr_mode = "00"
constant init_data_ov2640 : i2c_init_array := (
	('0', std_logic_vector(to_unsigned(16#0a#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#0b#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#2e#, 8)), std_logic_vector(to_unsigned(16#df#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#3c#, 8)), std_logic_vector(to_unsigned(16#32#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#11#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#09#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#04#, 8)), std_logic_vector(to_unsigned(16#a8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#13#, 8)), std_logic_vector(to_unsigned(16#e5#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#14#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#0c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#78#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#3a#, 8)), std_logic_vector(to_unsigned(16#33#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#3b#, 8)), std_logic_vector(to_unsigned(16#fb#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#3e#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#11#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#16#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#39#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#35#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#22#, 8)), std_logic_vector(to_unsigned(16#0a#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#37#, 8)), std_logic_vector(to_unsigned(16#40#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#23#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#34#, 8)), std_logic_vector(to_unsigned(16#a0#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#06#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#06#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#07#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#0d#, 8)), std_logic_vector(to_unsigned(16#b7#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#0e#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#4a#, 8)), std_logic_vector(to_unsigned(16#81#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#21#, 8)), std_logic_vector(to_unsigned(16#99#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#24#, 8)), std_logic_vector(to_unsigned(16#40#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#25#, 8)), std_logic_vector(to_unsigned(16#38#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#26#, 8)), std_logic_vector(to_unsigned(16#82#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#63#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#46#, 8)), std_logic_vector(to_unsigned(16#22#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#0c#, 8)), std_logic_vector(to_unsigned(16#3a#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5d#, 8)), std_logic_vector(to_unsigned(16#55#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5e#, 8)), std_logic_vector(to_unsigned(16#7d#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5f#, 8)), std_logic_vector(to_unsigned(16#7d#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#60#, 8)), std_logic_vector(to_unsigned(16#55#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#61#, 8)), std_logic_vector(to_unsigned(16#70#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#62#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#05#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#20#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#28#, 8)), std_logic_vector(to_unsigned(16#30#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#6c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#6d#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#6e#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#70#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#71#, 8)), std_logic_vector(to_unsigned(16#94#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#73#, 8)), std_logic_vector(to_unsigned(16#c1#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#3d#, 8)), std_logic_vector(to_unsigned(16#34#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#04#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#57#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#4f#, 8)), std_logic_vector(to_unsigned(16#bb#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#9c#, 8)), I2C_FRM_CNT),

	--COM10: PCLK output qualified by href
--	('1', std_logic_vector(to_unsigned(16#15#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),


	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#7f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#f9#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#41#, 8)), std_logic_vector(to_unsigned(16#24#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#14#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#76#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#a0#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#42#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#18#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#87#, 8)), std_logic_vector(to_unsigned(16#d0#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#88#, 8)), std_logic_vector(to_unsigned(16#3f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#d7#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#d9#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#82#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c8#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c9#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#0e#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#90#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#0e#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#1a#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#31#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#5a#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#69#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#75#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#7e#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#8f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#96#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#a3#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#af#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#c4#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#d7#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#e8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#92#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#06#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#e3#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#96#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#19#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#0c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#24#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#30#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#28#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#26#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#98#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a4#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a8#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c5#, 8)), std_logic_vector(to_unsigned(16#11#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c6#, 8)), std_logic_vector(to_unsigned(16#51#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#bf#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c7#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b6#, 8)), std_logic_vector(to_unsigned(16#66#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b8#, 8)), std_logic_vector(to_unsigned(16#a5#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b7#, 8)), std_logic_vector(to_unsigned(16#64#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b9#, 8)), std_logic_vector(to_unsigned(16#7c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b3#, 8)), std_logic_vector(to_unsigned(16#af#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b4#, 8)), std_logic_vector(to_unsigned(16#97#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b5#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b0#, 8)), std_logic_vector(to_unsigned(16#c5#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b1#, 8)), std_logic_vector(to_unsigned(16#94#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#b2#, 8)), std_logic_vector(to_unsigned(16#0f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c4#, 8)), std_logic_vector(to_unsigned(16#5c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a6#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#d8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#1b#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#31#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#18#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#d8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#19#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#31#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#18#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#d8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#19#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#31#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#a7#, 8)), std_logic_vector(to_unsigned(16#18#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#7f#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#1f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e1#, 8)), std_logic_vector(to_unsigned(16#77#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#dd#, 8)), std_logic_vector(to_unsigned(16#7f#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c2#, 8)), std_logic_vector(to_unsigned(16#0e#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#04#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c0#, 8)), std_logic_vector(to_unsigned(16#c8#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#c1#, 8)), std_logic_vector(to_unsigned(16#96#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#86#, 8)), std_logic_vector(to_unsigned(16#3d#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#51#, 8)), std_logic_vector(to_unsigned(16#90#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#52#, 8)), std_logic_vector(to_unsigned(16#2c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#53#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#54#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#55#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#57#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#92#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#50#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5b#, 8)), std_logic_vector(to_unsigned(16#3c#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#04#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#05#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#da#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#d7#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#05#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
	('0', DEV_END_MARKER, DEV_END_MARKER, 0)
);


--constant init_data_ov2640 : i2c_init_array := (
--	-- bank 1
--	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
--	-- reset
--	('1', std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), DELAY_5MS),
--	-- bank 0
--	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#2e#, 8)), std_logic_vector(to_unsigned(16#df#, 8)), I2C_FRM_CNT),
--	-- bank 1
--	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#3c#, 8)), std_logic_vector(to_unsigned(16#32#, 8)), I2C_FRM_CNT),
--	-- CLKRC: PCLK = XCLK
--	('1', std_logic_vector(to_unsigned(16#11#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#09#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#04#, 8)), std_logic_vector(to_unsigned(16#28#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#13#, 8)), std_logic_vector(to_unsigned(16#e5#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#14#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#0c#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#78#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#3a#, 8)), std_logic_vector(to_unsigned(16#33#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#3b#, 8)), std_logic_vector(to_unsigned(16#fB#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#3e#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#11#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#16#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#39#, 8)), std_logic_vector(to_unsigned(16#92#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#35#, 8)), std_logic_vector(to_unsigned(16#da#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#22#, 8)), std_logic_vector(to_unsigned(16#1a#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#37#, 8)), std_logic_vector(to_unsigned(16#c3#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#23#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#34#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#36#, 8)), std_logic_vector(to_unsigned(16#1a#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#06#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#07#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#0d#, 8)), std_logic_vector(to_unsigned(16#87#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#0e#, 8)), std_logic_vector(to_unsigned(16#41#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#48#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5B#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#42#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#4a#, 8)), std_logic_vector(to_unsigned(16#81#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#21#, 8)), std_logic_vector(to_unsigned(16#99#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#24#, 8)), std_logic_vector(to_unsigned(16#40#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#25#, 8)), std_logic_vector(to_unsigned(16#38#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#26#, 8)), std_logic_vector(to_unsigned(16#82#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#63#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#46#, 8)), std_logic_vector(to_unsigned(16#22#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#0c#, 8)), std_logic_vector(to_unsigned(16#3c#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#61#, 8)), std_logic_vector(to_unsigned(16#70#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#62#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#05#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#20#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#28#, 8)), std_logic_vector(to_unsigned(16#30#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#6c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#6d#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#6e#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#70#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#71#, 8)), std_logic_vector(to_unsigned(16#94#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#73#, 8)), std_logic_vector(to_unsigned(16#c1#, 8)), I2C_FRM_CNT),
--	-- COM7, SVGA mode
--	('1', std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#40#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#17#, 8)), std_logic_vector(to_unsigned(16#11#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#18#, 8)), std_logic_vector(to_unsigned(16#43#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#19#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#1a#, 8)), std_logic_vector(to_unsigned(16#4b#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#32#, 8)), std_logic_vector(to_unsigned(16#09#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#37#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#4f#, 8)), std_logic_vector(to_unsigned(16#ca#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#a8#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#23#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#6d#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#3d#, 8)), std_logic_vector(to_unsigned(16#38#, 8)), I2C_FRM_CNT),
--	-- bank 0
--	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#7f#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#f9#, 8)), std_logic_vector(to_unsigned(16#c0#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#41#, 8)), std_logic_vector(to_unsigned(16#24#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#14#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#76#, 8)), std_logic_vector(to_unsigned(16#ff#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#a0#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#42#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#18#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#87#, 8)), std_logic_vector(to_unsigned(16#d5#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#88#, 8)), std_logic_vector(to_unsigned(16#3f#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#d7#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#d9#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#82#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c8#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c9#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#03#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#0e#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#90#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#0e#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#1a#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#31#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#5a#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#69#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#75#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#7e#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#88#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#8f#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#96#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#a3#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#af#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#c4#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#d7#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#e8#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#20#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#92#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#06#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#e3#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#05#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#05#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#04#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#96#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#19#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#0c#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#24#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#30#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#28#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#26#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#98#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c3#, 8)), std_logic_vector(to_unsigned(16#ed#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#a4#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#a8#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c5#, 8)), std_logic_vector(to_unsigned(16#11#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c6#, 8)), std_logic_vector(to_unsigned(16#51#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#bf#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c7#, 8)), std_logic_vector(to_unsigned(16#10#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b6#, 8)), std_logic_vector(to_unsigned(16#66#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b8#, 8)), std_logic_vector(to_unsigned(16#A5#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b7#, 8)), std_logic_vector(to_unsigned(16#64#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b9#, 8)), std_logic_vector(to_unsigned(16#7C#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b3#, 8)), std_logic_vector(to_unsigned(16#af#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b4#, 8)), std_logic_vector(to_unsigned(16#97#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b5#, 8)), std_logic_vector(to_unsigned(16#FF#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b0#, 8)), std_logic_vector(to_unsigned(16#C5#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b1#, 8)), std_logic_vector(to_unsigned(16#94#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#b2#, 8)), std_logic_vector(to_unsigned(16#0f#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c4#, 8)), std_logic_vector(to_unsigned(16#5c#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c0#, 8)), std_logic_vector(to_unsigned(16#64#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c1#, 8)), std_logic_vector(to_unsigned(16#4B#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#8c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#86#, 8)), std_logic_vector(to_unsigned(16#3D#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#51#, 8)), std_logic_vector(to_unsigned(16#C8#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#52#, 8)), std_logic_vector(to_unsigned(16#96#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#53#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#54#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#55#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#C8#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5b#, 8)), std_logic_vector(to_unsigned(16#96#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#82#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#c3#, 8)), std_logic_vector(to_unsigned(16#ed#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#7f#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	-- IMAGE_MODE RGB565
--	('1', std_logic_vector(to_unsigned(16#da#, 8)), std_logic_vector(to_unsigned(16#08#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#1f#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#e1#, 8)), std_logic_vector(to_unsigned(16#67#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('1', std_logic_vector(to_unsigned(16#dd#, 8)), std_logic_vector(to_unsigned(16#7f#, 8)), I2C_FRM_CNT),
--	-- R_BYPASS, 0: DSP
--	('1', std_logic_vector(to_unsigned(16#05#, 8)), std_logic_vector(to_unsigned(16#00#, 8)), I2C_FRM_CNT),
--	('0', DEV_END_MARKER, DEV_END_MARKER, 0)
--);

type i2c_test_init_array is array (0 to 3) of i2c_set_t;

-- ov2640
-- device address: 0x30
-- usr_mode = "01"
constant init_test_ov2640 : i2c_test_init_array := (
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#0a#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#0b#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', DEV_END_MARKER, DEV_END_MARKER, 0)
);

-- ov7670
-- ov7675
-- device address: 0x21
-- usr_mode = "10"
constant init_test_ov767x : i2c_test_init_array := (
	('1', std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#80#, 8)), I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#01#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#09#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', DEV_END_MARKER, DEV_END_MARKER, 0)
);


-- 24FC256 EEPROM
-- device address: 0x50
-- usr_mode = "11"
constant init_test_eeprom_24fc : i2c_test_init_array := (
	('1', std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8)), I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#1c#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', std_logic_vector(to_unsigned(16#1d#, 8)), "ZZZZZZZZ", I2C_FRM_CNT),
	('0', DEV_END_MARKER, DEV_END_MARKER, 0)
);

function hex_to_7seg (
	indata : in std_logic_vector
	) return std_logic_vector
	is
variable retdata : std_logic_vector(6 downto 0);
begin
	if (unsigned(indata) = 0) then
		retdata := "1000000";
	elsif (unsigned(indata) = 1) then
		retdata := "1111001";
	elsif (unsigned(indata) = 2) then
		retdata := "0100100";
	elsif (unsigned(indata) = 3) then
		retdata := "0110000";
	elsif (unsigned(indata) = 4) then
		retdata := "0011001";
	elsif (unsigned(indata) = 5) then
		retdata := "0010010";
	elsif (unsigned(indata) = 6) then
		retdata := "0000010";
	elsif (unsigned(indata) = 7) then
		retdata := "1011000";
	elsif (unsigned(indata) = 8) then
		retdata := "0000000";
	elsif (unsigned(indata) = 9) then
		retdata := "0010000";
	elsif (unsigned(indata) = 10) then
		retdata := "0001000";
	elsif (unsigned(indata) = 11) then
		retdata := "0000011";
	elsif (unsigned(indata) = 12) then
		retdata := "1000110";
	elsif (unsigned(indata) = 13) then
		retdata := "0100001";
	elsif (unsigned(indata) = 14) then
		retdata := "0000110";
	elsif (unsigned(indata) = 15) then
		retdata := "0001110";
	else
		retdata := "1111111";
	end if;
	return retdata;
end hex_to_7seg;

function hex_to_7seg (
	indata : in unsigned
	) return std_logic_vector
	is
variable indata_v : std_logic_vector(indata'length - 1 downto 0);
begin
	indata_v := std_logic_vector(indata);
	return hex_to_7seg(indata_v);
end hex_to_7seg;

signal cm_i2c_ce				: std_logic;
signal cm_i2c_we				: std_logic;
signal cm_i2c_dev_addr		: std_logic_vector(6 downto 0) := "0000000";
signal cm_i2c_reg_addr		: std_logic_vector(7 downto 0);
signal cm_i2c_set_value		: std_logic_vector(7 downto 0);
signal cm_i2c_read_value	: std_logic_vector(7 downto 0);

signal fpga_rst 				: std_logic;
signal usr_rst 				: std_logic;
signal pll_locked 			: std_logic;

signal jtag_i2c_clk			: std_logic;
signal jtag_cam_clk			: std_logic;

signal usr_mode 				: unsigned(1 downto 0) := "00";

-- for debugging
signal vsync_cnt				: unsigned(6 downto 0);
-- max 1232
signal href_cnt				: unsigned(10 downto 0);
-- max 1632
signal pclk_cnt				: unsigned(10 downto 0);

signal prev_vsync				: std_logic;
signal prev_href				: std_logic;
signal prev_pclk				: std_logic;

signal cam_r					: std_logic_vector(7 downto 0);
signal cam_g					: std_logic_vector(7 downto 0);
signal cam_b					: std_logic_vector(7 downto 0);

begin

	fpga_rst <= not pi_rst_n;
	usr_rst <= not pi_btn(0);
	po_cam_rst <= '1';
	po_cam_pwdn <= '0';

	-- PLL 24 MHz for ov2640 system clock
	pll_inst : PLL port map (
		pi_clk_50m,
		fpga_rst,
		po_cam_xvclk,
		pll_locked);

	-- i2c encoder
	cm_i2c_inst : cam_i2c port map (
		-- input clock 50 mhz
		pi_clk_50m,

		-- camera data interface
		cm_i2c_ce,
		cm_i2c_we,
		cm_i2c_dev_addr,
		cm_i2c_reg_addr,
		cm_i2c_set_value,
		cm_i2c_read_value, 

		-- output i2c interface
		po_cam_scl,
		pio_cam_sda);

--	cm_vga_inst : cam_vga port map (
--		-- input clock 50 mhz
--		pi_clk_50m,
--
--		-- camera 36 mhz
--		pi_cam_pclk,
--
--		-- user reset signal
--		usr_rst,
--
--		-- camera data interface
--		pi_cam_href,
--		pi_cam_vsync,
--		pi_cam_y,
--		pi_cam_d,
--
--		-- vga output
--		po_h_sync_n,
--		po_v_sync_n,
--		po_r,
--		po_g,
--		po_b
--	);

	-- i2c device address mode
	mode_p : process (pi_clk_50m)
	variable btn_prev : std_logic;
	begin
		if (rising_edge(pi_clk_50m)) then

			if (fpga_rst = '1') then
				usr_mode <= "00";
				btn_prev := '1';
			else
				if (pi_btn(1) = '1' and btn_prev = '0') then
					usr_mode <= usr_mode + 1;
				end if;
				btn_prev := pi_btn(1);
			end if;
		end if;
	end process;

	-- 7 segment display
	svn_umode_seg_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				po_svn_seg0 <= (others => '1');
			else
				po_svn_seg0 <= hex_to_7seg(usr_mode);
			end if;
		end if;
	end process;

	addr_seg_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				po_svn_seg2 <= (others => '1');
				po_svn_seg3 <= (others => '1');

				po_svn_seg4 <= (others => '1');
				po_svn_seg5 <= (others => '1');
			else
				po_svn_seg2 <= hex_to_7seg(pi_switch(3 downto 0));
				po_svn_seg3 <= hex_to_7seg(pi_switch(6 downto 4));
				
				po_svn_seg5 <= hex_to_7seg(cm_i2c_read_value(7 downto 4));
				po_svn_seg4 <= hex_to_7seg(cm_i2c_read_value(3 downto 0));
			end if;
		end if;
	end process;

	po_svn_seg1 <= (others => '1');

	led_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then

			if (usr_rst = '1') then
				po_led(9 downto 0) <= (others => '0');
			else
				po_led(0) <= pi_cam_href;
				po_led(1) <= pi_cam_vsync;
--				po_led(2) <= pi_cam_pclk;
				po_led(3) <= vsync_cnt(3);
				po_led(4) <= pclk_cnt(10);
				po_led(9 downto 5) <= (others => '0');
			end if;
		end if;
	end process;

	-- initialize camera
	cam_set_p : process (pi_clk_50m)
	variable frm_cnt : integer := 0;
	variable clk_cnt : integer := 0;
	variable init_data : i2c_set_t;
	variable init_done : std_logic;
	begin
		if (rising_edge(pi_clk_50m)) then

			cm_i2c_dev_addr <= pi_switch;

			if (usr_rst = '1') then
				cm_i2c_ce <= '0';
				cm_i2c_we <= '0';
				cm_i2c_reg_addr <= (others => '0');
				cm_i2c_set_value <= (others => '0');
				clk_cnt := 0;
				frm_cnt := 0;
				init_done := '0';
			else
				if (frm_cnt = 0) then
					-- after reset, initialize and void loop for init delay.
					cm_i2c_ce <= '0';
					cm_i2c_we <= '0';
					cm_i2c_reg_addr <= (others => '0');
					cm_i2c_set_value <= (others => '0');
					init_done := '0';

					if (clk_cnt < INIT_DELAY) then
						clk_cnt := clk_cnt + 1;
					else
						clk_cnt := 0;
						frm_cnt := frm_cnt + 1;
					end if;

				elsif (init_done = '0') then
					-- set data.
					-- select data from usr_mode.
					if (usr_mode = "00") then
						init_data := init_data_ov2640(frm_cnt - 1);
					elsif (usr_mode = "01") then
						init_data := init_test_ov2640(frm_cnt - 1);
					elsif (usr_mode = "10") then
						init_data := init_test_ov767x(frm_cnt - 1);
					else
						init_data := init_test_eeprom_24fc(frm_cnt - 1);
					end if;

					if (clk_cnt = 1) then
						cm_i2c_ce <= '1';
						cm_i2c_we <= init_data.we;
					elsif (clk_cnt > I2C_EN_CNT) then
						cm_i2c_ce <= '0';
						cm_i2c_we <= '0';
					end if;

					cm_i2c_reg_addr <= init_data.reg_addr;
					cm_i2c_set_value <= init_data.reg_value;

					if (clk_cnt < init_data.delay_cnt) then
						clk_cnt := clk_cnt + 1;
					else
						clk_cnt := 0;
						frm_cnt := frm_cnt + 1;
					end if;

					if (init_data.we = '0' and init_data.reg_addr = DEV_END_MARKER and init_data.reg_value = DEV_END_MARKER) then
						init_done := '1';
					end if;
				end if;
			end if;
		end if;
	end process;


	counter_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (fpga_rst = '1') then
				vsync_cnt <= (others => '0');
				href_cnt <= (others => '0');
				prev_vsync <= '0';
				prev_href <= '0';
				prev_pclk <= '0';
			else
				if (prev_vsync = '0' and pi_cam_vsync = '1') then
					vsync_cnt <= vsync_cnt + 1;
				end if;

				if (pi_cam_vsync = '1') then
					href_cnt <= (others => '0');
				else
					if (prev_href = '0' and pi_cam_href = '1') then
						href_cnt <= href_cnt + 1;
					end if;
				end if;

				prev_vsync <= pi_cam_vsync;
				prev_href <= pi_cam_href;
			end if;
		end if;
	end process;

	pclk_p : process (pi_cam_pclk)
	begin
		if (rising_edge(pi_cam_pclk)) then
			if (usr_rst = '1') then
					pclk_cnt <= (others => '0');
			else
				if (prev_href = '1') then
					pclk_cnt <= (others => '0');
				else
					pclk_cnt <= pclk_cnt + 1;
				end if;
			end if;
		end if;
	end process;

	cam_rgb_p : process (pi_cam_pclk)
	begin
		if (rising_edge(pi_cam_pclk)) then
			if (usr_rst = '1') then
					cam_r <= (others => '0');
					cam_g <= (others => '0');
					cam_b <= (others => '0');
			else
				if (vsync_cnt(0) = '0') then
					if (pclk_cnt(0) = '0') then
						cam_b <= pi_cam_d;
					else
						cam_g <= pi_cam_d;
					end if;
				else
					if (pclk_cnt(0) = '0') then
						cam_g <= pi_cam_d;
					else
						cam_r <= pi_cam_d;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- input clock is 50mhz
	-- i2c jtag clock is 1/512 of 50mhz
	-- cam jtag clock is 1/2 of 50mhz
	jtag_clk_p : process (pi_clk_50m)
	variable div : unsigned (7 downto 0) := "00000000";
	begin
		if (rising_edge(pi_clk_50m)) then
			div := div + 1;
			jtag_i2c_clk <= div(5);
--			jtag_cam_clk <= div(0);
			jtag_cam_clk <= div(4);
		end if;
	end process;

--	jtag_clk <= jtag_i2c_clk;
	jtag_clk <= jtag_cam_clk;
--	jtag_clk <= pi_clk_50m;


end rtl;
