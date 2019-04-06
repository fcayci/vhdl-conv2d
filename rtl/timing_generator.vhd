-- author: Furkan Cayci, 2019
-- description: video timing generator
--   choose between hd720p, svga, vga
--     and sim for debug purposes

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timing_generator is
	generic (
		RESOLUTION   : string  := "HD720P"; -- hd720p, svga, vga
		GEN_PIX_LOC  : boolean := true
	);
	port(
		clk           : in  std_logic;
		hsync, vsync  : out std_logic;
		video_active  : out std_logic;
		pixel_x       : out std_logic_vector(15 downto 0);
		pixel_y       : out std_logic_vector(15 downto 0)
	);
end timing_generator;

architecture rtl of timing_generator is

	type video_timing_type is record
		H_VIDEO : integer;
		H_FP    : integer;
		H_SYNC  : integer;
		H_BP    : integer;
		H_TOTAL : integer;
		V_VIDEO : integer;
		V_FP    : integer;
		V_SYNC  : integer;
		V_BP    : integer;
		V_TOTAL : integer;
		H_POL   : std_logic;
		V_POL   : std_logic;
		ACTIVE  : std_logic;
	end record;

-- HD720p timing
--      screen area 1280x720 @60 Hz
--      horizontal : 1280 visible + 72 front porch (fp) + 80 hsync + 216 back porch = 1648 pixels
--      vertical   :  720 visible +  3 front porch (fp) +  5 vsync +  22 back porch =  750 pixels
--      Total area 1648x750
--      clk input should be 74.25 MHz signal (1650 * 750 * 60)
--      hsync and vsync are positive polarity

	constant HD720P_TIMING : video_timing_type := (
		H_VIDEO => 1280,
		H_FP    =>   72,
		H_SYNC  =>   80,
		H_BP    =>  216,
		H_TOTAL => 1648,
		V_VIDEO =>  720,
		V_FP    =>    3,
		V_SYNC  =>    5,
		V_BP    =>   22,
		V_TOTAL =>  750,
		H_POL   =>  '1',
		V_POL   =>  '1',
		ACTIVE  =>  '1'
	);

-- SVGA timing
--      screen area 800x600 @60 Hz
--      horizontal : 800 visible + 40 front porch (fp) + 128 hsync + 88 back porch = 1056 pixels
--      vertical   : 600 visible +  1 front porch (fp) +   4 vsync + 23 back porch =  628 pixels
--      Total area 1056x628
--      clk input should be 40 MHz signal (1056 * 628 * 60)
--      hsync and vsync are positive polarity

	constant SVGA_TIMING : video_timing_type := (
		H_VIDEO =>  800,
		H_FP    =>   40,
		H_SYNC  =>  128,
		H_BP    =>   88,
		H_TOTAL => 1056,
		V_VIDEO =>  600,
		V_FP    =>    1,
		V_SYNC  =>    4,
		V_BP    =>   23,
		V_TOTAL =>  628,
		H_POL   =>  '1',
		V_POL   =>  '1',
		ACTIVE  =>  '1'
	);

-- VGA timing
--      screen area 640x480 @60 Hz
--      horizontal : 640 visible + 16 front porch (fp) + 96 hsync + 48 back porch = 800 pixels
--      vertical   : 480 visible + 10 front porch (fp) +  2 vsync + 33 back porch = 525 pixels
--      Total area 800x525
--      clk input should be 25 MHz signal (800 * 525 * 60)
--      hsync and vsync are negative polarity

	constant VGA_TIMING : video_timing_type := (
		H_VIDEO =>  640,
		H_FP    =>   16,
		H_SYNC  =>   96,
		H_BP    =>   48,
		H_TOTAL =>  800,
		V_VIDEO =>  480,
		V_FP    =>   10,
		V_SYNC  =>    2,
		V_BP    =>   33,
		V_TOTAL =>  525,
		H_POL   =>  '0',
		V_POL   =>  '0',
		ACTIVE  =>  '1'
	);


-- Simulation timing
--      screen area 12x8
--      horizontal : 12 visible + 2 front porch (fp) + 4 hsync + 2 back porch = 20 pixels
--      vertical   :  8 visible + 1 front porch (fp) + 2 vsync + 1 back porch = 12 pixels
--      Total area 20x12

constant SIM_TIMING : video_timing_type := (
	H_VIDEO =>  12,
	H_FP    =>   2,
	H_SYNC  =>   4,
	H_BP    =>   2,
	H_TOTAL =>  20,
	V_VIDEO =>   8,
	V_FP    =>   1,
	V_SYNC  =>   2,
	V_BP    =>   1,
	V_TOTAL =>  12,
	H_POL   =>  '1',
	V_POL   =>  '1',
	ACTIVE  =>  '1'
);

	-- horizontal and vertical counters
	signal hcount : unsigned(15 downto 0) := (others => '0');
	signal vcount : unsigned(15 downto 0) := (others => '0');
	signal timings : video_timing_type := HD720P_TIMING;

begin

	timings <= HD720P_TIMING when RESOLUTION = "HD720P" else
	           SVGA_TIMING   when RESOLUTION = "SVGA"   else
	           VGA_TIMING    when RESOLUTION = "VGA"    else
	           SIM_TIMING    when RESOLUTION = "SIM";

	-- pixel counters
	process (clk) is
	begin
		if rising_edge(clk) then
			if (hcount = timings.H_TOTAL) then
				hcount <= (others => '0');
				if (vcount = timings.V_TOTAL) then
					vcount <= (others => '0');
				else
					vcount <= vcount + 1;
				end if;
			else
				hcount <= hcount + 1;
			end if;
		end if;
	end process;

	-- generate video_active, hsync, and vsync signals based on the counters
	video_active <= timings.ACTIVE when (hcount < timings.H_VIDEO) and (vcount < timings.V_VIDEO ) else not timings.ACTIVE;
	hsync <= timings.H_POL when (hcount >= timings.H_VIDEO + timings.H_FP) and (hcount < timings.H_TOTAL - timings.H_BP) else not timings.H_POL;
	vsync <= timings.V_POL when (vcount >= timings.V_VIDEO + timings.V_FP) and (vcount < timings.V_TOTAL - timings.V_BP) else not timings.V_POL;

	g0: if GEN_PIX_LOC = true generate
	begin
		-- send pixel locations
		pixel_x <= std_logic_vector(hcount) when hcount < timings.H_VIDEO else (others => '0');
		pixel_y <= std_logic_vector(vcount) when vcount < timings.V_VIDEO else (others => '0');
	end generate;

	g1: if GEN_PIX_LOC = false generate
	begin
		-- send pixel locations
		pixel_x <= (others => '0');
		pixel_y <= (others => '0');
	end generate;
end rtl;