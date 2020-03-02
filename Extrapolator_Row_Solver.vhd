library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_Row_Solver is
generic (
		FAST_MODE	: BOOLEAN := false
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		valid_input : in STD_LOGIC;
		Coordinates : in coordinate_array_stage1_float;
		Constants 	: in constant_row_array;
		ready 			: out STD_LOGIC;

		Result		: out std_logic_vector(31 downto 0);
		valid_output : out STD_LOGIC
);
end Extrapolator_Row_Solver;

architecture behavioral of Extrapolator_Row_Solver is

	component add is
		port (
			clk0            : in  std_logic                     := 'X';             -- clk
			ena             : in  std_logic                     := 'X';             -- ena
			clr0            : in  std_logic                     := 'X';             -- reset
			result          : out std_logic_vector(31 downto 0);                    -- result
			ax              : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ax
			ay              : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ay
			adder_overflow  : out std_logic;                                        -- adder_overflow
			adder_underflow : out std_logic;                                        -- adder_underflow
			adder_invalid   : out std_logic;                                        -- adder_invalid
			adder_inexact   : out std_logic                                         -- adder_inexact
		);
	end component add;


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

constant LATENCY : integer := 15;

signal Coordinates_i : coordinate_array_stage1_float := (others => (others => '0'));
signal Constants_i	 : constant_row_array := (others => (others => '0'));
signal calculating	 : boolean := false;

signal Coord_to_mult : std_logic_vector(31 downto 0) := (others => '0');
signal Const_to_mult : std_logic_vector(31 downto 0) := (others => '0');
signal Coord_to_mult2 : std_logic_vector(31 downto 0) := (others => '0');
signal Const_to_mult2 : std_logic_vector(31 downto 0) := (others => '0');
signal result_mult   : std_logic_vector(31 downto 0) := (others => '0');
signal result_mult2  : std_logic_vector(31 downto 0) := (others => '0');
signal result_mult2_pipe : std_logic_vector(31 downto 0) := (others => '0');
signal result_mult2_add : std_logic_vector(31 downto 0) := (others => '0');
signal result_add    : std_logic_vector(31 downto 0) := (others => '0');
signal accumulate 	 : std_logic;
signal enable 	 		 : std_logic := '1';
signal count 				 : integer := 0;

signal latency_pipe  : std_logic_vector(LATENCY-1 downto 0) := (others => '0');


begin

	store_internal_data : process(clk)
	begin
		if (reset = '1') then
				Coordinates_i <= (others => (others => '0'));
				Constants_i 	<= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			if (valid_input = '1' and not calculating) then
				Coordinates_i <= Coordinates;
				Constants_i 	<= Constants;
			end if;
		end if;
	end process store_internal_data;


	processing_state : process(clk)
	begin
		if (reset = '1') then
				calculating <= false;
				ready <= '1';
		elsif (rising_edge(clk)) then
			if (calculating) then
				if ((FAST_MODE and count = N_Matrix_Col/2) or
						(not FAST_MODE and count = N_Matrix_Col)) then
					calculating <= false;
					ready <= '1';
				end if;
			else
				if (valid_input = '1') then
					calculating <= true;
					ready <= '0';
				end if;
			end if;
		end if;
	end process processing_state;


	time_latency : process(clk)
	begin
		if (reset = '1') then
				latency_pipe <= (others => '0');
		elsif (rising_edge(clk)) then
			latency_pipe(0) <= '0';
			if (not calculating and valid_input = '1') then
				latency_pipe(0) <= '1';
			end if;
			for i in LATENCY-1 downto 1 loop
				latency_pipe(i) <= latency_pipe(i-1);
			end loop;
		end if;
	end process time_latency;


	time_accumulation : process(clk)
	begin
		if (reset = '1') then
				count <= 0;
				accumulate <= '0';
		elsif (rising_edge(clk) and calculating) then
			if ((FAST_MODE and count < N_Matrix_Col/2) or
			 		(not FAST_MODE and count < N_Matrix_Col)) then
				count <= count + 1;
				accumulate <= '1';
			else
				count <= 0;
				accumulate <= '0';
			end if;
		end if;
	end process time_accumulation;


	feed_multiplier : process(clk)
	begin
		if (reset = '1') then
			Coord_to_mult  <= (others => '0');
			Const_to_mult  <= (others => '0');
			Coord_to_mult2 <= (others => '0');
			Const_to_mult2 <= (others => '0');
		elsif (rising_edge(clk)) then
			if (FAST_MODE) then
				if (calculating and count < N_Matrix_Col/2) then
					Coord_to_mult  <= Coordinates_i(2*count);
					Const_to_mult  <= Constants_i(2*count);
					Coord_to_mult2 <= Coordinates_i(2*count+1);
					Const_to_mult2 <= Constants_i(2*count+1);
				else
					Coord_to_mult  <= Coordinates(N_Matrix_Col-1);
					Const_to_mult  <= Constants(N_Matrix_Col-1);
					Coord_to_mult2 <= ONE_float;
					Const_to_mult2 <= Constants(N_Matrix_Col);
				end if;
			else
				if (calculating and count < N_Matrix_Col) then
					Coord_to_mult <= Coordinates_i(count);
					Const_to_mult <= Constants_i(count);
				else
					Coord_to_mult <= ONE_float;
					Const_to_mult <= Constants(N_Matrix_Col);
				end if;
			end if;
		end if;
	end process feed_multiplier;


	Multiply_Accumulator : mult_accum
		port map (
			clk0            => clk,            --            clk0.clk
			ena             => enable,             --             ena.ena
			clr0            => reset,            --            clr0.reset
			result          => result_mult,          --          result.result
			accumulate      => accumulate,      --      accumulate.accumulate
			ay              => Coord_to_mult,              --              ay.ay
			az              => Const_to_mult              --              az.az
--			mult_overflow   => CONNECTED_TO_mult_overflow,   --   mult_overflow.mult_overflow
--			mult_underflow  => CONNECTED_TO_mult_underflow,  --  mult_underflow.mult_underflow
--			mult_invalid    => CONNECTED_TO_mult_invalid,    --    mult_invalid.mult_invalid
--			mult_inexact    => CONNECTED_TO_mult_inexact,    --    mult_inexact.mult_inexact
--			adder_overflow  => CONNECTED_TO_adder_overflow,  --  adder_overflow.adder_overflow
--			adder_underflow => CONNECTED_TO_adder_underflow, -- adder_underflow.adder_underflow
--			adder_invalid   => CONNECTED_TO_adder_invalid,   --   adder_invalid.adder_invalid
--			adder_inexact   => CONNECTED_TO_adder_inexact    --   adder_inexact.adder_inexact
		);

Result 				<= result_add when FAST_MODE else result_mult;
valid_output 	<= latency_pipe(LATENCY-1);

GEN_FAST_MODE : if FAST_MODE generate
	Multiply_Accumulator_2 : mult_accum
		port map (
			clk0            => clk,            --            clk0.clk
			ena             => enable,             --             ena.ena
			clr0            => reset,            --            clr0.reset
			result          => result_mult2,          --          result.result
			accumulate      => accumulate,      --      accumulate.accumulate
			ay              => Coord_to_mult2,              --              ay.ay
			az              => Const_to_mult2              --              az.az
--			mult_overflow   => CONNECTED_TO_mult_overflow,   --   mult_overflow.mult_overflow
--			mult_underflow  => CONNECTED_TO_mult_underflow,  --  mult_underflow.mult_underflow
--			mult_invalid    => CONNECTED_TO_mult_invalid,    --    mult_invalid.mult_invalid
--			mult_inexact    => CONNECTED_TO_mult_inexact,    --    mult_inexact.mult_inexact
--			adder_overflow  => CONNECTED_TO_adder_overflow,  --  adder_overflow.adder_overflow
--			adder_underflow => CONNECTED_TO_adder_underflow, -- adder_underflow.adder_underflow
--			adder_invalid   => CONNECTED_TO_adder_invalid,   --   adder_invalid.adder_invalid
--			adder_inexact   => CONNECTED_TO_adder_inexact    --   adder_inexact.adder_inexact
		);

	Adder : add
		port map (
			clk0            => clk,            --            clk0.clk
			ena             => enable,             --             ena.ena
			clr0            => reset,            --            clr0.reset
			result          => result_add,          --          result.result
			ax              => result_mult,              --              ax.ax
			ay              => result_mult2_add              --              ay.ay
			--adder_overflow  => CONNECTED_TO_adder_overflow,  --  adder_overflow.adder_overflow
			--adder_underflow => CONNECTED_TO_adder_underflow, -- adder_underflow.adder_underflow
			--adder_invalid   => CONNECTED_TO_adder_invalid,   --   adder_invalid.adder_invalid
			--adder_inexact   => CONNECTED_TO_adder_inexact    --   adder_inexact.adder_inexact
		);

	alignment_pipe : process(clk)
	begin
		if (reset = '1') then
			result_mult2_pipe <= (others => '0');
			result_mult2_add  <= (others => '0');
		elsif (rising_edge(clk)) then
			result_mult2_pipe <= result_mult2;
			result_mult2_add  <= result_mult2_pipe;
		end if;
	end process alignment_pipe;

end generate GEN_FAST_MODE;


end behavioral;
