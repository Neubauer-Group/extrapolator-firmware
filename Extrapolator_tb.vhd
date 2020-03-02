library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_TEXTIO.all;
use STD.TEXTIO.all;

library work;
use work.Extrapolator_Package.all;


-- ###############################################################################################
--                                    TESTING PARAMETERS
-- ###############################################################################################
entity Extrapolator_tb is
GENERIC(
	-- Testbench Parameters
	DEBUG_ON		: boolean := false;			-- Enable for debug messages

	INPUT_FILE	: string	:= "./inputs.txt";	-- This is a list of the test vector files that need to be loaded
	MAX_COUNT	: integer := 2**12;			-- Max number of words allowed in input test vector
	MAX_TV		: integer := 8;				-- Max number of test vectors that can be loaded
	META_ON_RIGHT	: boolean := true;		-- Enable if metadata bit is on the right in the files
														-- Disable if metadata bit is on the left in the files


	INCREMENT_L0ID	: boolean := true;		-- Enable if you want test bench to increment L0ID on each loop
	TEST_RESET	: boolean := false;			-- Enable if you want test bench to send periodic resets
	TEST_BP		: boolean := false;			-- Enable if you want test bench to send periodic back pressure
	IDLE_WORD	: std_logic_vector(63 downto 0) := X"0000DEAD0000BEEF";

	CONSTANT_LATENCY : integer := 30;

	-- Extrapolator Parameters
	N_CONNECTIONS	: INTEGER := 1;
	FAST_MODE	: BOOLEAN := false
	);
end;

architecture behav of Extrapolator_tb is

COMPONENT Extrapolator_Main
		GENERIC (
			N_CONNECTIONS	: INTEGER := 1;
			FAST_MODE	: BOOLEAN := false
		);
      PORT (
			clk:			in STD_LOGIC;
			reset:		in STD_LOGIC;

			din:			in STD_LOGIC_VECTOR(63 downto 0);
			metadata:	in STD_LOGIC;
			valid_data:	in STD_LOGIC;
			ready:		out STD_LOGIC;
			halt_out:	out STD_LOGIC;

			SectorID_8L_to_HBM:out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
			read_request_to_HBM:out STD_LOGIC;
			Constants_from_HBM : in constant_array;
			ModuleID_from_HBM : in module_array;
			SectorID_8L_from_HBM : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
			SectorID_13L_from_HBM : in STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0);
			Constants_Ready_from_HBM : in STD_LOGIC;

			halt_in:		in	STD_LOGIC
		);
END COMPONENT ;


SIGNAL clk   		: std_logic := '0';
SIGNAL rst 			: std_logic := '0';
SIGNAL din			: std_logic_vector(63 downto 0) := (others => '0');
SIGNAL metadata	: std_logic := '0';
SIGNAL valid_data	: std_logic := '0';
SIGNAL ready   	: std_logic;
SIGNAL halt_out   : std_logic;
SIGNAL halt_in   	: std_logic := '0';


SIGNAL TV_index	: integer := 0;
SIGNAL word_index	: integer := 0;
SIGNAL L0ID_count	: integer := 0;


TYPE test_vector is array (MAX_COUNT-1 downto 0) of std_logic_vector(67 downto 0);
TYPE data_array is array (MAX_TV-1 downto 0) of test_vector;
SIGNAL text_data : data_array := (others => (others => (others => '0')));


TYPE vector_length is array (MAX_TV-1 downto 0) of integer;
SIGNAL TV_length	: vector_length := (others => 0);
SIGNAL TV_loaded	: integer := 0;

SIGNAL TV_sending : boolean := false;


SIGNAL SectorID_8L_to_HBM  : STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
SIGNAL read_request_to_HBM : STD_LOGIC;

SIGNAL Constants_from_HBM : constant_array := (others => (others => (others => '0')));
SIGNAL ModuleID_from_HBM : module_array := (others => (others => '0'));
SIGNAL SectorID_8L_from_HBM : STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0) := (others => '0');
SIGNAL SectorID_13L_from_HBM : STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0) := (others => '0');
SIGNAL Constants_Ready_from_HBM : STD_LOGIC := '0';

SIGNAL read_pipe : STD_LOGIC_VECTOR(CONSTANT_LATENCY-1 downto 0) := (others => '0');

begin

Extrapolator : Extrapolator_Main
	GENERIC MAP (
		N_CONNECTIONS => N_CONNECTIONS,
		FAST_MODE 	=> FAST_MODE
	)
   PORT MAP (
		clk => clk,
		reset => rst,

		din => din,
		metadata => metadata,
		valid_data => valid_data,
		ready => ready,
		halt_out => halt_out,

		SectorID_8L_to_HBM => SectorID_8L_to_HBM,
		read_request_to_HBM => read_request_to_HBM,
		Constants_from_HBM => Constants_from_HBM,
		ModuleID_from_HBM => ModuleID_from_HBM,
		SectorID_8L_from_HBM => SectorID_8L_from_HBM,
		SectorID_13L_from_HBM => SectorID_13L_from_HBM,
		Constants_Ready_from_HBM => Constants_Ready_from_HBM,


		halt_in => halt_in
	);



clock : PROCESS
   begin
   wait for 10 ns; clk  <= not clk;
end PROCESS clock;




reset : PROCESS
   begin
   wait for 5  ns; rst  <= '1';						-- Initial reset
   wait for 20 ns; rst  <= '0';

	if (TEST_RESET) then									-- Periodic resets
		while (TEST_RESET) loop
			wait for 5000 ns; rst  <= '1';
			wait for 500 ns; 	rst  <= '0';
		end loop;
	else
		wait;
	end if;
end PROCESS reset;


back_pressure : PROCESS
   begin
	if (TEST_BP) then										-- Periodic back pressure
		while (TEST_BP) loop
			wait for 1000 ns; halt_in  <= '1';
			wait for 200 ns; 	halt_in  <= '0';
		end loop;
	else
		wait;
	end if;
end PROCESS back_pressure;



-- This process reads the test vectors from a text file.
-- Contents of the files are placed in a large 3D array of registers
-- at the beginning of the simulation
file_read : PROCESS
	file input_list	: text open read_mode is INPUT_FILE;
	variable word 		: line;
	variable filename : line;
	variable word_vector : std_logic_vector(67 downto 0);
	variable N_files	: integer;
	variable count		: integer := 0;
	variable file_count : integer := 0;
	file read_file		: text;

	variable debug		: line;
begin
	file_count := 0;
	report "Reading input TVs from " &INPUT_FILE;

	while (not endfile(input_list)) loop
		readline(input_list, filename);
		report filename.all &" will be loaded";

		file_open(read_file, filename.all, read_mode);
		count := 0;
		while (not endfile(read_file)) loop

			readline(read_file, word);
			if (DEBUG_ON) then
				write(debug, count);
				report "Word " &debug.all &" is " &word.all;
				debug := null;
			end if;

			hread(word, word_vector);
			text_data(file_count)(count) <= word_vector;
			count := count + 1;
		end loop;

		TV_length(file_count) <= count;			-- Extracts the length of the test vector
		file_close(read_file);
		report "Closing " &filename.all;

		file_count := file_count + 1;
	end loop;

	if (DEBUG_ON) then
		write(debug, file_count);
		report "Total number of files read is " &debug.all;
		debug := null;
	end if;

	TV_loaded <= file_count;
	file_close(input_list);
	report "Closing " &INPUT_FILE;
	wait;

end PROCESS file_read;



-- Test vector is placed on the input stream, one word per clock edge
-- Idle words are placed on the input stream during resets and when back pressured
data_stream : process(clk)
begin
	if( rst = '1') then
		TV_index 	<= 0;
		word_index 	<= 0;
		L0ID_count 	<= 0;
		din 			<= IDLE_WORD;
		metadata 	<= '0';
		valid_data 	<= '0';
	elsif( rising_edge(clk) ) then

		if (halt_out = '0') then
			if (ready = '1') then
				TV_sending <= true;
			end if;

			if (TV_sending) then
				valid_data 	<= '1';
				if (META_ON_RIGHT) then
					din 		<= text_data(TV_index)(word_index)(67 downto 4);
					metadata <= text_data(TV_index)(word_index)(0);
				else
					metadata <= text_data(TV_index)(word_index)(64);
					din 		<= text_data(TV_index)(word_index)(63 downto 0);
				end if;

				if (word_index = TV_length(TV_index)-1) then
					word_index <= 0;
					L0ID_count <= L0ID_count + 1;
					TV_sending <= false;
					if (TV_index = TV_loaded-1) then
						TV_index <= 0;
					else
						TV_index <= TV_index + 1;
					end if;
				else
					word_index <= word_index + 1;
				end if;

				if (INCREMENT_L0ID and word_index = 0) then
					din(39 downto 0)	<= std_logic_vector(to_unsigned(L0ID_count, 40));
				end if;

			else
				din 			<= IDLE_WORD;
				metadata 	<= '0';
				valid_data	<= '0';
				word_index 	<= 0;
				TV_index 	<= TV_index;
			end if;
		else -- back pressured
			din 			<= IDLE_WORD;
			metadata 	<= '0';
			valid_data	<= '0';
			word_index 	<= word_index;
			TV_index 	<= TV_index;
		end if;

	end if;
end process data_stream;



Generate_Constants : process(clk)
begin
	if( rst = '1') then
		Constants_from_HBM <= (others => (others => (others => '0')));
		ModuleID_from_HBM <= (others => (others => '0'));
		SectorID_8L_from_HBM <= (others => '0');
		SectorID_13L_from_HBM <= (others => '0');
		Constants_Ready_from_HBM <= '0';
		read_pipe <= (others => '0');
	elsif( rising_edge(clk) ) then
		if (read_request_to_HBM = '1') then
			SectorID_8L_from_HBM <= SectorID_8L_to_HBM;
			for ii in N_Matrix_Row-1 downto 0 loop
				for jj in N_Matrix_Col downto 0 loop
					Constants_from_HBM(ii)(jj) <= TWO_float; -- one
				end loop;
			end loop;

			for ii in N_Layers_Extrapolated-1 downto 0 loop
				ModuleID_from_HBM(ii) <= std_logic_vector(to_unsigned(1000*ii+122, ModuleID_Length));
			end loop;

			SectorID_13L_from_HBM <= (others => '0');
			for ii in SectorID_8L_Length-1 downto 0 loop
				SectorID_13L_from_HBM(SectorID_8L_Length-ii-1) <= SectorID_8L_to_HBM(ii);
			end loop;
		end if;

		read_pipe(CONSTANT_LATENCY-1) <= read_request_to_HBM;
		for ii in CONSTANT_LATENCY-1 downto 1 loop
			read_pipe(ii-1) <= read_pipe(ii);
		end loop;
		Constants_Ready_from_HBM <= read_pipe(0);

	end if;
end process Generate_Constants;


end behav;
