library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;

entity Extrapolator_Main is
generic (
		N_CONNECTIONS	: INTEGER := 1;
		FAST_MODE	: BOOLEAN := false
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		-- Track Tranceiver Interface
		din:			in STD_LOGIC_VECTOR(63 downto 0);
		metadata:	in STD_LOGIC;
		valid_data:	in STD_LOGIC;
		ready:		out STD_LOGIC;
		halt_out:	out STD_LOGIC;

		--HBM Interface
		SectorID_8L_to_HBM:out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		read_request_to_HBM:out STD_LOGIC;
		Constants_from_HBM : in constant_array;
		ModuleID_from_HBM : in module_array;
		SectorID_8L_from_HBM : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		SectorID_13L_from_HBM : in STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0);
		Constants_Ready_from_HBM : in STD_LOGIC;

		halt_in:		in	STD_LOGIC
);
end Extrapolator_Main;


architecture behavioral of Extrapolator_Main is

component Extrapolator_Decoder
generic (
		N_CONNECTIONS	: INTEGER := 1
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		-- Track Tranceiver Interface
		din:			in STD_LOGIC_VECTOR(63 downto 0);
		metadata:	in STD_LOGIC;
		valid_data:	in STD_LOGIC;
		ready:		out STD_LOGIC;
		halt_out:	out STD_LOGIC;

		-- Constant Loader and Matrix Calculation Interface
		L0ID:			out STD_LOGIC_VECTOR(L0ID_Length-1 downto 0);
		SectorID_8L:out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		Coordinates:out coordinate_array_stage1_int;
		valid_track:out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end component;


component Extrapolator_Constants_Loader
generic (
		N_CONNECTIONS	: INTEGER := 1
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		-- Decoder Interface
		SectorID_8L:in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		valid_sector:in STD_LOGIC;
		halt_out:	out STD_LOGIC;

		--HBM Interface
		SectorID_8L_to_HBM:out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		read_request_to_HBM:out STD_LOGIC;
		Constants_from_HBM : in constant_array;
		ModuleID_from_HBM : in module_array;
		SectorID_8L_from_HBM : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		SectorID_13L_from_HBM : in STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0);
		Constants_Ready_from_HBM : in STD_LOGIC;

		--SSMap Interface
		ModuleID : out module_array;

		-- Matrix Calculation Interface
		Constants : out constant_array;
		ConstantID_8L : out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		SectorID_13L : out STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0);
		valid_constants : out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end component;


component Extrapolator_Matrix_Calculation
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
end component;


component Extrapolator_SSMap
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
end component;


-- Decoder Output Signals
signal L0ID : STD_LOGIC_VECTOR(L0ID_Length-1 downto 0);
signal SectorID_8L	: STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
signal Coordinates : coordinate_array_stage1_int;
signal valid_track 	: STD_LOGIC;

-- Constant_Loader Output Signals
signal Constants : constant_array;
signal ModuleID : module_array;
signal ConstantID_8L : STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
signal SectorID_13L : STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0);
signal valid_constants : STD_LOGIC;

-- Matrix Calculation Output Signals
signal Coordinates_exp_float : coordinate_array_exp_float;
signal valid_exp_result : STD_LOGIC;

-- Internal Halt Signals between modules
signal halt_to_Decoder : STD_LOGIC := '0';
signal halt_from_Constants_Loader : STD_LOGIC := '0';
signal halt_from_Matrix_Calculation : STD_LOGIC := '0';
signal halt_from_SSMap : STD_LOGIC := '0';



begin

Decoder : Extrapolator_Decoder
	GENERIC MAP (
		N_CONNECTIONS => N_CONNECTIONS
	)
   PORT MAP (
		clk => clk,
		reset => reset,

		-- Track Tranceiver Interface
		din => din,
		metadata => metadata,
		valid_data => valid_data,
		ready => ready,
		halt_out => halt_out,

		-- Constant Loader and Matrix Calculation Interface
		L0ID			=> L0ID,
		SectorID_8L => SectorID_8L,
		Coordinates => Coordinates,
		valid_track => valid_track,
		halt_in => halt_to_Decoder
	);

halt_to_Decoder <= halt_from_Constants_Loader or halt_from_Matrix_Calculation;


Constants_Loader : Extrapolator_Constants_Loader
	GENERIC MAP (
		N_CONNECTIONS => N_CONNECTIONS
	)
   PORT MAP (
		clk => clk,
		reset => reset,

		-- Decoder Interface
		SectorID_8L => SectorID_8L,
		valid_sector => valid_track,
		halt_out => halt_from_Constants_Loader,

		--HBM Interface
		SectorID_8L_to_HBM => SectorID_8L_to_HBM,
		read_request_to_HBM => read_request_to_HBM,
		Constants_from_HBM => Constants_from_HBM,
		ModuleID_from_HBM => ModuleID_from_HBM,
		SectorID_8L_from_HBM => SectorID_8L_from_HBM,
		SectorID_13L_from_HBM => SectorID_13L_from_HBM,
		Constants_Ready_from_HBM => Constants_Ready_from_HBM,

		--SSMap Interface
		ModuleID => ModuleID,

		-- Matrix Calculation Interface
		Constants => Constants,
		ConstantID_8L => ConstantID_8L,
		SectorID_13L => SectorID_13L,
		valid_constants => valid_constants,
		halt_in => halt_from_Matrix_Calculation
	);


Matrix_Calculation : Extrapolator_Matrix_Calculation
	GENERIC MAP (
		N_CONNECTIONS => N_CONNECTIONS,
	  FAST_MODE 	=> FAST_MODE
	)
   PORT MAP (
		clk => clk,
		reset => reset,

		-- Decoder Interface
		L0ID			=> L0ID,
		SectorID_8L => SectorID_8L,
		Coordinates => Coordinates,
		valid_track => valid_track,
		halt_out => halt_from_Matrix_Calculation,

		-- Constants Loader Interface
		Constants => Constants,
		ConstantID_8L => ConstantID_8L,
		valid_constants => valid_constants,

		-- SSMap Interface
		Coordinates_exp_float => Coordinates_exp_float,
		valid_exp_result => valid_exp_result,
		halt_in => halt_from_SSMap
	);



SSmap : Extrapolator_SSMap
	GENERIC MAP (
		N_CONNECTIONS => N_CONNECTIONS
	)
   PORT MAP (
		clk => clk,
		reset => reset,

		--Constant Loader Interface
		ModuleID => ModuleID,
		valid_module => valid_constants,

		-- Matrix Calculation Interface
		Coordinates_exp_float => Coordinates_exp_float,
		valid_exp_result => valid_exp_result,
		halt_out => halt_from_SSMap,

		halt_in => halt_in
	);


end behavioral;
