-- author: Furkan Cayci, 2019
-- description: module to store and distribute incoming pixel/masks to convolution

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity workgroup is
	generic(
		PIXSIZE : integer := 8; -- pixel size
		MAXWBITS : integer := 12; -- max number of bits for width
		H  : integer := 720; -- height of image
		W  : integer := 1280; -- width of image
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		clk      : in  std_logic;
		i_hcounter : in unsigned(MAXWBITS-1 downto 0);
		i_active : in  std_logic; -- input active signal
		i_pix    : in  pixel; --  input pixel data
		i_mask   : in  mask_array(0 to KS**2-1); -- 3x3 mask
		o_pix    : out pixel -- output pixel data
	);
	-- attribute gated_clock : string;
	-- attribute gated_clock of clk : signal is "false";
end workgroup;

architecture rtl of workgroup is
	-- this will hold the first {mask size} rows
	signal rows : pixel_array(0 to ((KS-1) * W) + KS-1) := (others =>(others=>'0'));
	signal row1: pixel_array(0 to W-KS-1) := (others => (others => '0'));
	signal row2: pixel_array(0 to W-KS-1) := (others => (others => '0'));

	-- window to be convoluted
	signal window : pixel_array(0 to KS**2-1) := (others => (others => '0'));
	signal winbuf1, winbuf2, winbuf3 : pixel_array(0 to KS-1) := (others => (others => '0'));

	-- mask to be convoluted
	signal mask : mask_array(0 to KS**2-1) := (others => 0 );

	signal validrow,enable : std_logic := '0';
	-- signal enable : std_logic_vector(KS-2 downto 0) := (others=>'0');

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

	-- do not enable for top and bottom rows
	process(clk) is
	begin
		if rising_edge(clk) then
			if i_hcounter <= (KS-1)/2 then
				validrow <= '0';
			elsif i_hcounter > H-(KS-1)/2 then
				validrow <= '0';
			else
				validrow <= i_active;
			end if;
		end if;
	end process;

	enable <= validrow when rising_edge(clk);

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
	port map (clk=>clk, i_enable=>enable,
		i_window=>window, i_mask=>mask, o_pix=>o_pix);

	-- assign window
	-- auto generate based on the KS size
	-- w_gen: for i in 0 to KS-1 generate
	-- begin
	-- 	window(i*KS to i*KS + KS-1) <= rows(i*W to i*W + KS-1);
	-- end generate;

	window <= winbuf3 & winbuf2 & winbuf1;

end rtl;
