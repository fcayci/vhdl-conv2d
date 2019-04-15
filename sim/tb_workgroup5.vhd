-- author: Furkan Cayci, 2019
-- description: workgroup with 5 mask size testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity tb_workgroup5 is
end tb_workgroup5;

architecture rtl of tb_workgroup5 is

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
	constant KS          : natural := 5; -- mask size

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

	-- laplacian mask
	-- constant mask : mask5 := (
	-- 	 0,  0, -1,  0,  0,
	-- 	 0, -1, -2, -1,  0,
	-- 	-1, -2, 16, -2, -1,
	-- 	 0, -1, -2, -1,  0,
	-- 	 0,  0, -1,  0,  0
	-- );

	-- sharpen mask
	-- constant mask : mask5 := (
	-- 	 0, -1,  0,
	-- 	-1,  5, -1,
	-- 	 0, -1,  0
	-- );

	-- identity mask
	constant mask : mask5 := (
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 1, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	);

	signal i_pix, o_pix : pixel := (others => '0');
	signal i_active, o_valid : std_logic := '0';

begin

	uut0: entity work.workgroup
		generic map(H=>H, W=>W, KS=>KS)
		port map(clk=>clk, i_active=>i_active, i_pix=>i_pix,
		i_mask=>mask, o_pix=>o_pix, o_valid=>o_valid);

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
		for i in i_img'range loop
			i_pix <= i_img(i);
			wait for clk_period;
		end loop;
		i_active <= '0';
		wait;
	end process;

end rtl;
