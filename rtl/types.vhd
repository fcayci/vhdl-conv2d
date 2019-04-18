-- author: Furkan Cayci, 2019
-- description: custom pixel types

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package types is

	-- 8-bit pixel type
	--subtype pixel_int is integer range -128 to 127;
	subtype pixel is signed(7 downto 0);
	type pixel_array is array(natural range <>) of pixel;

	-- 8-bit mask type
	subtype mask is integer range -128 to 127;
	type mask_array is array(integer range <>) of mask;
	-- 3x3 mask
	subtype mask3 is mask_array(0 to 8);
	-- 5x5 mask
	subtype mask5 is mask_array(0 to 24);

end types;
