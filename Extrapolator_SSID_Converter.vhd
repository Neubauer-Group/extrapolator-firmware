library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_SSID_Converter is
generic (
		N_COORDINATES			 : INTEGER := 2;
		SCALE_COORDINATE_1 : STD_LOGIC_VECTOR(31 downto 0) := X"3D000000"; --float strip/phi
		SCALE_COORDINATE_2 : STD_LOGIC_VECTOR(31 downto 0) := X"3D4CCCCD"; --float eta
		N_SS_PER_MODULE    : INTEGER := 360;
		N_SS_PER_ROW       : INTEGER := 20
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		moduleID : in STD_LOGIC_VECTOR(ModuleID_Length-1 downto 0);
		coordinate_1 : in STD_LOGIC_VECTOR(31 downto 0);
		coordinate_2 : in STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
		valid_in : in STD_LOGIC;
		halt_out : out STD_LOGIC;

		SSID : out STD_LOGIC_VECTOR(SSID_Length-1 downto 0);
		valid_out : out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end Extrapolator_SSID_Converter;

architecture behavioral of Extrapolator_SSID_Converter is

	component truncation is
		port (
			clk    : in  std_logic                     := 'X';             -- clk
			areset : in  std_logic                     := 'X';             -- reset
			a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component truncation;

	component mult is
		port (
			clk0           : in  std_logic                     := 'X';             -- clk
			ena            : in  std_logic                     := 'X';             -- ena
			clr0           : in  std_logic                     := 'X';             -- reset
			result         : out std_logic_vector(31 downto 0);                    -- result
			ay             : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ay
			az             : in  std_logic_vector(31 downto 0) := (others => 'X'); -- az
			mult_overflow  : out std_logic;                                        -- mult_overflow
			mult_underflow : out std_logic;                                        -- mult_underflow
			mult_invalid   : out std_logic;                                        -- mult_invalid
			mult_inexact   : out std_logic                                         -- mult_inexact
		);
	end component mult;

	component SSID_Converter_RAM is
		port (
			data    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- datain
			q       : out std_logic_vector(15 downto 0);                    -- dataout
			address : in  std_logic_vector(17 downto 0) := (others => 'X'); -- address
			wren    : in  std_logic                     := 'X';             -- wren
			clock   : in  std_logic                     := 'X'              -- clk
		);
	end component SSID_Converter_RAM;

	component mult_add_fixed is
		port (
			ay      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- ay
			by      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- by
			ax      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- ax
			bx      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- bx
			resulta : out std_logic_vector(15 downto 0);                    -- resulta
			clk0    : in  std_logic                     := 'X';             -- clk
			clk1    : in  std_logic                     := 'X';             -- clk
			clk2    : in  std_logic                     := 'X';             -- clk
			ena     : in  std_logic_vector(2 downto 0)  := (others => 'X'); -- ena
			clr0    : in  std_logic                     := 'X'              -- reset
		);
	end component mult_add_fixed;




signal enable : std_logic := '1';
signal scaled_coordinate_1_float : std_logic_vector(31 downto 0) := (others => '0');
signal scaled_coordinate_1_fixed : std_logic_vector(31 downto 0) := (others => '0');
signal scaled_coordinate_1_int : std_logic_vector(15 downto 0) := (others => '0');
signal scaled_coordinate_2_float : std_logic_vector(31 downto 0) := (others => '0');
signal scaled_coordinate_2_fixed : std_logic_vector(31 downto 0) := (others => '0');
signal scaled_coordinate_2_int : std_logic_vector(15 downto 0) := (others => '0');
signal module_offset : std_logic_vector(15 downto 0) := (others => '0');

constant MULT_LATENCY  : integer := 4;
constant FLOOR_LATENCY : integer := 1;
constant RAM_LATENCY : integer := 1;
constant MODULE_LATENCY : integer := MULT_LATENCY+FLOOR_LATENCY-RAM_LATENCY;
constant ONE_COORDINATE_LATENCY : integer := 2*MULT_LATENCY+FLOOR_LATENCY;
constant TWO_COORDINATE_LATENCY : integer := 3*MULT_LATENCY+FLOOR_LATENCY;

signal latency_pipe : std_logic_vector(TWO_COORDINATE_LATENCY-1 downto 0);
type offset_pipe is array (MODULE_LATENCY-1 downto 0) of std_logic_vector(15 downto 0);
signal module_offset_pipe : offset_pipe;
type coordinate_pipe is array (MULT_LATENCY-1 downto 0) of std_logic_vector(15 downto 0);
signal coordinate_2_pipe : coordinate_pipe;

signal result_1 : std_logic_vector(15 downto 0) := (others => '0');
signal result_2 : std_logic_vector(15 downto 0) := (others => '0');


begin

	Module_Offset_Storage : SSID_Converter_RAM
		port map (
			data    => X"0000",    --    data.datain
			q       => module_offset,       --       q.dataout
			address => moduleID, -- address.address
			wren    => '0',    --    wren.wren
			clock   => clk    --   clock.clk
		);


	divide : mult
		port map (
			clk0           => clk,           --           clk0.clk
			ena            => enable,            --            ena.ena
			clr0           => reset,           --           clr0.reset
			result         => scaled_coordinate_1_float,         --         result.result
			ay             => SCALE_COORDINATE_1,             --             ay.ay
			az             => coordinate_1             --             az.az
--			mult_overflow  => CONNECTED_TO_mult_overflow,  --  mult_overflow.mult_overflow
--			mult_underflow => CONNECTED_TO_mult_underflow, -- mult_underflow.mult_underflow
--			mult_invalid   => CONNECTED_TO_mult_invalid,   --   mult_invalid.mult_invalid
--			mult_inexact   => CONNECTED_TO_mult_inexact    --   mult_inexact.mult_inexact
		);


	floor : truncation
		port map (
			clk    => clk,    --    clk.clk
			areset => reset, -- areset.reset
			a      => scaled_coordinate_1_float,      --      a.a
			q      => scaled_coordinate_1_fixed       --      q.q
		);
	scaled_coordinate_1_int <= scaled_coordinate_1_fixed(31 downto 16);


	multiplier : mult_add_fixed
		port map (
			ay      => std_logic_vector(to_unsigned(N_SS_PER_MODULE, 16)),      --      ay.ay
			by      => std_logic_vector(to_unsigned(1, 16)),      --      ay.ay
			ax      => module_offset_pipe(MODULE_LATENCY-1),      --      ax.ax
			bx      => scaled_coordinate_1_int,      --      bx.bx
			resulta => result_1, -- resulta.resulta
			clk0    => clk,    --    clk0.clk
			clk1    => clk,    --    clk1.clk
			clk2    => clk,    --    clk2.clk
			ena     => "111",     --     ena.ena
			clr0    => reset     --    clr0.reset
		);


	time_latency : process(clk)
	begin
		if (reset = '1') then
				latency_pipe <= (others => '0');
				module_offset_pipe <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			latency_pipe(0) <= valid_in;
			module_offset_pipe(0) <= module_offset;
			for i in TWO_COORDINATE_LATENCY-1 downto 1 loop
				latency_pipe(i) <= latency_pipe(i-1);
			end loop;
			for i in MODULE_LATENCY-1 downto 1 loop
				module_offset_pipe(i) <= module_offset_pipe(i-1);
			end loop;
		end if;
	end process time_latency;

halt_out	<= halt_in;
valid_out <= latency_pipe(TWO_COORDINATE_LATENCY-1) when N_COORDINATES > 1 else
						 latency_pipe(ONE_COORDINATE_LATENCY-1);
SSID 			<= result_2 				when N_COORDINATES > 1 else
						 result_1;

GEN_Second_Coordinate : if N_COORDINATES > 1 generate
	divide_2 : mult
		port map (
			clk0           => clk,           --           clk0.clk
			ena            => enable,            --            ena.ena
			clr0           => reset,           --           clr0.reset
			result         => scaled_coordinate_2_float,         --         result.result
			ay             => SCALE_COORDINATE_2,             --             ay.ay
			az             => coordinate_2             --             az.az
--			mult_overflow  => CONNECTED_TO_mult_overflow,  --  mult_overflow.mult_overflow
--			mult_underflow => CONNECTED_TO_mult_underflow, -- mult_underflow.mult_underflow
--			mult_invalid   => CONNECTED_TO_mult_invalid,   --   mult_invalid.mult_invalid
--			mult_inexact   => CONNECTED_TO_mult_inexact    --   mult_inexact.mult_inexact
		);


	floor_2 : truncation
		port map (
			clk    => clk,    --    clk.clk
			areset => reset, -- areset.reset
			a      => scaled_coordinate_2_float,      --      a.a
			q      => scaled_coordinate_2_fixed       --      q.q
		);
	scaled_coordinate_2_int <= scaled_coordinate_2_fixed(31 downto 16);


	multiplier_2 : mult_add_fixed
		port map (
			ay      => std_logic_vector(to_unsigned(N_SS_PER_ROW, 16)),      --      ay.ay
			by      => std_logic_vector(to_unsigned(1, 16)),      --      ay.ay
			ax      => coordinate_2_pipe(MULT_LATENCY-1),      --      ax.ax
			bx      => result_1,      --      bx.bx
			resulta => result_2, -- resulta.resulta
			clk0    => clk,    --    clk0.clk
			clk1    => clk,    --    clk1.clk
			clk2    => clk,    --    clk2.clk
			ena     => "111",     --     ena.ena
			clr0    => reset     --    clr0.reset
		);

	coordinate_2_latency : process(clk)
	begin
		if (reset = '1') then
				coordinate_2_pipe <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			coordinate_2_pipe(0) <= scaled_coordinate_2_int;
			for i in MULT_LATENCY-1 downto 1 loop
				coordinate_2_pipe(i) <= coordinate_2_pipe(i-1);
			end loop;
		end if;
	end process coordinate_2_latency;

end generate GEN_Second_Coordinate;

end behavioral;
