-- author: Furkan Cayci, 2019
-- description: image processing unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity mask is
	generic(
		KS : integer := 3 -- mask (kernel) size
	);
	port(
		ctrl : in  std_logic_vector(2 downto 0);
		mask : out mask_array(0 to KS**2-1)
	);
end mask;

architecture rtl of mask is

	-- identity mask
	constant identity5 : mask5 := (
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 1, 0, 0,
		0, 0, 0, 0, 0,
		0, 0, 0, 0, 0
	);

	-- laplacian mask
	constant laplacian5 : mask5 := (
		 0,  0, -1,  0,  0,
		 0, -1, -2, -1,  0,
		-1, -2, 16, -2, -1,
		 0, -1, -2, -1,  0,
		 0,  0, -1,  0,  0
	);

	-- identity mask
	constant identity3 : mask3 := (
		0, 0, 0,
		0, 1, 0,
		0, 0, 0
	);

	-- edge mask
	constant edge3 : mask3 := (
		-1, -1, -1,
		-1,  8, -1,
		-1, -1, -1
	);

	-- sharpen mask
	constant sharpen3 : mask3 := (
		 0, -1,  0,
		-1,  5, -1,
		 0, -1,  0
	);

begin

	m3_gen: if KS = 3 generate
	begin
	mask <= identity3 when ctrl = "000" else
	            edge3 when ctrl = "001" else
			 sharpen3;
	end generate;

	m5_gen: if KS = 5 generate
	begin
	mask <= identity5 when ctrl = "000" else
	        laplacian5;
	end generate;

end rtl;
