-- author: Furkan Cayci, 2019
-- description: module to store and distribute incoming pixel/masks to convolution

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity workgroup is
	generic(
		PIXSIZE : integer := 8; -- pixel size
		H  : integer := 720; -- height of image
		W  : integer := 1280; -- width of image
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		clk      : in  std_logic;
		i_active : in  std_logic; -- input active signal
		i_pix    : in  pixel; --  input pixel data
		i_mask   : in  mask_array(0 to KS**2-1); -- 3x3 mask
		o_pix    : out pixel; -- output pixel data
		o_valid  : out std_logic -- output valid signal (for writing to a FIFO)
	);
	-- attribute gated_clock : string;
	-- attribute gated_clock of clk : signal is "false";
end workgroup;

architecture rtl of workgroup is
	-- this will hold the first {mask size} rows
	--signal rows : pixel_array(0 to ((KS-1) * W) + KS-1) := (others =>(others=>'0'));
	signal row1: pixel_array(0 to W-KS-1) := (others => (others => '0'));
	signal row2: pixel_array(0 to W-KS-1) := (others => (others => '0'));
	-- type ram_type is array(0 to ((KS-1) * W) + KS-1) of pixel;
	-- signal rows1, rows2 : ram_type;
	-- attribute ram_style : string;
	-- attribute ram_style of rows : signal is "block";
	-- attribute shreg_extract : string;
	-- attribute shreg_extract of rows : signal is "yes";
	-- attribute srl_style : string;
	-- attribute srl_style of rows : signal is "srl";

	-- window to be convoluted
	signal window : pixel_array(0 to KS**2-1) := (others => (others => '0'));
	signal winbuf1, winbuf2, winbuf3 : pixel_array(0 to KS-1) := (others => (others => '0'));

	-- mask to be convoluted
	signal mask : mask_array(0 to KS**2-1) := (others => 0 );

	-- delay enable signal
	-- it is {mask size-1 / 2} row big + {mask size-1 / 2} pixel for extra padding
	-- for mask size = 3; 1 row + 1 pixel
	-- for mask size = 5; 2 rows + 2 pixels
	signal enable : std_logic_vector((KS-1)/2*(W+1) downto 0) := (others => '0');
	signal window_count : std_logic_vector(KS-1 downto 0) := "000"; -- fixme: make it changable

begin

	process(clk) is
	begin
		if rising_edge(clk) then
			if i_active = '1' then
				winbuf1 <= winbuf1(1 to winbuf1'high) & i_pix;
				row1 <= row1(1 to row1'high) & winbuf1(0);
				winbuf2 <= winbuf2(1 to winbuf2'high) & row1(0);
				row2 <= row2(1 to row2'high) & winbuf2(0);
				winbuf3 <= winbuf3(1 to winbuf3'high) & row2(0);
			end if;
		end if;
	end process;

	-- shift register that is one row big
	-- to delay the frame for a single row (both beginning and end)
	process(clk) is
	begin
		if rising_edge(clk) then
			if i_active = '1' then
				enable <= enable(enable'high-1 downto 0) & '1';
			else
				enable <= enable(enable'high-1 downto 0) & '0';
			end if;
		end if;
	end process;

	-- buffer mask
	process(clk) is
	begin
		if rising_edge(clk) then
			mask <= i_mask;
		end if;
	end process;

	-- 2d convolution
	c2d: entity work.convolution2d(rtl)
	generic map (PIXSIZE=>PIXSIZE, KS=>KS)
	port map (clk=>clk, i_enable=>enable(enable'high),
		i_window=>window, i_mask=>mask, o_pix=>o_pix,
		o_valid=>o_valid);

	-- assign window
	-- auto generate based on the KS size
	-- w_gen: for i in 0 to KS-1 generate
	-- begin
	-- 	window(i*KS to i*KS + KS-1) <= rows(i*W to i*W + KS-1);
	-- end generate;

	window <= winbuf3 & winbuf2 & winbuf1;

end rtl;
