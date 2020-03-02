library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_Decoder is
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
end Extrapolator_Decoder;

architecture behavioral of Extrapolator_Decoder is

signal count : INTEGER range 63 downto 0 := 0;
signal ready_i : STD_LOGIC := '0';

signal word_count : INTEGER := 0;
signal data_i : STD_LOGIC_VECTOR(63 downto 0) := (others => '0');
signal valid_i : STD_LOGIC := '0';

type Data_t is (Header, Footer, Track, Idle);
signal Data_type : Data_t := Idle;

signal Hitmap : std_logic_vector(Hitmap_Length-1 downto 0);
signal Detmap : std_logic_vector(Detmap_Length-1 downto 0);

signal layer_index : integer := 0;
signal coordinate_index  : integer := 0;

begin

	halt_out <= halt_in;
	ready	<= ready_i;

	-- Temporary process to initiate packet transfers
	packet_request : process(clk)
	begin
		if (reset = '1') then
			count <= 0;
			ready_i <= '0';
		elsif (rising_edge(clk) and halt_in = '0') then
			if (count = 63) then
				count <= 0;
				ready_i <= '1';
			else
				count <= count + 1;
			end if;
			if (ready_i = '1' and valid_data = '1') then
				ready_i <= '0';
			end if;
		end if;
	end process packet_request;




	data_pipe : process(clk)
	begin
		if (reset = '1') then
			word_count <= 0;
			Data_type <= Idle;
			data_i <= (others => '0');
			valid_i <= '0';
		elsif (rising_edge(clk)) then
			data_i <= din;
			valid_i <= valid_data;
			if (valid_data = '1') then
				word_count <= word_count + 1;
				if (metadata = '1') then
					word_count <= 0;
					if ( din( Flag_Bit + Flag_Length - 1 downto Flag_Bit) = Header_Flag) then
						Data_type <= Header;
					elsif ( din( Flag_Bit + Flag_Length - 1 downto Flag_Bit) = Footer_Flag) then
						Data_type <= Footer;
					else
						Data_type <= Track;
					end if;
				end if;
			else
				if (Data_type = Footer and word_count = Footer_Length - 1) then
					word_count <= 0;
					Data_type <= Idle;
				end if;
			end if;
		end if;
	end process data_pipe;



	sector_parse : process(clk)
	begin
		if (reset = '1') then
			L0ID 			<= (others => '0');
			SectorID_8L <= (others => '0');
			valid_track <= '0';
			Hitmap <= (others => '0');
			Detmap <= (others => '0');
		elsif (rising_edge(clk)) then
			valid_track <= '0';
			if (valid_i = '1') then
				if (Data_type = Header and word_count = L0ID_Word) then
					L0ID <= data_i(L0ID_Bit + L0ID_Length - 1 downto L0ID_Bit);
				end if;
				if (Data_type = Track and word_count = SectorID_8L_Word) then
					SectorID_8L <= data_i(SectorID_8L_Bit + SectorID_8L_Length - 1 downto SectorID_8L_Bit);
				end if;
				if (Data_type = Track and word_count = Hitmap_Word) then
					Hitmap <= data_i(Hitmap_Bit + Hitmap_Length - 1 downto Hitmap_Bit);
				end if;
				if (Data_type = Track and word_count = Detmap_Word) then
					Detmap <= data_i(Detmap_Bit + Detmap_Length - 1 downto Detmap_Bit);
				end if;


				if (Data_type = Track and word_count >= Track_Length and (data_i(0) = '1' or data_i(32) = '1' )) then
					valid_track <= '1';
				end if;
			end if;
		end if;
	end process sector_parse;


	-- This process uses the hitmap and detmap to parse the coordinates
	-- Will probably need to modify as data format changes
	coordinate_parse : process(clk)
	begin
		if (reset = '1') then
			Coordinates <= (others => (others => '0'));
			layer_index <= 0;
			coordinate_index <= 0;
		elsif (rising_edge(clk)) then
			if (valid_i = '1') then
				if (Data_type = Track and word_count >= Track_Length) then
					if (Hitmap(Stage1_Layers(layer_index)) = '1' and Detmap(Stage1_Layers(layer_index)) = '0') then --Pixel Word
						Coordinates(coordinate_index)(Pix_Eta_Length-1 downto 0) <= data_i(Pix_Eta_Bit + Pix_Eta_Length - 1 downto Pix_Eta_Bit);
						Coordinates(coordinate_index + 1)(Pix_Phi_Length-1 downto 0) <= data_i(Pix_Phi_Bit + Pix_Phi_Length - 1 downto Pix_Phi_Bit);
						if (data_i(0) = '1') then
							layer_index <= 0;
							coordinate_index <= 0;
						else
							layer_index <= layer_index + 1;
							coordinate_index <= coordinate_index + 2;
						end if;
					elsif (Hitmap(Stage1_Layers(layer_index)) = '1' and Detmap(Stage1_Layers(layer_index)) = '1') then --Strip Words
						Coordinates(coordinate_index)(Strip_Idx_Length-1 downto 0) <= data_i(32 + Strip_Idx_Bit + Strip_Idx_Length - 1 downto 32 + Strip_Idx_Bit);
						if (data_i(32) = '1') then
							layer_index <= 0;
							coordinate_index <= 0;
						elsif (data_i(0) = '1') then
							Coordinates(coordinate_index + 1)(Strip_Idx_Length-1 downto 0) <= data_i(Strip_Idx_Bit + Strip_Idx_Length - 1 downto Strip_Idx_Bit);
							layer_index <= 0;
							coordinate_index <= 0;
						else
							Coordinates(coordinate_index + 1)(Strip_Idx_Length-1 downto 0) <= data_i(Strip_Idx_Bit + Strip_Idx_Length - 1 downto Strip_Idx_Bit);
							layer_index <= layer_index + 2;
							coordinate_index <= coordinate_index + 2;
						end if;
					end if;
				end if;
			end if;
		end if;
	end process coordinate_parse;




end behavioral;
