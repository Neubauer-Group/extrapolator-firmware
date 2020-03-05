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

		ssid_out: out ssid_array;
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


	component module_id_fifo is
		port (
			data        : in  std_logic_vector(17 downto 0) := (others => 'X'); -- datain
			wrreq       : in  std_logic                     := 'X';             -- wrreq
			rdreq       : in  std_logic                     := 'X';             -- rdreq
			clock       : in  std_logic                     := 'X';             -- clk
			sclr        : in  std_logic                     := 'X';             -- sclr
			q           : out std_logic_vector(17 downto 0);                    -- dataout
			empty       : out std_logic;                                        -- empty
			almost_full : out std_logic                                         -- almost_full
		);
	end component module_id_fifo;


	component Extrapolator_SSID_Converter
		generic (
			N_COORDINATES			 : INTEGER := 2;
			SCALE_COORDINATE_1 : STD_LOGIC_VECTOR(31 downto 0) := X"3D000000"; --float strip/phi
			SCALE_COORDINATE_2 : STD_LOGIC_VECTOR(31 downto 0) := X"3D4CCCCD"; --float eta
			N_SS_PER_MODULE    : INTEGER := 360;
			N_SS_PER_ROW       : INTEGER := 20
		);
		port (
		  clk          : in  STD_LOGIC;
		  reset        : in  STD_LOGIC;
		  moduleID     : in  STD_LOGIC_VECTOR(ModuleID_Length-1 downto 0);
		  coordinate_1 : in  STD_LOGIC_VECTOR(31 downto 0);
		  coordinate_2 : in  STD_LOGIC_VECTOR(31 downto 0) := (others => '0');
		  valid_in     : in  STD_LOGIC;
		  halt_out     : out STD_LOGIC;
		  SSID         : out STD_LOGIC_VECTOR(SSID_Length-1 downto 0);
		  valid_out    : out STD_LOGIC;
		  halt_in      : in  STD_LOGIC
		);
	end component Extrapolator_SSID_Converter;


	component Extrapolator_SSID_Neighborhood
		generic (
		  N_COORDINATES   : INTEGER := 2;
		  N_SS_PER_MODULE : INTEGER := 360;
		  N_SS_PER_ROW    : INTEGER := 20
		);
		port (
		  clk       : in  STD_LOGIC;
		  reset     : in  STD_LOGIC;

			SSID_center : in  STD_LOGIC_VECTOR(SSID_Length-1 downto 0);
		  valid_in  : in  STD_LOGIC;
		  halt_out  : out STD_LOGIC;

			SSID_pix_neighborhood   : out ssid_pix_neighborhood_array;
			SSID_strip_neighborhood : out ssid_strip_neighborhood_array;
		  valid_out : out STD_LOGIC;
		  halt_in   : in  STD_LOGIC
		);
	end component Extrapolator_SSID_Neighborhood;

	component ssid_fifo is
		port (
			data        : in  std_logic_vector(15 downto 0) := (others => 'X'); -- datain
			wrreq       : in  std_logic                     := 'X';             -- wrreq
			rdreq       : in  std_logic                     := 'X';             -- rdreq
			clock       : in  std_logic                     := 'X';             -- clk
			sclr        : in  std_logic                     := 'X';             -- sclr
			q           : out std_logic_vector(15 downto 0);                    -- dataout
			empty       : out std_logic;                                        -- empty
			almost_full : out std_logic                                         -- almost_full
		);
	end component ssid_fifo;


signal Coordinates_exp_float_i : coordinate_array_exp_float;
signal coordinates_exp_empty : std_logic_vector(N_Coordinates_Extrapolated-1 downto 0) := (others => '0');
signal coordinates_exp_almost_full : std_logic_vector(N_Coordinates_Extrapolated-1 downto 0) := (others => '0');

signal ModuleID_i : module_array;
signal modules_empty : std_logic_vector(N_Layers_Extrapolated-1 downto 0) := (others => '0');
signal modules_almost_full : std_logic_vector(N_Layers_Extrapolated-1 downto 0) := (others => '0');

signal calculating : boolean := false;
signal read_enable : std_logic := '0';

signal strip_module : std_logic_vector(ModuleID_Length-1 downto 0) := (others => '0');
signal strip_coordinate : std_logic_vector(31 downto 0) := (others => '0');
signal strip_valid : std_logic := '0';
signal strip_count : integer := 0;
signal strip_counter : integer := 0;

signal pix_module : std_logic_vector(ModuleID_Length-1 downto 0) := (others => '0');
signal pix_phi_coordinate : std_logic_vector(31 downto 0) := (others => '0');
signal pix_eta_coordinate : std_logic_vector(31 downto 0) := (others => '0');
signal pix_valid : std_logic := '0';
signal pix_count : integer := 0;
signal pix_counter : integer := 0;

signal pix_ssid_center : std_logic_vector(SSID_Length-1 downto 0) := (others => '0');
signal pix_ssid_valid : std_logic := '0';
signal pix_neighborhood_halt : std_logic := '0';
signal pix_converter_halt : std_logic := '0';
signal pix_neighborhood_valid : std_logic := '0';
signal pix_SSID_neighbors : ssid_pix_neighborhood_array;

signal strip_ssid_center : std_logic_vector(SSID_Length-1 downto 0) := (others => '0');
signal strip_ssid_valid : std_logic := '0';
signal strip_neighborhood_halt : std_logic := '0';
signal strip_converter_halt : std_logic := '0';
signal strip_neighborhood_valid : std_logic := '0';
signal strip_SSID_neighbors : ssid_strip_neighborhood_array;

signal ssid_in : ssid_array := (others => (others => '0'));
signal ssid_write : std_logic_vector(SSID_total-1 downto 0) := (others => '0');
signal ssid_empty : std_logic_vector(SSID_total-1 downto 0) := (others => '0');
signal ssid_almost_full : std_logic_vector(SSID_total-1 downto 0) := (others => '0');

begin

halt_out <= coordinates_exp_almost_full(0) or modules_almost_full(0);

GEN_Coordinates : for i in N_Coordinates_Extrapolated-1 downto 0 generate
	coordinate_exp_fifos : fifo_float32
		port map (
			data        => Coordinates_exp_float(i),        --  fifo_input.datain
			wrreq       => valid_exp_result,       --            .wrreq
			rdreq       => read_enable,       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			q           => Coordinates_exp_float_i(i),           -- fifo_output.dataout
			empty       => coordinates_exp_empty(i),       --            .empty
			almost_full => coordinates_exp_almost_full(i)  --            .almost_full
		);
end generate GEN_Coordinates;


GEN_Modules : for i in N_Layers_Extrapolated-1 downto 0 generate
module_id_fifos : module_id_fifo
	port map (
		data        => ModuleID(i),        --  fifo_input.datain
		wrreq       => valid_module,       --            .wrreq
		rdreq       => read_enable,       --            .rdreq
		clock       => clk,       --            .clk
		sclr        => reset,        --            .sclr
		q           => ModuleID_i(i),           -- fifo_output.dataout
		empty       => modules_empty(i),       --            .empty
		almost_full => modules_almost_full(i)  --            .almost_full
	);
end generate GEN_Modules;


PIX_SSID_Converter : Extrapolator_SSID_Converter
	generic map (
	  N_COORDINATES 			=> 2,
		SCALE_COORDINATE_1 	=> X"3D000000", --float phi = 1/32
		SCALE_COORDINATE_2 	=> X"3D4CCCCD", --float eta = 1/20
		N_SS_PER_MODULE 		=> 360,
		N_SS_PER_ROW 				=> 20
	)
	port map (
	  clk          => clk,
	  reset        => reset,
	  moduleID     => pix_module,
	  coordinate_1 => pix_phi_coordinate,
	  coordinate_2 => pix_eta_coordinate,
	  valid_in     => pix_valid,
	  halt_out     => pix_converter_halt,
	  SSID         => pix_ssid_center,
	  valid_out    => pix_ssid_valid,
	  halt_in      => pix_neighborhood_halt
	);


PIX_SSID_Neighborhood : Extrapolator_SSID_Neighborhood
	generic map (
	  N_COORDINATES   => 2,
	  N_SS_PER_MODULE => 360,
	  N_SS_PER_ROW    => 20
	)
	port map (
	  clk       => clk,
	  reset     => reset,
	  SSID_center => pix_ssid_center,
	  valid_in  => pix_ssid_valid,
	  halt_out  => pix_neighborhood_halt,
		SSID_pix_neighborhood => pix_SSID_neighbors,
		--SSID_strip_neighborhood => ,
	  valid_out => pix_neighborhood_valid,
	  halt_in   =>  ssid_almost_full(0)
	);


STRIP_SSID_Converter : Extrapolator_SSID_Converter
	generic map (
		N_COORDINATES 			=> 1,
		SCALE_COORDINATE_1 	=> X"3DAAAAAB", --float strip = 1/12
		N_SS_PER_MODULE 		=> 480
	)
	port map (
	  clk          => clk,
	  reset        => reset,
	  moduleID     => strip_module,
	  coordinate_1 => strip_coordinate,
	  coordinate_2 => open,
	  valid_in     => strip_valid,
	  halt_out     => strip_converter_halt,
	  SSID         => strip_ssid_center,
	  valid_out    => strip_ssid_valid,
	  halt_in      => strip_neighborhood_halt
	);


STRIP_SSID_Neighborhood : Extrapolator_SSID_Neighborhood
	generic map (
	  N_COORDINATES   => 1,
	  N_SS_PER_MODULE => 480
	)
	port map (
	  clk       => clk,
	  reset     => reset,
	  SSID_center => strip_ssid_center,
	  valid_in  => strip_ssid_valid,
	  halt_out  => strip_neighborhood_halt,
		--SSID_pix_neighborhood => ,
		SSID_strip_neighborhood => strip_SSID_neighbors,
	  valid_out => strip_neighborhood_valid,
	  halt_in   => ssid_almost_full(0)
	);


GEN_SSID : for i in SSID_total-1 downto 0 generate
	ssid_fifos : ssid_fifo
		port map (
			data        => ssid_in(i),        --  fifo_input.datain
			wrreq       => ssid_write(i),       --            .wrreq
			rdreq       => '0',       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			q           => ssid_out(i),           -- fifo_output.dataout
			empty       => ssid_empty(i),       --            .empty
			almost_full => ssid_almost_full(i)  --            .almost_full
		);
end generate GEN_SSID;


	state : process(clk)
	begin
		if (reset = '1') then
			calculating <= false;
			read_enable <= '0';
		elsif (rising_edge(clk)) then
			read_enable <= '0';
			if (calculating) then
				if (pix_count >= N_PIX_Layers_Extrapolated and strip_count >= N_STRIP_Layers_Extrapolated) then
					calculating <= false;
				end if;
			else
				if (strip_converter_halt = '0' and
						pix_converter_halt = '0' and
						coordinates_exp_empty(0) = '0' and
						modules_empty(0) = '0') then
					calculating <= true;
					read_enable <= '1';
				end if;
			end if;
		end if;
	end process state;


	strip_data : process(clk)
	begin
		if (reset = '1') then
			strip_valid <= '0';
			strip_count <= 0;
			strip_module <= (others => '0');
			strip_coordinate <= (others => '0');
		elsif (rising_edge(clk)) then
			strip_valid <= '0';
			if (calculating) then
				strip_count <= strip_count + 1;
				if (strip_count > 0 and strip_count <= N_STRIP_Layers_Extrapolated) then
					strip_module <= ModuleID_i(N_PIX_Layers_Extrapolated+strip_count-1);
					strip_coordinate <= Coordinates_exp_float_i(2*N_PIX_Layers_Extrapolated+strip_count-1);
					strip_valid <= '1';
				end if;
			else
				if (coordinates_exp_empty(0) = '0' and modules_empty(0) = '0') then
					strip_count <= 0;
				end if;
			end if;
		end if;
	end process strip_data;


	pix_data : process(clk)
	begin
		if (reset = '1') then
			pix_valid   <= '0';
			pix_count   <= 0;
			pix_module <= (others => '0');
			pix_eta_coordinate <= (others => '0');
			pix_phi_coordinate <= (others => '0');
		elsif (rising_edge(clk)) then
			pix_valid   <= '0';
			if (calculating) then
				pix_count <= pix_count + 1;
				if (pix_count > 0 and pix_count <= N_PIX_Layers_Extrapolated) then
					pix_module <= ModuleID_i(pix_count-1);
					pix_eta_coordinate <= Coordinates_exp_float_i(2*pix_count-2);
					pix_phi_coordinate <= Coordinates_exp_float_i(2*pix_count-1);
					pix_valid <= '1';
				end if;
			else
				if (coordinates_exp_empty(0) = '0' and modules_empty(0) = '0') then
					pix_count   <= 0;
				end if;
			end if;
		end if;
	end process pix_data;


	write_ssid : process(clk)
	begin
		if (reset = '1') then
			strip_counter <= 0;
			pix_counter <= 0;
			ssid_write <= (others => '0');
		elsif (rising_edge(clk)) then
			ssid_write <= (others => '0');
			pix_counter <= 0;
			if (pix_neighborhood_valid = '1') then
				pix_counter <= pix_counter + 1;
				ssid_in(SSID_pix_neighborhood_size*pix_counter)   <= pix_SSID_neighbors(0);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+1) <= pix_SSID_neighbors(1);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+2) <= pix_SSID_neighbors(2);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+3) <= pix_SSID_neighbors(3);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+4) <= pix_SSID_neighbors(4);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+5) <= pix_SSID_neighbors(5);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+6) <= pix_SSID_neighbors(6);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+7) <= pix_SSID_neighbors(7);
				ssid_in(SSID_pix_neighborhood_size*pix_counter+8) <= pix_SSID_neighbors(8);
				ssid_write(SSID_pix_neighborhood_size*(pix_counter+1)-1 downto SSID_pix_neighborhood_size*pix_counter) <= (others => '1');
			end if;

			strip_counter <= 0;
			if (strip_neighborhood_valid = '1') then
				strip_counter <= strip_counter + 1;
				ssid_in(SSID_pix_neighborhood_size*N_PIX_Layers_Extrapolated+SSID_strip_neighborhood_size*strip_counter)   <= strip_SSID_neighbors(0);
				ssid_in(SSID_pix_neighborhood_size*N_PIX_Layers_Extrapolated+SSID_strip_neighborhood_size*strip_counter+1) <= strip_SSID_neighbors(1);
				ssid_in(SSID_pix_neighborhood_size*N_PIX_Layers_Extrapolated+SSID_strip_neighborhood_size*strip_counter+2) <= strip_SSID_neighbors(2);
				ssid_write(SSID_pix_neighborhood_size*N_PIX_Layers_Extrapolated+SSID_strip_neighborhood_size*(strip_counter+1)-1 downto SSID_pix_neighborhood_size*N_PIX_Layers_Extrapolated+SSID_strip_neighborhood_size*strip_counter) <= (others => '1');
			end if;
		end if;
	end process write_ssid;

end behavioral;
