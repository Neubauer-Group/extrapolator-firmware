library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.STD_LOGIC_MISC.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_Matrix_Calculation is
generic (
		N_CONNECTIONS	: INTEGER := 1;
		FAST_MODE	: BOOLEAN := false
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		-- Decoder Interface
		L0ID : in STD_LOGIC_VECTOR(L0ID_Length-1 downto 0);
		SectorID_8L : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		Coordinates : in coordinate_array_stage1_int;
		valid_track : in STD_LOGIC;
		halt_out : out STD_LOGIC;

		-- Constants Loader Interface
		Constants : in constant_array;
		ConstantID_8L : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		valid_constants : in STD_LOGIC;

		-- SSMap Interface
		Coordinates_exp_float : out coordinate_array_exp_float;
		valid_exp_result : out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end Extrapolator_Matrix_Calculation;

architecture behavioral of Extrapolator_Matrix_Calculation is


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


	component float_convert is
		port (
			clk    : in  std_logic                     := 'X';             -- clk
			areset : in  std_logic                     := 'X';             -- reset
			a      : in  std_logic_vector(15 downto 0) := (others => 'X'); -- a
			q      : out std_logic_vector(31 downto 0)                     -- q
		);
	end component float_convert;


	component Extrapolator_Row_Solver
	generic (
	  FAST_MODE : BOOLEAN := false
	);
	port (
	  clk         : in  STD_LOGIC;
	  reset       : in  STD_LOGIC;

	  valid_input : in  STD_LOGIC;
	  Coordinates : in  coordinate_array_stage1_float;
	  Constants   : in  constant_row_array;
	  ready       : out STD_LOGIC;

		Result      : out std_logic_vector(31 downto 0);
	  valid_output : out  STD_LOGIC
	);
	end component Extrapolator_Row_Solver;



signal valid_track_pipe : std_logic := '0';
signal valid_track_float : std_logic := '0';

signal Coordinates_float : coordinate_array_stage1_float;
signal Coordinates_float_i : coordinate_array_stage1_float;
signal valid_arguments : std_logic := '0';
signal multipliers_ready : std_logic_vector(N_Matrix_Row-1 downto 0) := (others => '0');

signal results_valid : std_logic_vector(N_Matrix_Row-1 downto 0) := (others => '0');

signal constants_empty : constant_flag_array := (others => (others => '0'));
signal constants_almost_full : constant_flag_array := (others => (others => '0'));
signal Constants_i : constant_array;
signal read_input_arguments : std_logic := '0';

signal coordinates_stage1_empty : std_logic_vector(N_Coordinates_Stage1-1 downto 0) := (others => '0');
signal coordinates_stage1_almost_full : std_logic_vector(N_Coordinates_Stage1-1 downto 0) := (others => '0');

begin

halt_out <= coordinates_stage1_almost_full(0) or constants_almost_full(0)(0);
valid_exp_result <= results_valid(0);


GEN_Converters : for i in N_Coordinates_Stage1-1 downto 0 generate
	Hit_convert : float_convert
		port map (
			clk    => clk,    --    clk.clk
			areset => reset, -- areset.reset
			a      => Coordinates(i),      --      a.a
			q      => Coordinates_float(i)       --      q.q
		);
end generate GEN_Converters;


GEN_Constants_FIFO_Row : for i in N_Matrix_Row-1 downto 0 generate
	GEN_Constants_FIFO_Col : for j in N_Matrix_Col downto 0 generate
		constant_fifos : fifo_float32
			port map (
				data        => Constants(i)(j),        --  fifo_input.datain
				wrreq       => valid_constants,       --            .wrreq
				rdreq       => read_input_arguments,       --            .rdreq
				clock       => clk,       --            .clk
				sclr        => reset,        --            .sclr
				q           => Constants_i(i)(j),           -- fifo_output.dataout
				empty       => constants_empty(i)(j),       --            .empty
				almost_full => constants_almost_full(i)(j)  --            .almost_full
			);
	end generate GEN_Constants_FIFO_Col;
end generate GEN_Constants_FIFO_Row;


GEN_Coordinates_FIFO_in : for i in N_Coordinates_Stage1-1 downto 0 generate
	coordinate_stage1_fifos : fifo_float32
		port map (
			data        => Coordinates_float(i),        --  fifo_input.datain
			wrreq       => valid_track_float,       --            .wrreq
			rdreq       => read_input_arguments,       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			q           => Coordinates_float_i(i),           -- fifo_output.dataout
			empty       => coordinates_stage1_empty(i),       --            .empty
			almost_full => coordinates_stage1_almost_full(i)  --            .almost_full
		);
end generate GEN_Coordinates_FIFO_in;



GEN_Solvers : for i in N_Matrix_Row-1 downto 0 generate
	Row_Solver : Extrapolator_Row_Solver
	generic map (
	  FAST_MODE 	=> FAST_MODE
	)
	port map (
	  clk         => clk,
	  reset       => reset,

		valid_input => valid_arguments,
	  Coordinates => Coordinates_float_i,
	  Constants   => Constants_i(i),
		ready 			=> multipliers_ready(i),

		Result      => Coordinates_exp_float(i),
		valid_output => results_valid(i)
	);
end generate GEN_Solvers;


data_pipe : process(clk)
begin
	if (reset = '1') then
		valid_track_pipe <= '0';
		valid_track_float <= '0';
	elsif (rising_edge(clk)) then
		valid_track_pipe <= valid_track;
		valid_track_float <= valid_track_pipe;
	end if;
end process data_pipe;



initiate_calculation : process(clk)
begin
	if (reset = '1') then
		valid_arguments <= '0';
		read_input_arguments <= '0';
	elsif (rising_edge(clk)) then
		valid_arguments <= read_input_arguments;
		if (read_input_arguments = '0' and
				valid_arguments = '0' and
				multipliers_ready(0) = '1' and
				coordinates_stage1_empty(0) = '0' and
				constants_empty(0)(0) = '0' and
				halt_in = '0') then
			read_input_arguments <= '1';
		else
			read_input_arguments <= '0';
		end if;
	end if;
end process initiate_calculation;


end behavioral;
