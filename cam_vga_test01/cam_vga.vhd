library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cam_vga is
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
end cam_vga;

architecture rtl of cam_vga is

signal vga_h_cnt 			: integer range 0 to 800 - 1 := 0;
signal vga_v_cnt 			: integer range 0 to 540 - 1 := 0;
signal cm_h_cnt 		: integer range 0 to 1922 - 1 := 0;
signal cm_v_cnt 		: integer range 0 to 1248 - 1 := 0;

signal cm_r				: std_logic_vector(4 downto 0);
signal cm_g				: std_logic_vector(4 downto 0);
signal cm_b				: std_logic_vector(4 downto 0);


begin

	-- cam cnt
	cam_hcnt_p : process (pi_cam_pclk)
	begin
		if (rising_edge(pi_cam_pclk)) then
			-- it looks like spec is opposite.
			-- vsync is active high?
			if (pi_cam_vsync = '0') then
				cm_h_cnt <= 0;
			else
				if (pi_cam_href = '0') then
					cm_h_cnt <= 0;
				elsif (cm_h_cnt < 1922 - 1) then
					if (to_unsigned(cm_v_cnt, 10)(0) = '0') then
						if (to_unsigned(cm_h_cnt, 10)(0) = '0') then
							cm_b <= pi_cam_d(7 downto 3);
						else
							cm_g <= pi_cam_d(7 downto 3);
						end if;
					else
						if (to_unsigned(cm_h_cnt, 10)(0) = '0') then
							cm_g <= pi_cam_d(7 downto 3);
						else
							cm_r <= pi_cam_d(7 downto 3);
						end if;
					end if;
					cm_h_cnt <= cm_h_cnt + 1;
				end if;
			end if;
		end if;
	end process;

	cam_vcnt_p : process (pi_cam_pclk)
	variable href_prev : std_logic := '0';
	begin
		if (rising_edge(pi_cam_pclk)) then
			if (pi_cam_vsync = '0') then
				cm_v_cnt <= 0;
			else
				if (href_prev = '1' and pi_cam_href = '0') then
					if (cm_v_cnt < 1248 - 1) then
						cm_v_cnt <= cm_v_cnt + 1;
					else
						cm_v_cnt <= 0;
					end if;
				end if;
			end if;
			href_prev := pi_cam_href;
		end if;
	end process;

	-- vga output
	vga_cnt_p : process (pi_clk_50m)
	variable div_25 : std_logic := '0';
	begin
		if (rising_edge(pi_clk_50m)) then
			if (usr_rst = '1') then
				vga_h_cnt <= 0;
				vga_v_cnt <= 0;
				div_25 := '0';
			else
				-- input clock is 50mhz
				-- vga 640 x 480 pixel rate is 25mhz
				-- divide half
				div_25 := not div_25;
				if (div_25 = '1') then
--					if (h_cnt = h_cnt'high) then
--modelsim fails with 'high
					if (vga_h_cnt = 800 - 1) then
						vga_h_cnt <= 0;
--						if (v_cnt = v_cnt'high) then
						if (vga_v_cnt = 540 - 1) then
							vga_v_cnt <= 0;
						else
							vga_v_cnt <= vga_v_cnt + 1;
						end if;
					else
						vga_h_cnt <= vga_h_cnt + 1;
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
				if (vga_h_cnt < 96) then
					po_h_sync_n <= '0';
				else
					po_h_sync_n <= '1';
				end if;

				if (vga_v_cnt < 2) then
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
				if (vga_v_cnt >= 2 + 33 and vga_v_cnt < 2 + 33 + 480) then
					if (vga_h_cnt >= 96 + 48 and vga_h_cnt < 96 + 48 + 640) then

--						po_r <= "00" & pi_cam_y(1 downto 0);
--						po_g <= pi_cam_d(7 downto 4);
--						po_b <= pi_cam_d(3 downto 0);

						po_r <= cm_r(4 downto 1);
						po_g <= cm_g(4 downto 1);
						po_b <= cm_b(4 downto 1);
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

end rtl;
