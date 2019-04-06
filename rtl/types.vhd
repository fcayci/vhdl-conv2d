library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is

	subtype pixel is signed(7 downto 0); --integer range -128 to 127;
	type pixel_array is array(natural range <>) of pixel;

	subtype mask is integer range -128 to 127;
	type mask_array is array(integer range <>) of mask;
	subtype mask9 is mask_array(0 to 8);
	--type img_type is array(natural range <>, natural range <>) of pixel;

end types;
