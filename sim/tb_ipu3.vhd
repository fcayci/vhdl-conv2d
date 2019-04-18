-- author: Furkan Cayci, 2019
-- description: image processing unit with 3 mask size testbench

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_ipu3 is
end tb_ipu3;

architecture rtl of tb_ipu3 is

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

	signal i_rgb, o_rgb : std_logic_vector(23 downto 0) := (others => '0');
	signal i_active, o_active : std_logic := '0';
	signal i_maskctrl : std_logic_vector(2 downto 0) := "000";

begin


	uut0: entity work.ipu
		--generic map(H=>H, W=>W, KS=>KS)
		port map(clk=>clk, i_maskctrl=>i_maskctrl, i_active=>i_active, i_rgb=>i_rgb,
		o_active=>o_active, o_rgb=>o_rgb);

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
		for i in 1 to H loop
			for j in 1 to W loop
				i_rgb <= std_logic_vector(to_signed(H*i+j,8) & to_signed(H*i+j,8) & to_signed(H*i+j,8));
				wait for clk_period;
			end loop;
		end loop;
		i_active <= '0';
		wait;
	end process;

end rtl;
