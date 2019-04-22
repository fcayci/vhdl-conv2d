-- author: Furkan Cayci, 2019
-- description: image processing unit

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity ipu_top is
	port(
		-- hdmi in
		hdmi_rx_clk_p : IN std_logic;
		hdmi_rx_clk_n : IN std_logic;
		hdmi_rx_d_p : IN std_logic_vector(2 downto 0);
		hdmi_rx_d_n : IN std_logic_vector(2 downto 0);
		hdmi_rx_hpd : out std_logic;
		hdmi_rx_scl_io : inout std_logic;
		hdmi_rx_sda_io : inout std_logic;

		-- hdmi out
		hdmi_tx_clk_p : out std_logic;
		hdmi_tx_clk_n : out std_logic;
		hdmi_tx_d_p : out std_logic_vector(2 downto 0);
		hdmi_tx_d_n : out std_logic_vector(2 downto 0);
		--
		sysclk : in std_logic;
		rst : in std_logic;
		led1 : out std_logic;
		led2 : out std_logic;

		sw : in std_logic_vector(2 downto 0)
	);
end ipu_top;

architecture rtl of ipu_top is
	component dvi2rgb_0
	port (
	TMDS_Clk_p : IN std_logic;
	TMDS_Clk_n : IN std_logic;
	TMDS_Data_p : IN std_logic_vector(2 downto 0);
	TMDS_Data_n : IN std_logic_vector(2 downto 0);
	RefClk : IN std_logic;
	aRst : IN std_logic;
	vid_pData : OUT std_logic_vector(23 downto 0);
	vid_pVDE : OUT std_logic;
	vid_pHSync : OUT std_logic;
	vid_pVSync : OUT std_logic;
	PixelClk : OUT std_logic;
	aPixelClkLckd : OUT std_logic;
	SDA_I : IN std_logic;
	SDA_O : OUT std_logic;
	SDA_T : OUT std_logic;
	SCL_I : IN std_logic;
	SCL_O : OUT std_logic;
	SCL_T : OUT std_logic;
	pRst : IN std_logic
	);
	end component;

	component rgb2tmds_0
	port (
	clk_p : OUT std_logic;
	clk_n : OUT std_logic;
	data_p : OUT std_logic_vector(2 downto 0);
	data_n : OUT std_logic_vector(2 downto 0);
	rst : IN std_logic;
	video_data : IN std_logic_vector(23 downto 0);
	video_active : IN std_logic;
	hsync : IN std_logic;
	vsync : IN std_logic;
	serialclock : IN std_logic;
	pixelclock : IN std_logic
	);
	end component;

	component rgb2dvi_0
	port (
	TMDS_Clk_p : OUT std_logic;
	TMDS_Clk_n : OUT std_logic;
	TMDS_Data_p : OUT std_logic_vector(2 downto 0);
	TMDS_Data_n : OUT std_logic_vector(2 downto 0);
	aRst : IN std_logic;
	vid_pData : IN std_logic_vector(23 downto 0);
	vid_pVDE : IN std_logic;
	vid_pHSync : IN std_logic;
	vid_pVSync : IN std_logic;
	PixelClk : IN std_logic
	);
	end component;

	constant PIXSIZE : integer := 8;
	constant CHANNEL : integer := 3;
	constant SYNCPASS : boolean := true;
	constant H : integer := 720;
	constant W : integer := 1280;
	constant KS : integer := 3;

	signal vin_data : std_logic_vector(23 downto 0);
	signal vin_active  : std_logic;
	signal vin_hsync, vin_vsync : std_logic;
	signal pixelclock  : std_logic;
	signal serialclock : std_logic;
	signal refclock  : std_logic;

	signal ddc_sda_i, ddc_sda_o, ddc_sda_t : std_logic;
	signal ddc_scl_i, ddc_scl_o, ddc_scl_t : std_logic;

	signal vout_data : std_logic_vector(23 downto 0) := (others => '0');
	signal vout_active : std_logic := '0';
	signal vout_hsync, vout_vsync : std_logic := '0';

begin

	led1 <= vin_active;
	led2 <= vout_active;
	hdmi_rx_hpd <= '1';

	-- 200 Mhz ref clock generate
	ref_clk_inst: entity work.clock_gen(rtl)
	port map (reset=>rst, clk_in1=>sysclk, clk_out1=>refclock);

	-- hdmi in
	hdmi_in_inst: dvi2rgb_0
	port map (TMDS_Clk_p=>hdmi_rx_clk_p, TMDS_Clk_n=>hdmi_rx_clk_n, TMDS_Data_p=>hdmi_rx_d_p, TMDS_Data_n=>hdmi_rx_d_n,
	RefClk=>refclock, aRst=>rst, vid_pData=>vin_data, vid_pVDE=>vin_active, vid_pHSync=>vin_hsync, vid_pVSync=>vin_vsync,
	PixelClk=>pixelclock, aPixelClkLckd=>open, pRst=>rst,
	SCL_I=>ddc_scl_i, SCL_O=>ddc_scl_o, SCL_T=>ddc_scl_t,
	SDA_I=>ddc_sda_i, SDA_O=>ddc_sda_o, SDA_T=>ddc_sda_t);

	ddc_scl_iobuf_inst : component IOBUF
	port map (
		I => ddc_scl_o,
		IO => hdmi_rx_scl_io,
		O => ddc_scl_i,
		T => ddc_scl_t
	);

	ddc_sda_iobuf_inst : component IOBUF
	port map (
		I => ddc_sda_o,
		IO => hdmi_rx_sda_io,
		O => ddc_sda_i,
		T => ddc_sda_t
	);

	-- hdmi out
	-- hdmi_out_inst: rgb2tmds_0
	-- port map (clk_p=>hdmi_tx_clk_p, clk_n=>hdmi_tx_clk_n, data_p=>hdmi_tx_d_p, data_n=>hdmi_tx_d_n,
	-- rst=>rst, video_data=>vout_data, video_active=>vout_active, hsync=>vout_hsync, vsync=>vout_vsync,
	-- pixelclock=>pixelclock, serialclock=>serialclock);

	-- hdmi out
	hdmi_out_inst: rgb2dvi_0
	port map (TMDS_Clk_p=>hdmi_tx_clk_p, TMDS_Clk_n=>hdmi_tx_clk_n, TMDS_Data_p=>hdmi_tx_d_p, TMDS_Data_n=>hdmi_tx_d_n,
	aRst=>rst, vid_pData=>vout_data, vid_pVDE=>vout_active, vid_pHSync=>vout_hsync, vid_pVSync=>vout_vsync,
	PixelClk=>pixelclock);

	-- timing generator
	-- tg_inst: entity work.timing_generator(rtl)
	-- generic map (GEN_PIX_LOC=>false)
	-- port map (clk=>pixelclock, hsync=>vout_hsync, vsync=>vout_vsync, video_active=>vout_active);

	-- pattern generator
	-- pg_inst: entity work.pattern_generator(rtl)
	-- port map (clk=>pixelclock, video_active=>vout_active, rgb=>vin_data);

	-- ipu
	ipu_inst: entity work.ipu(rtl)
	generic map (PIXSIZE=>PIXSIZE, CHANNEL=>CHANNEL, SYNCPASS=>SYNCPASS, H=>H, W=>W, KS=>KS)
	port map (clk=>pixelclock, i_maskctrl=>sw, i_active=>vin_active,
	i_hsync=>vin_hsync, i_vsync=>vin_vsync, i_rgb=>vin_data,
	o_active=>vout_active, o_hsync=>vout_hsync, o_vsync=>vout_vsync, o_rgb=>vout_data);

end rtl;
