library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_SSMap is
generic (
		N_CONNECTIONS	: INTEGER := 1
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		--Constant Loader Interface
		ModuleID : in module_array;
		valid_module : in std_logic;

		-- Matrix Calculation Interface
		Coordinates_exp_float : in coordinate_array_exp_float;
		valid_exp_result : in STD_LOGIC;
		halt_out : out STD_LOGIC;

		halt_in:		in	STD_LOGIC
);
end Extrapolator_SSMap;

architecture behavioral of Extrapolator_SSMap is

	component fifo_float32 is
		port (
			data        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain
			wrreq       : in  std_logic                     := 'X';             -- wrreq
			rdreq       : in  std_logic                     := 'X';             -- rdreq
			clock       : in  std_logic                     := 'X';             -- clk
			sclr        : in  std_logic                     := 'X';             -- sclr
			q           : out std_logic_vector(31 downto 0);                    -- dataout
			empty       : out std_logic;                                        -- empty
			almost_full : out std_logic                                         -- almost_full
		);
	end component fifo_float32;

	component mult_accum is
		port (
			clk0            : in  std_logic                     := 'X';             -- clk
			ena             : in  std_logic                     := 'X';             -- ena
			clr0            : in  std_logic                     := 'X';             -- reset
			result          : out std_logic_vector(31 downto 0);                    -- result
			accumulate      : in  std_logic                     := 'X';             -- accumulate
			ay              : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ay
			az              : in  std_logic_vector(31 downto 0) := (others => 'X'); -- az
			mult_overflow   : out std_logic;                                        -- mult_overflow
			mult_underflow  : out std_logic;                                        -- mult_underflow
			mult_invalid    : out std_logic;                                        -- mult_invalid
			mult_inexact    : out std_logic;                                        -- mult_inexact
			adder_overflow  : out std_logic;                                        -- adder_overflow
			adder_underflow : out std_logic;                                        -- adder_underflow
			adder_invalid   : out std_logic;                                        -- adder_invalid
			adder_inexact   : out std_logic                                         -- adder_inexact
		);
	end component mult_accum;

	component truncation is
		port (
			clk    : in  std_logic                     := 'X';             -- clk
			areset : in  std_logic                     := 'X';             -- reset
			a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component truncation;



signal coordinates_exp_empty : std_logic_vector(N_Coordinates_Extrapolated-1 downto 0) := (others => '0');
signal coordinates_exp_almost_full : std_logic_vector(N_Coordinates_Extrapolated-1 downto 0) := (others => '0');

signal result : std_logic_vector(31 downto 0);
signal test_floor : std_logic_vector(31 downto 0);

begin

halt_out <= coordinates_exp_almost_full(0);

GEN_Coordinates_FIFO_out : for i in N_Coordinates_Extrapolated-1 downto 0 generate
	coordinate_exp_fifos : fifo_float32
		port map (
			data        => Coordinates_exp_float(i),        --  fifo_input.datain
			wrreq       => valid_exp_result,       --            .wrreq
			rdreq       => '0',       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			--q           => ,           -- fifo_output.dataout
			empty       => coordinates_exp_empty(i),       --            .empty
			almost_full => coordinates_exp_almost_full(i)  --            .almost_full
		);
end generate GEN_Coordinates_FIFO_out;

Multiply_Accumulator : mult_accum
	port map (
		clk0            => clk,            --            clk0.clk
		ena             => '1',             --             ena.ena
		clr0            => reset,            --            clr0.reset
		result          => result,          --          result.result
		accumulate      => '1',      --      accumulate.accumulate
		ay              => ONE_float,              --              ay.ay
		az              => X"3DCCCCCD"              --              az.az
--			mult_overflow   => CONNECTED_TO_mult_overflow,   --   mult_overflow.mult_overflow
--			mult_underflow  => CONNECTED_TO_mult_underflow,  --  mult_underflow.mult_underflow
--			mult_invalid    => CONNECTED_TO_mult_invalid,    --    mult_invalid.mult_invalid
--			mult_inexact    => CONNECTED_TO_mult_inexact,    --    mult_inexact.mult_inexact
--			adder_overflow  => CONNECTED_TO_adder_overflow,  --  adder_overflow.adder_overflow
--			adder_underflow => CONNECTED_TO_adder_underflow, -- adder_underflow.adder_underflow
--			adder_invalid   => CONNECTED_TO_adder_invalid,   --   adder_invalid.adder_invalid
--			adder_inexact   => CONNECTED_TO_adder_inexact    --   adder_inexact.adder_inexact
	);

	floor : truncation
		port map (
			clk    => clk,    --    clk.clk
			areset => reset, -- areset.reset
			a      => result,      --      a.a
			q      => test_floor       --      q.q
		);




end behavioral;
