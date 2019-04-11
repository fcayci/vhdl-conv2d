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
	-- this will hold the first {mask size} rows
	signal rows : pixel_array(0 to ((KS-1) * W) + KS-1);

	-- window to be convoluted
	signal window : pixel_array(0 to KS**2-1);

	-- delay enable signal
	-- it is {mask size-1 / 2} row big + {mask size-1 / 2} pixel for extra padding
	-- for mask size = 3; 1 row + 1 pixel
	-- for mask size = 5; 2 rows + 2 pixels
	signal enable : std_logic_vector((KS-1)/2*(W+1) downto 0) := (others => '0');
begin

	process(clk) is
	begin
		-- push the incoming rgb to the edge of the buffer
		-- active is the signal that comes with rgb values
		-- (video active area)
		if rising_edge(clk) then
			-- push the new pixel to the end of the buffer when active
			-- flush the buffers when not active
			if i_active = '1' then
				rows <= rows(1 to rows'high) & i_rgb;
			else
				rows <= rows(1 to rows'high) & x"00";
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

	-- 2d convolution
	c2d: entity work.convolution2d(rtl)
	generic map (KS=>KS)
	port map (clk=>clk, i_enable=>enable(enable'high),
		window=>window, mask=>i_mask, o_pix=>o_rgb,
		o_valid=>o_valid);

	-- assign window
	-- auto generate based on the KS size
	w_gen: for i in 0 to KS-1 generate
	begin
		window(i*KS to i*KS + KS-1) <= rows(i*W to i*W + KS-1);
	end generate;

end rtl;
