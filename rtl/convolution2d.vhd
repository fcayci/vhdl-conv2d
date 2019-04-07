-- author: Furkan Cayci, 2019
-- description: 2d convolution with a given mask
-- variable mask and pixel size

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity convolution2d is
	generic (
		KS : integer := 3 -- mask size
	);
	port (
		clk      : in  std_logic;
		-- control signals
		i_enable : in  std_logic;
		--done   : out std_logic;
		-- window / mask
		window   : in  pixel_array(0 to KS**2-1);
		mask     : in  mask_array(0 to KS**2-1);
		-- output pixel and valid signals
		o_pix    : out pixel;
		o_valid  : out std_logic
	);
end convolution2d;

architecture rtl of convolution2d is
begin
	-- iteratively
	-- also generate active signal
	process(clk) is
		variable sum : integer := 0;
	begin
		if rising_edge(clk) then
			if i_enable = '1' then
				sum := 0;
				for n in 0 to KS-1 loop
					for k in 0 to KS-1 loop
						sum := sum + (to_integer(window(n*KS + k)) * mask(n*KS + k));
					end loop;
				end loop;
				o_pix <= to_signed(sum, 8);
				o_valid <= '1';
			else
				o_valid <= '0';
			end if;
		end if;
	end process;

end rtl;