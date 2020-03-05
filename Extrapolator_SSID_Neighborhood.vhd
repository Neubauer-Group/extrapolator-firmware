library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_SSID_Neighborhood is
generic (
		N_COORDINATES		  : INTEGER := 2;
		N_SS_PER_MODULE   : INTEGER := 360;
		N_SS_PER_ROW      : INTEGER := 20
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		SSID_center : in STD_LOGIC_VECTOR(SSID_Length-1 downto 0);
		valid_in : in STD_LOGIC;
		halt_out : out STD_LOGIC;

		SSID_pix_neighborhood   : out ssid_pix_neighborhood_array;
		SSID_strip_neighborhood : out ssid_strip_neighborhood_array;
		valid_out : out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end Extrapolator_SSID_Neighborhood;

architecture behavioral of Extrapolator_SSID_Neighborhood is

signal SSID_center_int : integer := 0;
signal divide_module : integer := 0;
signal divide_row : integer := 0;
signal valid_pipe : std_logic := '0';

begin

halt_out <= halt_in;

data_pipe : process(clk)
begin
	if (reset = '1') then
		valid_out <= '0';
		valid_pipe <= '0';
		SSID_center_int <= 0;
		divide_module <= 0;
		divide_row <= 0;
	elsif (rising_edge(clk)) then
		valid_pipe <= valid_in;
		valid_out  <= valid_pipe;
		SSID_center_int <= to_integer(unsigned(SSID_center));
		divide_module 	<= to_integer(unsigned(SSID_center)) mod N_SS_PER_MODULE;
		divide_row 			<= to_integer(unsigned(SSID_center)) mod N_SS_PER_ROW;
	end if;
end process data_pipe;


GEN_Pix_Neighbors : if N_COORDINATES > 1 generate
	pix_neighbors : process(clk)
	begin
		if (reset = '1') then
			SSID_pix_neighborhood   <= (others => (others => '0'));
			SSID_strip_neighborhood <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			SSID_pix_neighborhood(0) <= std_logic_vector(to_unsigned(SSID_center_int-N_SS_PER_ROW-1, SSID_Length));
			SSID_pix_neighborhood(1) <= std_logic_vector(to_unsigned(SSID_center_int-N_SS_PER_ROW, SSID_Length));
			SSID_pix_neighborhood(2) <= std_logic_vector(to_unsigned(SSID_center_int-N_SS_PER_ROW+1, SSID_Length));
			SSID_pix_neighborhood(3) <= std_logic_vector(to_unsigned(SSID_center_int-1, SSID_Length));
			SSID_pix_neighborhood(4) <= std_logic_vector(to_unsigned(SSID_center_int, SSID_Length));
			SSID_pix_neighborhood(5) <= std_logic_vector(to_unsigned(SSID_center_int+1, SSID_Length));
			SSID_pix_neighborhood(6) <= std_logic_vector(to_unsigned(SSID_center_int+N_SS_PER_ROW-1, SSID_Length));
			SSID_pix_neighborhood(7) <= std_logic_vector(to_unsigned(SSID_center_int+N_SS_PER_ROW, SSID_Length));
			SSID_pix_neighborhood(8) <= std_logic_vector(to_unsigned(SSID_center_int+N_SS_PER_ROW+1, SSID_Length));

			if (divide_row = 0) then -- left border
				SSID_pix_neighborhood(0) <= (others => '1');
				SSID_pix_neighborhood(3) <= (others => '1');
				SSID_pix_neighborhood(6) <= (others => '1');
			elsif (divide_row = N_SS_PER_ROW-1) then -- right border
				SSID_pix_neighborhood(2) <= (others => '1');
				SSID_pix_neighborhood(5) <= (others => '1');
				SSID_pix_neighborhood(6) <= (others => '1');
			end if;

			if (divide_module < N_SS_PER_ROW) then -- bottom border
				SSID_pix_neighborhood(0) <= (others => '1');
				SSID_pix_neighborhood(1) <= (others => '1');
				SSID_pix_neighborhood(2) <= (others => '1');
			elsif (divide_module >= N_SS_PER_MODULE - N_SS_PER_ROW) then -- top border
				SSID_pix_neighborhood(6) <= (others => '1');
				SSID_pix_neighborhood(7) <= (others => '1');
				SSID_pix_neighborhood(8) <= (others => '1');
			end if;
		end if;
	end process pix_neighbors;
end generate GEN_Pix_Neighbors;


GEN_Strip_Neighbors : if N_COORDINATES <= 1 generate
	strip_neighbors : process(clk)
	begin
		if (reset = '1') then
			SSID_pix_neighborhood   <= (others => (others => '0'));
			SSID_strip_neighborhood <= (others => (others => '0'));
		elsif (rising_edge(clk)) then
			SSID_strip_neighborhood(0) <= std_logic_vector(to_unsigned(SSID_center_int-1, SSID_Length));
			SSID_strip_neighborhood(1) <= std_logic_vector(to_unsigned(SSID_center_int, SSID_Length));
			SSID_strip_neighborhood(2) <= std_logic_vector(to_unsigned(SSID_center_int+1, SSID_Length));

			if (divide_module = 0) then -- left border
				SSID_strip_neighborhood(0) <= (others => '1');
			elsif (divide_module = N_SS_PER_MODULE-1) then -- right border
				SSID_strip_neighborhood(2) <= (others => '1');
			end if;
		end if;
	end process strip_neighbors;
end generate GEN_Strip_Neighbors;

end behavioral;
