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
		SYNCPOL : boolean := true; -- hsync/vsync polarity
		MAXWBITS : integer := 12; -- max number of bits for width
		H  : integer := 720; -- height of image
		W  : integer := 1280; -- width of image
		WLINE : integer := 1648; -- width of a full line
		KS : integer := 3    -- mask (kernel) size
	);
	port(
		-- pixel clock
		clk        : in  std_logic;
		-- mask selector
		i_maskctrl : in  std_logic_vector(2 downto 0); -- mask control

		-- video input signals
		i_rgb      : in  std_logic_vector(CHANNEL*PIXSIZE-1 downto 0);
		i_active   : in  std_logic;
		i_hsync    : in  std_logic;
		i_vsync    : in  std_logic;

		-- video output signals
		o_rgb      : out std_logic_vector(CHANNEL*PIXSIZE-1 downto 0);
		o_active   : out std_logic;
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

	signal hsyncbuf, vsyncbuf, activebuf : std_logic := '0';
	signal hcounter : unsigned(MAXWBITS-1 downto 0) := (others => '0');

	-- + X comes from convolution pipline delay
	signal hsyncdelay : std_logic_vector((KS-1)/2*(WLINE+1) + 4 downto 0) := (others => '0');
	signal vsyncdelay : std_logic_vector((KS-1)/2*(WLINE+1) + 4 downto 0) := (others => '0');
	signal activedelay : std_logic_vector((KS-1)/2*(WLINE+1) + 4 downto 0) := (others => '0');

begin

	-- input/output type conversions
	u_i_rgb <= unsigned(i_rgb);
	o_rgb <= std_logic_vector(u_o_rgb);

	-- line counter using falling edge detector
	-- which is used to omit first and last rows
	process(clk) is
	begin
		if rising_edge(clk) then
			vsyncbuf <= i_vsync;
			activebuf <= i_active;

			if (activebuf = '1') and (i_active = '0') then
				hcounter <= hcounter + 1;
			end if;
			if (vsyncbuf = '1') and (i_vsync = '0') then
				hcounter <= (others => '0');
			end if;
		end if;
	end process;

	-- generate hsync/vsync/active pass through mode
	-- delay for one row + convolution pipeline steps
	passthrough: if SYNCPASS = true generate
	-- -- assign hsync/vsync/active
	o_hsync <= hsyncdelay(hsyncdelay'high);
	o_vsync <= vsyncdelay(vsyncdelay'high);
	o_active <= activedelay(activedelay'high);

	-- hsync/vsync/active delay
	process(clk)
	begin
		if rising_edge(clk) then
			hsyncdelay <= hsyncdelay(hsyncdelay'high -1 downto 0) & i_hsync;
			vsyncdelay <= vsyncdelay(vsyncdelay'high -1 downto 0) & i_vsync;
			activedelay <= activedelay(activedelay'high -1 downto 0) & i_active;
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
		port map (clk=>clk, i_hcounter=>hcounter, i_active=>i_active, i_pix=>u_i_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE),
		i_mask=>mask, o_pix=>u_o_rgb(i*PIXSIZE-1 downto (i-1)*PIXSIZE));
	end generate;

end rtl;
