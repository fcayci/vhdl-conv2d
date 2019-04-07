-- author: Furkan Cayci, 2019
-- description:

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity workgroup is
	generic(
		H  : integer := 480; -- height of image
		W  : integer := 640; -- width of image
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		clk      : in  std_logic;
		i_active : in  std_logic; -- input active signal
		i_rgb    : in  pixel; -- input rgb data
		i_mask   : in  mask_array(0 to KS**2-1); -- 3x3 convolution mask
		o_rgb    : out pixel; -- output rgb data
		o_valid  : out std_logic -- output valid signal (for writing to a FIFO)
	);
end workgroup;

architecture rtl of workgroup is
	-- this will hold the first three rows
	signal row1 : pixel_array(0 to W-1) := (others => (others => '0'));
	signal row2 : pixel_array(0 to W-1) := (others => (others => '0'));
	signal row3 : pixel_array(0 to KS-1) := (others => (others => '0'));

	-- window to be convoluted
	signal window : pixel_array(0 to KS**2-1);

	-- delay enable signal
	-- it is one row big + 1 pixel for extra padding
	signal enable : std_logic_vector(W+1 downto 0) := (others => '0');
begin

	process(clk) is
	begin
		-- push the incoming rgb to the edge of the buffer
		-- active is the signal that comes with rgb values
		-- (video active area)
		if rising_edge(clk) then
			row1 <= row1(1 to W-1) & row2(0);
			row2 <= row2(1 to W-1) & row3(0);
			-- flush the buffers when not active
			if i_active = '1' then
				row3 <= row3(1 to KS-1) & i_rgb;
			else
				row3 <= row3(1 to KS-1) & x"00";
			end if;
		end if;
	end process;

	-- shift register that is one row big
	-- to delay the frame for a single row (both beginning and end)
	process(clk) is
	begin
		if rising_edge(clk) then
			if i_active = '1' then
				enable <= enable(W downto 0) & '1';
			else
				enable <= enable(W downto 0) & '0';
			end if;
		end if;
	end process;

	-- 2d convolution
	c2d: entity work.convolution2d(rtl)
	  generic map (KS=>KS)
	  port map (clk=>clk, i_enable=>enable(W+1),
		window=>window, mask=>i_mask, o_pix=>o_rgb,
		o_valid=>o_valid);

	-- assign window
	window <= row1(0 to 2) & row2(0 to 2) & row3(0 to 2);

end rtl;
