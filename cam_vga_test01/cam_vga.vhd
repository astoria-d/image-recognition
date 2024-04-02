library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cam_vga is
	port (
		-- input clock 50 mhz
		pi_clk_50m,

		-- user reset signal
		usr_rst 			: std_logic;

		-- camera data interface
		cam_r				: in std_logic_vector(4 downto 0);
		cam_g				: in std_logic_vector(5 downto 0);
		cam_b				: in std_logic_vector(4 downto 0);

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

--	RGB565
signal cm_r				: std_logic_vector(4 downto 0);
signal cm_g				: std_logic_vector(5 downto 0);
signal cm_b				: std_logic_vector(4 downto 0);


begin

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
						po_r <= cam_r(4 downto 1);
						po_g <= cam_g(5 downto 2);
						po_b <= cam_b(4 downto 1);
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
