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
	po_svn_seg0		: out std_logic_vector(6 downto 0);
	po_svn_seg1		: out std_logic_vector(6 downto 0);
	po_svn_seg2		: out std_logic_vector(6 downto 0);
	po_svn_seg3		: out std_logic_vector(6 downto 0);
	po_svn_seg4		: out std_logic_vector(6 downto 0);
	po_svn_seg5		: out std_logic_vector(6 downto 0);

	--logic analyzer reference clock
	jtag_clk		: out std_logic
);
end cam_vga_test01;

architecture rtl of cam_vga_test01 is

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

component PLL
	port (
		refclk   : in  std_logic := '0'; --  refclk.clk
		rst      : in  std_logic := '0'; --   reset.reset
		outclk_0 : out std_logic;        -- outclk0.clk
		locked   : out std_logic         --  locked.export
	);
end component;

type i2c_set_t is
record
	we		 : std_logic;
	dev_addr : std_logic_vector(6 downto 0);
	reg_addr : std_logic_vector(7 downto 0);
	reg_value : std_logic_vector(7 downto 0);
end record;

constant I2C_FRM_CNT : integer := 6400 * 4;
constant I2C_SET_CNT : integer := 175;

constant DEV_END_MARKER : std_logic_vector(6 downto 0) := "0000000";

type i2c_init_array is array (0 to I2C_SET_CNT - 1) of i2c_set_t;

constant i2c_init_data_set : i2c_init_array := (
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#ff#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#2e#, 8)), std_logic_vector(to_unsigned(16#df#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#3c#, 8)), std_logic_vector(to_unsigned(16#32#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#11#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#09#, 8)), std_logic_vector(to_unsigned(16#02#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#04#, 8)), std_logic_vector(to_unsigned(16#28#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#13#, 8)), std_logic_vector(to_unsigned(16#e5#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#14#, 8)), std_logic_vector(to_unsigned(16#48#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#2c#, 8)), std_logic_vector(to_unsigned(16#0c#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#78#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#3a#, 8)), std_logic_vector(to_unsigned(16#33#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#3b#, 8)), std_logic_vector(to_unsigned(16#fB#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#3e#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#11#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#16#, 8)), std_logic_vector(to_unsigned(16#10#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#39#, 8)), std_logic_vector(to_unsigned(16#92#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#35#, 8)), std_logic_vector(to_unsigned(16#da#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#22#, 8)), std_logic_vector(to_unsigned(16#1a#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#37#, 8)), std_logic_vector(to_unsigned(16#c3#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#23#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#34#, 8)), std_logic_vector(to_unsigned(16#c0#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#36#, 8)), std_logic_vector(to_unsigned(16#1a#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#06#, 8)), std_logic_vector(to_unsigned(16#88#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#07#, 8)), std_logic_vector(to_unsigned(16#c0#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#0d#, 8)), std_logic_vector(to_unsigned(16#87#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#0e#, 8)), std_logic_vector(to_unsigned(16#41#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#48#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5B#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#42#, 8)), std_logic_vector(to_unsigned(16#03#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#4a#, 8)), std_logic_vector(to_unsigned(16#81#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#21#, 8)), std_logic_vector(to_unsigned(16#99#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#24#, 8)), std_logic_vector(to_unsigned(16#40#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#25#, 8)), std_logic_vector(to_unsigned(16#38#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#26#, 8)), std_logic_vector(to_unsigned(16#82#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#63#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#46#, 8)), std_logic_vector(to_unsigned(16#22#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#0c#, 8)), std_logic_vector(to_unsigned(16#3c#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#61#, 8)), std_logic_vector(to_unsigned(16#70#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#62#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#05#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#20#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#28#, 8)), std_logic_vector(to_unsigned(16#30#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#6c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#6d#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#6e#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#70#, 8)), std_logic_vector(to_unsigned(16#02#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#71#, 8)), std_logic_vector(to_unsigned(16#94#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#73#, 8)), std_logic_vector(to_unsigned(16#c1#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#40#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#17#, 8)), std_logic_vector(to_unsigned(16#11#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#18#, 8)), std_logic_vector(to_unsigned(16#43#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#19#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#1a#, 8)), std_logic_vector(to_unsigned(16#4b#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#32#, 8)), std_logic_vector(to_unsigned(16#09#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#37#, 8)), std_logic_vector(to_unsigned(16#c0#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#4f#, 8)), std_logic_vector(to_unsigned(16#ca#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#a8#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#23#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#6d#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#3d#, 8)), std_logic_vector(to_unsigned(16#38#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#7f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#f9#, 8)), std_logic_vector(to_unsigned(16#c0#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#41#, 8)), std_logic_vector(to_unsigned(16#24#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#14#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#76#, 8)), std_logic_vector(to_unsigned(16#ff#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#33#, 8)), std_logic_vector(to_unsigned(16#a0#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#42#, 8)), std_logic_vector(to_unsigned(16#20#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#43#, 8)), std_logic_vector(to_unsigned(16#18#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#4c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#87#, 8)), std_logic_vector(to_unsigned(16#d5#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#88#, 8)), std_logic_vector(to_unsigned(16#3f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#d7#, 8)), std_logic_vector(to_unsigned(16#03#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#d9#, 8)), std_logic_vector(to_unsigned(16#10#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#82#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c8#, 8)), std_logic_vector(to_unsigned(16#08#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c9#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#03#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#48#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7c#, 8)), std_logic_vector(to_unsigned(16#08#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#20#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#10#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7d#, 8)), std_logic_vector(to_unsigned(16#0e#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#90#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#0e#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#1a#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#31#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#5a#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#69#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#75#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#7e#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#88#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#8f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#96#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#a3#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#af#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#c4#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#d7#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#e8#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#91#, 8)), std_logic_vector(to_unsigned(16#20#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#92#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#06#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#e3#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#05#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#05#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#04#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#93#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#96#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#08#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#19#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#0c#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#24#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#30#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#28#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#26#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#02#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#98#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#97#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c3#, 8)), std_logic_vector(to_unsigned(16#ed#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#a4#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#a8#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c5#, 8)), std_logic_vector(to_unsigned(16#11#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c6#, 8)), std_logic_vector(to_unsigned(16#51#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#bf#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c7#, 8)), std_logic_vector(to_unsigned(16#10#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b6#, 8)), std_logic_vector(to_unsigned(16#66#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b8#, 8)), std_logic_vector(to_unsigned(16#A5#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b7#, 8)), std_logic_vector(to_unsigned(16#64#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b9#, 8)), std_logic_vector(to_unsigned(16#7C#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b3#, 8)), std_logic_vector(to_unsigned(16#af#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b4#, 8)), std_logic_vector(to_unsigned(16#97#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b5#, 8)), std_logic_vector(to_unsigned(16#FF#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b0#, 8)), std_logic_vector(to_unsigned(16#C5#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b1#, 8)), std_logic_vector(to_unsigned(16#94#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#b2#, 8)), std_logic_vector(to_unsigned(16#0f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c4#, 8)), std_logic_vector(to_unsigned(16#5c#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c0#, 8)), std_logic_vector(to_unsigned(16#64#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c1#, 8)), std_logic_vector(to_unsigned(16#4B#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#8c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#86#, 8)), std_logic_vector(to_unsigned(16#3D#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#50#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#51#, 8)), std_logic_vector(to_unsigned(16#C8#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#52#, 8)), std_logic_vector(to_unsigned(16#96#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#53#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#54#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#55#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5a#, 8)), std_logic_vector(to_unsigned(16#C8#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5b#, 8)), std_logic_vector(to_unsigned(16#96#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#5c#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#d3#, 8)), std_logic_vector(to_unsigned(16#82#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#c3#, 8)), std_logic_vector(to_unsigned(16#ed#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#7f#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#da#, 8)), std_logic_vector(to_unsigned(16#08#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#e5#, 8)), std_logic_vector(to_unsigned(16#1f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#e1#, 8)), std_logic_vector(to_unsigned(16#67#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#e0#, 8)), std_logic_vector(to_unsigned(16#00#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#dd#, 8)), std_logic_vector(to_unsigned(16#7f#, 8))),
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#05#, 8)), std_logic_vector(to_unsigned(16#00#, 8)))
);


type i2c_init_array_chk is array (0 to 3) of i2c_set_t;

constant i2c_init_data_set_chk : i2c_init_array_chk := (
-- ov2640
	('1', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8))),
	('0', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#0a#, 8)), "ZZZZZZZZ"),
	('0', std_logic_vector(to_unsigned(16#30#, 7)) ,std_logic_vector(to_unsigned(16#0b#, 8)), "ZZZZZZZZ"),
	('0', DEV_END_MARKER ,"00000000", "ZZZZZZZZ")

-- ov7670
-- ov7675
--	('1', std_logic_vector(to_unsigned(16#21#, 7)) ,std_logic_vector(to_unsigned(16#12#, 8)), std_logic_vector(to_unsigned(16#80#, 8))),
--	('0', std_logic_vector(to_unsigned(16#21#, 7)) ,std_logic_vector(to_unsigned(16#01#, 8)), "ZZZZZZZZ"),
--	('0', std_logic_vector(to_unsigned(16#21#, 7)) ,std_logic_vector(to_unsigned(16#09#, 8)), "ZZZZZZZZ")


-- 24FC256 EEPROM
--	('1', std_logic_vector(to_unsigned(16#50#, 7)) ,std_logic_vector(to_unsigned(16#ff#, 8)), std_logic_vector(to_unsigned(16#01#, 8))),
--	('0', std_logic_vector(to_unsigned(16#50#, 7)) ,std_logic_vector(to_unsigned(16#1c#, 8)), "ZZZZZZZZ"),
--	('0', std_logic_vector(to_unsigned(16#50#, 7)) ,std_logic_vector(to_unsigned(16#1d#, 8)), "ZZZZZZZZ")
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

signal h_cnt 					: integer range 0 to 800 - 1 := 0;
signal v_cnt 					: integer range 0 to 540 - 1 := 0;

signal cm_i2c_ce				: std_logic;
signal cm_i2c_we				: std_logic;
signal cm_i2c_dev_addr		: std_logic_vector(6 downto 0) := "0000000";
signal cm_i2c_reg_addr		: std_logic_vector(7 downto 0);
signal cm_i2c_set_value		: std_logic_vector(7 downto 0);
signal cm_i2c_read_value	: std_logic_vector(7 downto 0);

signal fpga_rst 				: std_logic;
signal usr_rst 				: std_logic;
signal tmp_cam_clk 			: std_logic;
signal pll_locked 			: std_logic;

signal usr_mode 				: unsigned(1 downto 0) := "00";

begin

	fpga_rst <= not pi_rst_n;
	usr_rst <= not pi_btn(0);
	po_cam_rst <= '1';
	po_cam_pwdn <= '0';
	po_cam_xvclk <= tmp_cam_clk;

	-- i2c encoder
	cm_i2c_inst : cam_i2c port map (
		pi_clk_50m,
		cm_i2c_ce, cm_i2c_we, cm_i2c_dev_addr, cm_i2c_reg_addr, cm_i2c_set_value, cm_i2c_read_value, 
		po_cam_scl, pio_cam_sda);

	-- PLL 24 MHz for ov2640 system clock
	pll_inst : PLL port map (
		pi_clk_50m,
		fpga_rst,
		tmp_cam_clk,
		pll_locked);

	-- i2c device address mode
	mode_p : process (pi_clk_50m)
	variable btn_prev : std_logic;
	begin
		if (rising_edge(pi_clk_50m)) then

			if (fpga_rst = '1') then
				usr_mode <= (others => '0');
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
			if (fpga_rst = '1') then
				po_svn_seg0 <= (others => '1');
			else
				po_svn_seg0 <= hex_to_7seg(usr_mode);
			end if;
		end if;
	end process;

	addr_seg_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (fpga_rst = '1') then
				po_svn_seg2 <= (others => '1');
				po_svn_seg3 <= (others => '1');
			else
				po_svn_seg2 <= hex_to_7seg(pi_switch(3 downto 0));
				po_svn_seg3 <= hex_to_7seg(pi_switch(6 downto 4));
			end if;
		end if;
	end process;

	po_svn_seg1 <= (others => '1');
	po_svn_seg4 <= (others => '1');
	po_svn_seg5 <= (others => '1');


	-- initialize camera
	cam_set_p : process (pi_clk_50m)
	variable frm_cnt : integer := 0;
	variable clk_cnt : integer := 0;
	--5msec delay for 50Mhz
--	constant DELAY_5MS : integer := 250000;
	constant DELAY_5MS : integer := 2500;
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
			else
				if (frm_cnt = 0) then
					cm_i2c_ce <= '0';
					cm_i2c_we <= '0';
					cm_i2c_reg_addr <= (others => '0');
					cm_i2c_set_value <= (others => '0');

					-- after reset, delay 5ms.
					if (clk_cnt < DELAY_5MS) then
						clk_cnt := clk_cnt + 1;
					else
						clk_cnt := 0;
						frm_cnt := frm_cnt + 1;
					end if;

--				elsif (frm_cnt < I2C_SET_CNT + 1) then
				elsif (frm_cnt < 3 + 1) then
					if (clk_cnt = 1) then
						cm_i2c_ce <= '1';
						cm_i2c_we <= i2c_init_data_set_chk(frm_cnt - 1).we;
					elsif (clk_cnt > 5000 * 4) then
						cm_i2c_ce <= '0';
						cm_i2c_we <= '0';
					end if;

					cm_i2c_reg_addr <= i2c_init_data_set_chk(frm_cnt - 1).reg_addr;
					cm_i2c_set_value <= i2c_init_data_set_chk(frm_cnt - 1).reg_value;

					if (clk_cnt < I2C_FRM_CNT) then
						clk_cnt := clk_cnt + 1;
					else
						clk_cnt := 0;
						frm_cnt := frm_cnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- vga output
	vga_cnt_p : process (pi_clk_50m)
	variable div_25 : std_logic := '0';
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				h_cnt <= 0;
				v_cnt <= 0;
				div_25 := '0';
			else
				-- input clock is 50mhz
				-- vga 640 x 480 pixel rate is 25mhz
				-- divide half
				div_25 := not div_25;
				if (div_25 = '1') then
--					if (h_cnt = h_cnt'high) then
--modelsim fails with 'high
					if (h_cnt = 800 - 1) then
						h_cnt <= 0;
--						if (v_cnt = v_cnt'high) then
						if (v_cnt = 540 - 1) then
							v_cnt <= 0;
						else
							v_cnt <= v_cnt + 1;
						end if;
					else
						h_cnt <= h_cnt + 1;
					end if;
				end if;
			end if;
		end if;
	end process;

	vga_sync_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				po_h_sync_n <= '0';
				po_v_sync_n <= '0';
			else
				if (h_cnt < 96) then
					po_h_sync_n <= '0';
				else
					po_h_sync_n <= '1';
				end if;

				if (v_cnt < 2) then
					po_v_sync_n <= '0';
				else
					po_v_sync_n <= '1';
				end if;
			end if;
		end if;
	end process;

	vga_out_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				po_r <= (others => '0');
				po_g <= (others => '0');
				po_b <= (others => '0');
			else
				if (v_cnt >= 2 + 33 and v_cnt < 2 + 33 + 480) then
					if (h_cnt >= 96 + 48 and h_cnt < 96 + 48 + 640) then
--						po_r <= std_logic_vector(to_unsigned(h_cnt, po_r'length));
						po_r <= cm_i2c_read_value(7 downto 4);
						po_g <= cm_i2c_read_value(3 downto 0);
						po_b <= pi_cam_d(3 downto 0);
						--po_b <= std_logic_vector(to_unsigned(v_cnt, po_b'length));
					else
						po_r <= (others => '0');
						po_g <= (others => '0');
						po_b <= (others => '0');
					end if;
				else
					po_r <= (others => '0');
					po_g <= (others => '0');
					po_b <= (others => '0');
				end if;
			end if;
		end if;
	end process;

	-- jtag clock
	jtag_clk_p : process (pi_clk_50m)
	variable div : unsigned (7 downto 0) := "00000000";
	begin
		if (rising_edge(pi_clk_50m)) then
			div := div + 1;
			jtag_clk <= div(5);
		end if;
	end process;


end rtl;
