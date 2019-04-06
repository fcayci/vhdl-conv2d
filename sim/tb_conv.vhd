-- author: Furkan Cayci, 2019
-- description: workgroup testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity tb_conv is
end tb_conv;

architecture rtl of tb_conv is

	signal clk : std_logic := '1';
	--signal rst : std_logic := '0';
	constant clk_period : time := 8 ns;
	constant reset_time : time := 6 * clk_period;
	constant frame_time : time := 49 * clk_period;

	-- interface ports / generics
	-- enable GHDL simulation support
	-- set this to false when using Vivado
	--   OSERDESE2 is normally used for 7-series
	--   but since it is encrypted, GHDL cannot simulate it
	--   Thus, this will downgrade it to OSERDESE1
	--   for simulation under GHDL
	constant SERIES6     : boolean := false;    -- use OSERDES1/2
	constant RESOLUTION  : string  := "SIM";    -- HD720P, SVGA, VGA, SIM
	constant GEN_PIX_LOC : boolean := true;     -- generate location counters for x / y coordinates
	constant PIXEL_SIZE  : natural := 24;       -- RGB pixel total size. (R + G + B)
	constant H           : natural := 8;
	constant W           : natural := 10;
	constant KS          : natural := 3; -- mask size

	constant i_img : pixel_array(0 to 79) := (
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A"
	);

	-- edge mask
	constant mask : mask3 := (
		-1, -1, -1,
		-1,  8, -1,
		-1, -1, -1
	);

	-- sharpen mask
	-- constant mask : mask3 := (
	-- 	 0, -1,  0,
	-- 	-1,  5, -1,
	-- 	 0, -1,  0
	-- );

	-- identity mask
	-- constant mask : mask3 := (
	-- 	0, 0, 0,
	-- 	0, 1, 0,
	-- 	0, 0, 0
	-- );

	signal o_img : pixel_array(0 to 24) := (others => (others => '0'));
	signal i_rgb, o_rgb : pixel := (others => '0');
	signal i_active, o_active : std_logic := '0';

begin

	uut0: entity work.workgroup
	  generic map(H=>H, W=>W)
	  port map(clk=>clk, i_active=>i_active, i_rgb=>i_rgb,
	    i_mask=>mask, o_rgb=>o_rgb, o_active=>o_active);

	-- clock generate
	process
	begin
		--for i in 0 to 2 * frame_time / clk_period loop
			wait for clk_period/2;
			clk <= not clk;
		--end loop;
		--wait;
	end process;

	process
	begin
		i_active <= '0';
		wait for reset_time;
		i_active <= '1';
		for i in 0 to i_img'length-1 loop
			i_rgb <= i_img(i);
			wait for clk_period;
		end loop;
		i_active <= '0';
		wait;
	end process;

end rtl;
