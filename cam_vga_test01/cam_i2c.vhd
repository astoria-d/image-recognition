library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cam_i2c is 
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
end cam_i2c;

architecture rtl of cam_i2c is

type i2c_status is (
	I2C_IDLE,
	I2C_START,
	I2C_PH1,
	I2C_PH2_W,
	I2C_PH2_R,
	I2C_PH3,
	I2C_PH4,
	I2C_STOP
	);

signal cur_state			: i2c_status;
signal next_state			: i2c_status;
signal i2c_clk_div : unsigned (7 downto 0) := "00000000";
signal out_cnt : unsigned (4 downto 0) := "00001";

begin

	-- input clock is 50mhz (20ns)
	-- i2c clock is max 400khz (2.5us)
	-- i2c_clk_div is 1/256 of pi_clk_50m
	div64_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			i2c_clk_div <= i2c_clk_div + 1;
		end if;
	end process;

	i2c_nxt_stat_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (ce = '1') then
				case cur_state is
				when I2C_IDLE =>
					next_state <= I2C_START;
				when I2C_START =>
					next_state <= I2C_PH1;
				when I2C_PH1 =>
					if (we = '1') then
						next_state <= I2C_PH2_W;
					else
						next_state <= I2C_PH2_R;
					end if;
				when I2C_PH2_W =>
					next_state <= I2C_PH3;
				when I2C_PH2_R =>
					next_state <= I2C_PH3;
				when I2C_PH3 =>
					if (we = '0') then
						next_state <= I2C_PH4;
					else
						next_state <= I2C_STOP;
					end if;
				when others =>
					next_state <= I2C_STOP;
				end case;
			else
				next_state <= I2C_IDLE;
			end if;
		end if;
	end process;

	i2c_cur_stat_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (ce = '1') then
				if i2c_clk_div = "00000000" then
					if next_state = I2C_START then
						cur_state <= next_state;
					elsif next_state = I2C_PH1 then
						cur_state <= next_state;
					elsif next_state = I2C_PH2_W or next_state = I2C_PH2_R or next_state = I2C_PH4 or next_state = I2C_STOP then
						if out_cnt = 18 then
							cur_state <= next_state;
						end if;
					elsif next_state = I2C_PH3 then
						if (we = '1') then
							if out_cnt = 18 then
								cur_state <= next_state;
							end if;
						else
							if out_cnt = 20 then
								cur_state <= next_state;
							end if;
						end if;
					end if;
				end if;
			else
				cur_state <= I2C_IDLE;
			end if;
		end if;
	end process;

	-- out_cnt is 1/512 of pi_clk_50m
	i2c_cnt_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then
			if (cur_state = I2C_IDLE) then
				out_cnt <= "00001";
			else
				if i2c_clk_div = "00000000" then
					if cur_state = I2C_PH2_R then
						if out_cnt < 20 then
							out_cnt <= out_cnt + 1;
						else
							out_cnt <= "00001";
						end if;
					else
						if out_cnt < 18 then
							out_cnt <= out_cnt + 1;
						else
							out_cnt <= "00001";
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	-- scl is 1/512 of pi_clk_50m (97.6KHz)
	i2c_clk_p : process (pi_clk_50m)
	variable stopped : std_logic;
	begin
		if (rising_edge(pi_clk_50m)) then
			if (cur_state = I2C_IDLE) then
				scl <= '1';
			elsif (cur_state = I2C_START) then
				scl <= '1';
				stopped := '0';
			elsif (cur_state = I2C_STOP) then
				if stopped = '0' then
					if (out_cnt > 2) then
						stopped := '1';
					end if;
					scl <= out_cnt(0);
				else
					scl <= '1';
				end if;
			else
				scl <= out_cnt(0);
			end if;
		end if;
	end process;

	i2c_data_p : process (pi_clk_50m)
	variable stopped : std_logic;
	begin
		if (rising_edge(pi_clk_50m)) then
			if (cur_state = I2C_IDLE) then
				sda <= '1';
			else
				if i2c_clk_div = "00000000" then
					if (cur_state = I2C_START) then
						sda <= dev_addr(6);
					elsif (cur_state = I2C_PH1 and out_cnt(0) = '1') then
						if (out_cnt < 15) then
							sda <= dev_addr(to_integer(6 - out_cnt (3 downto 1)));
						elsif (out_cnt = 15) then
							-- write
							sda <= '0';
						else
								-- ack
							sda <= 'Z';
						end if;
					elsif (cur_state = I2C_PH2_W and out_cnt(0) = '1') then
						if (out_cnt < 17) then
							sda <= reg_addr(to_integer(7 - out_cnt (3 downto 1)));
						else
							-- ack
							sda <= 'Z';
						end if;
					elsif (cur_state = I2C_PH2_R and out_cnt(0) = '1') then
						if (out_cnt < 17) then
							sda <= reg_addr(to_integer(7 - out_cnt (3 downto 1)));
						else
							-- ack
							sda <= 'Z';
						end if;
					elsif (cur_state = I2C_PH3 and out_cnt(0) = '1') then
						if (we = '1') then
							if (out_cnt < 17) then
								sda <= set_reg(to_integer(7 - out_cnt (3 downto 1)));
							else
								-- ack
								sda <= 'Z';
							end if;
						else
							if (out_cnt < 15) then
								sda <= dev_addr(to_integer(6 - out_cnt (3 downto 1)));
							elsif (out_cnt = 15) then
								-- read
								sda <= '1';
							else
								-- ack
								sda <= 'Z';
							end if;
						end if;
					elsif (cur_state = I2C_PH4 and out_cnt(0) = '1') then
						if (out_cnt = 17) then
							-- nack
							sda <= '1';
						else
							-- read
							sda <= 'Z';
						end if;
					elsif (cur_state = I2C_STOP and out_cnt(0) = '1') then
						if (out_cnt = 1) then
							stopped := '1';
							sda <= '0';
						end if;
					end if;
				elsif i2c_clk_div = "10000000" then
					if (cur_state = I2C_START and out_cnt(0) = '1') then
						-- start bit
						sda <= '0';
						stopped := '0';
					elsif (cur_state = I2C_PH2_R and out_cnt = 20) then
						-- prepare start after ph2_r
						sda <= '1';
					elsif (cur_state = I2C_PH3 and out_cnt = 1 and we = '0') then
						-- start bit of ph3
						sda <= '0';
					elsif (cur_state = I2C_STOP and out_cnt(0) = '1') then
						-- stop bit
						if stopped = '1' then
							sda <= '1';
						end if;
					end if;
				end if;
			end if;
		end if;
	end process;

	i2c_read_p : process (pi_clk_50m)
	begin
		if (rising_edge(pi_clk_50m)) then

			if (cur_state = I2C_PH4 and i2c_clk_div = "00000000" and out_cnt < 17 and we = '0') then
				if (out_cnt (3 downto 1) > 0) then
					read_reg(to_integer(8 - out_cnt (3 downto 1))) <= sda;
				else
					read_reg(0) <= sda;
				end if;
			end if;

		end if;
	end process;

end rtl;
