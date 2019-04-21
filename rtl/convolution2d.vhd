-- author: Furkan Cayci, 2019
-- description: 2d convolution with a given mask
-- selectable mask and pixel size

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity convolution2d is
	generic (
		PIXSIZE : integer := 8; -- pixel size
		KS : integer := 3 -- mask size
	);
	port (
		clk      : in  std_logic;
		-- control signals
		i_enable : in  std_logic;
		-- window / mask
		i_window : in  pixel_array(0 to KS**2-1);
		i_mask   : in  mask_array(0 to KS**2-1);
		-- output pixel and valid signals
		o_pix    : out pixel;
		o_valid  : out std_logic
	);
end convolution2d;

architecture rtl of convolution2d is
	type pixel_extended is array(natural range <>) of signed(2*PIXSIZE downto 0);
	signal x : pixel_extended(0 to KS**2-1) := (others => (others => '0'));
	signal valid : std_logic := '0';
begin
	-- two stage pipeline multiple, accumulate
	-- also generate active signal
	process(clk) is
		variable sum : integer := 0;
	begin
		if rising_edge(clk) then
			if i_enable = '1' then
				for n in 0 to KS-1 loop
					for k in 0 to KS-1 loop
						x(n*KS + k) <= signed('0' & i_window(n*KS + k)) * to_signed(i_mask(n*KS + k), 8);
					end loop;
				end loop;
				-- delay valid by one
				valid <= '1';
			else
				for i in x'range loop
					x(i) <= (others => '0');
				end loop;
				valid <= '0';
			end if;

			sum := 0;
			for i in x'range loop
				sum := sum + to_integer(x(i));
			end loop;

			-- take care of underflow/overflows
			if sum < 0 then
				o_pix <= (others=> '0');
			elsif sum > 255 then
				o_pix <= (others=> '1');
			else
				o_pix <= to_unsigned(sum, 8);
			end if;

			o_valid <= valid;

		end if;
	end process;

end rtl;