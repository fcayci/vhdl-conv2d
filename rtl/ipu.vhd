-- author: Furkan Cayci, 2019
-- description: image processing unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.types.all;

entity ipu is
	generic(
		PIXSIZE : integer := 8; -- 1 channel pixel size
		CHANNEL : integer := 3; -- number of color channels
		SYNCPASS : boolean := true; -- generate hsync/vsync pass through
		H  : integer := 720; -- height of image
		W  : integer := 1280; -- width of image
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		-- pixel clock
		clk        : in  std_logic;
		-- mask selector
		i_maskctrl : in  std_logic_vector(2 downto 0); -- mask control

		-- input signals
		i_active   : in  std_logic; --  input active signal
		i_rgb      : in  std_logic_vector(CHANNEL*PIXSIZE-1 downto 0); -- input rgb data
		i_hsync    : in  std_logic;
		i_vsync    : in  std_logic;

		-- output signals
		o_active   : out std_logic; -- output active signal
		o_rgb      : out std_logic_vector(CHANNEL*PIXSIZE-1 downto 0); -- output rgb data
		o_hsync    : out std_logic;
		o_vsync    : out std_logic
	);
end ipu;

architecture rtl of ipu is
	-- there are three active signals, but one is enough
	-- leave two unconnected
	signal active : std_logic_vector(CHANNEL-1 downto 0) := (others => '0');
	signal mask : mask_array(0 to KS**2-1);
	signal u_i_rgb : unsigned(CHANNEL*PIXSIZE-1 downto 0);
	signal u_o_rgb : unsigned(CHANNEL*PIXSIZE-1 downto 0);

	-- + X comes from convolution pipline delay
	signal hsyncdelay : std_logic_vector((KS-1)/2*(W+1) + 3 downto 0) := (others => '0');
	signal vsyncdelay : std_logic_vector((KS-1)/2*(W+1) + 3 downto 0) := (others => '0');

begin

	-- input/output type conversions
	u_i_rgb <= unsigned(i_rgb);
	o_rgb <= std_logic_vector(u_o_rgb);

	-- generate hsync/vsync pass through mode
	sync_i: if SYNCPASS = true generate
	begin
	-- assign hsync/vsync
	o_hsync <= hsyncdelay(hsyncdelay'high);
	o_vsync <= vsyncdelay(vsyncdelay'high);

	-- hsync/vsync delay
	process(clk)
	begin
		if rising_edge(clk) then
			hsyncdelay <= hsyncdelay(hsyncdelay'high -1 downto 0) & i_hsync;
			vsyncdelay <= vsyncdelay(vsyncdelay'high -1 downto 0) & i_vsync;
		end if;
	end process;
	end generate;

	-- select mask
	masksel: entity work.mask(rtl)
	port map (i_ctrl=>i_maskctrl, o_mask=>mask);

	-- generate workgroup(s) for r,g,b channels
	ch: for i in 1 to CHANNEL generate
	begin
		wg: entity work.workgroup(rtl)
		generic map (PIXSIZE=>PIXSIZE, H=>H, W=>W, KS=>KS)
		port map (clk=>clk, i_active=>i_active, i_pix=>u_i_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE),
		i_mask=>mask, o_pix=>u_o_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE),
		o_valid=>active(i-1));
	end generate;

	-- since they are all parallel, one of them should be enough
	o_active <= active(0) or active(1) or active(2);

end rtl;
