-- author: Furkan Cayci, 2019
--   125 Mhz input clock
--   200 Mhz output clock

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity clock_gen is
	generic (
		CLKIN_PERIOD :    real := 8.000; -- input clock period (8ns)
		CLK_MULTIPLY : integer := 8;     -- multiplier
		CLK_DIVIDE   : integer := 1;     -- divider
		CLKOUT0_DIV  : integer := 5      -- serial clock divider
	);
	port(
		reset    : in  std_logic;
		clk_in1  : in  std_logic; -- input clock
		clk_out1 : out std_logic  --   ref clock
	);
end clock_gen;

architecture rtl of clock_gen is

	signal pllclk1  : std_logic;
	signal clkfbout : std_logic;

begin

	-- buffer output clocks
	clk1buf: BUFG port map (I=>pllclk1, O=>clk_out1);

	clock: PLLE2_BASE generic map (
		clkin1_period  => CLKIN_PERIOD,
		clkfbout_mult  => CLK_MULTIPLY,
		clkout0_divide => CLKOUT0_DIV,
		divclk_divide  => CLK_DIVIDE
	)
	port map(
		rst      => reset,
		pwrdwn   => '0',
		clkin1   => clk_in1,
		clkfbin  => clkfbout,
		clkfbout => clkfbout,
		clkout0  => pllclk1
	);

end rtl;
