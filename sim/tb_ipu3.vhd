-- author: Furkan Cayci, 2019
-- description: image processing unit with 3 mask size testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ipu3 is
end tb_ipu3;

architecture rtl of tb_ipu3 is

	signal clk : std_logic := '1';
	constant clk_period : time := 8 ns;
	constant reset_time : time := 6 * clk_period;
	constant frame_time : time := 49 * clk_period;

	constant RESOLUTION  : string  := "SIM"; -- hd720p, svga, vga, sim
	constant PIXSIZE     : integer := 8; -- pixel size
	constant CHANNEL     : integer := 3; -- number of color channels
	constant SYNCPASS    : boolean := true; -- generate hsync/vsync pass through
	constant H           : natural := 8;  -- from timings
	constant W           : natural := 12; -- from timings
	constant WLINE       : natural := 20; -- from timings
	constant KS          : natural := 3; -- mask size

	signal i_rgb, o_rgb : std_logic_vector(CHANNEL*PIXSIZE-1 downto 0) := (others => '0');
	signal active, o_active : std_logic := '0';
	signal maskctrl : std_logic_vector(2 downto 0) := "001";
	signal hsync, vsync, o_hsync, o_vsync : std_logic := '0';
begin

	uut0: entity work.ipu
		generic map(H=>H, W=>W, WLINE=>WLINE, KS=>KS, PIXSIZE=>PIXSIZE, CHANNEL=>CHANNEL, SYNCPASS=>SYNCPASS)
		port map(clk=>clk, i_maskctrl=>maskctrl,
		i_active=>active, i_hsync=>hsync, i_vsync=>vsync, i_rgb=>i_rgb,
		o_active=>o_active, o_hsync=>o_hsync, o_vsync=>o_vsync, o_rgb=>o_rgb);

	tg_inst: entity work.timing_generator
	generic map(RESOLUTION=>RESOLUTION, GEN_PIX_LOC=>false)
	port map(clk=>clk, hsync=>hsync, vsync=>vsync, video_active=>active, pixel_x=>open, pixel_y=>open);

	-- clock generate
	process
	begin
		--for i in 0 to 2 * frame_time / clk_period loop
			wait for clk_period/2;
			clk <= not clk;
		--end loop;
		--wait;
	end process;

	process(clk)
		variable s : integer range 0 to 255 := 0;
	begin
		if rising_edge(clk) then
			if active = '1' then
				i_rgb <= std_logic_vector(to_unsigned(s,8) & to_unsigned(s,8) & to_unsigned(s,8));
				s := 10 - s;
				-- if s = 255 then
				-- 	s := 0;
				-- else
				-- 	s := s + 1;
				-- end if;
			end if;
		end if;
	end process;

end rtl;
