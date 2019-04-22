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
	type pixel_extended is array(natural range <>) of signed(2*PIXSIZE-1 downto 0);
	signal x : pixel_extended(0 to KS**2-1) := (others => (others => '0'));
	signal sum1, sum2, sum3 : signed(2*PIXSIZE-1 downto 0);
	signal valid, valid1 : std_logic := '0';
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
						x(n*KS + k) <= to_signed(to_integer(i_window(n*KS + k)) * i_mask(n*KS + k), 2*PIXSIZE);
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

			sum1 <= x(0) + x(1) + x(2);
			sum2 <= x(3) + x(4) + x(5);
			sum3 <= x(6) + x(7) + x(8);
			sum := to_integer(sum1) + to_integer(sum2) + to_integer(sum3);

			-- sum := 0;
			-- for i in x'range loop
			-- 	sum := sum + to_integer(x(i));
			-- end loop;

			-- take care of underflow/overflows
			if sum < 0 then
				o_pix <= (others=> '0');
			elsif sum > 255 then
				o_pix <= (others=> '1');
			else
				o_pix <= to_unsigned(sum, 8);
			end if;

			valid1 <= valid;
			o_valid <= valid1;

		end if;
	end process;

end rtl;