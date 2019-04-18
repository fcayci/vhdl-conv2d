-- author: Furkan Cayci, 2019
-- description: image processing unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ipu is
	generic(
		PIXSIZE : integer := 8; -- pixel size
		CHANNEL : integer := 3; -- number of color channels
		H  : integer := 8; -- height of image
		W  : integer := 10; -- width of image
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		clk        : in  std_logic;
		i_maskctrl : in  std_logic_vector(2 downto 0); -- mask control
		i_active   : in  std_logic; --  input active signal
		i_rgb      : in  std_logic_vector(CHANNEL*PIXSIZE-1 downto 0); -- input rgb data
		o_active   : out std_logic; -- output active signal
		o_rgb      : out std_logic_vector(CHANNEL*PIXSIZE-1 downto 0)  -- output rgb data
	);
end ipu;

architecture rtl of ipu is
	-- there are three active signals, but one is enough
	-- leave two unconnected
	signal active : std_logic_vector(CHANNEL-1 downto 0) := (others => '0');
	signal mask : mask_array(0 to KS**2-1);
	signal s_i_rgb : signed(CHANNEL*PIXSIZE-1 downto 0);
	signal s_o_rgb : signed(CHANNEL*PIXSIZE-1 downto 0);

begin

	-- input/output type conversions
	s_i_rgb <= signed(i_rgb);
	o_rgb <= std_logic_vector(s_o_rgb);

	-- select mask
	masksel: entity work.mask(rtl)
	port map (i_ctrl=>i_maskctrl, o_mask=>mask);

	-- generate workgroup(s) for r,g,b channels
	gen_channels: for i in 1 to CHANNEL generate
	begin
		ch: entity work.workgroup(rtl)
		generic map (H=>H, W=>W, KS=>KS)
		port map (clk=>clk, i_active=>i_active, i_pix=>s_i_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE),
		i_mask=>mask, o_pix=>s_o_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE),
		o_valid=>active(i-1));
	end generate;

	-- since they are all parallel, one of them should be enough
	o_active <= active(0) or active(1) or active(2);

end rtl;
