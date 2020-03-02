library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library work;
use work.Extrapolator_Package.all;


entity Extrapolator_Constants_Loader is
generic (
		N_CONNECTIONS	: INTEGER := 1
);
port (
		clk:			in STD_LOGIC;
		reset:		in STD_LOGIC;

		-- Decoder Interface
		SectorID_8L : in STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0);
		valid_sector : in STD_LOGIC;
		halt_out : out STD_LOGIC;

		--HBM Interface
		SectorID_8L_to_HBM:out STD_LOGIC_VECTOR(SectorID_8L_Length-1 downto 0) := (others => '0');
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
		SectorID_13L : out STD_LOGIC_VECTOR(SectorID_13L_Length-1 downto 0) := (others => '0');
		valid_constants : out STD_LOGIC;
		halt_in:		in	STD_LOGIC
);
end Extrapolator_Constants_Loader;

architecture behavioral of Extrapolator_Constants_Loader is

	component fifo_8LSector is
		port (
			data        : in  std_logic_vector(15 downto 0); -- datain
			wrreq       : in  std_logic                    ;             -- wrreq
			rdreq       : in  std_logic                    ;             -- rdreq
			clock       : in  std_logic                    ;             -- clk
			sclr        : in  std_logic                    ;             -- sclr
			q           : out std_logic_vector(15 downto 0);                    -- dataout
			empty       : out std_logic;                                        -- empty
			almost_full : out std_logic                                         -- almost_full
		);
	end component fifo_8LSector;


	component fifo_13LSector is
		port (
			data        : in  std_logic_vector(15 downto 0); -- datain
			wrreq       : in  std_logic                    ;             -- wrreq
			rdreq       : in  std_logic                    ;             -- rdreq
			clock       : in  std_logic                    ;             -- clk
			sclr        : in  std_logic                    ;             -- sclr
			q           : out std_logic_vector(15 downto 0);                    -- dataout
			empty       : out std_logic;                                        -- empty
			almost_full : out std_logic                                         -- almost_full
		);
	end component fifo_13LSector;






signal read_8L 		: std_logic := '0';
signal read_13L 	: std_logic := '0';
signal empty_8L		: std_logic;
signal empty_13L	: std_logic;
signal halt_13L		: std_logic;
signal waiting		: boolean := false;

begin



	Sectors_8L : fifo_8LSector
		port map (
			data        => SectorID_8L,        --  fifo_input.datain
			wrreq       => valid_sector,       --            .wrreq
			rdreq       => read_8L,       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			q           => SectorID_8L_to_HBM,           -- fifo_output.dataout
			empty       => empty_8L,       --            .empty
			almost_full => halt_out  --            .almost_full
		);


	Sectors_13L : fifo_13LSector
		port map (
			data        => SectorID_13L_from_HBM,        --  fifo_input.datain
			wrreq       => Constants_Ready_from_HBM,       --            .wrreq
			rdreq       => read_13L,       --            .rdreq
			clock       => clk,       --            .clk
			sclr        => reset,        --            .sclr
			q           => SectorID_13L,           -- fifo_output.dataout
			empty       => empty_13L,       --            .empty
			almost_full => halt_13L  --            .almost_full
		);



	-- Waits until constants arrive before sending next request
	-- may need to rewrite to pipeline this stage better
	read_request : process(clk)
	begin
		if (reset = '1') then
			waiting <= false;
			read_8L <= '0';
			read_request_to_HBM <= '0';
		elsif (rising_edge(clk) and (halt_in = '0' or halt_13L = '0')) then
			read_request_to_HBM <= read_8L;
			read_8L <= '0';
			if (not waiting and empty_8L = '0') then
				read_8L <= '1';
				waiting <= true;
			end if;
			if (waiting and Constants_Ready_from_HBM ='1') then
				waiting <= false;
			end if;
		end if;
	end process read_request;


	-- Constants from HBM are piped one clock edge and sent to the Matrix Calculation module
	constants_pipe : process(clk)
	begin
		if (reset = '1') then
			Constants <= (others => (others => (others => '0')));
			ModuleID <= (others => (others => '0'));
			ConstantID_8L <= (others => '0');
			SectorID_13L <= (others => '0');
			valid_constants <= '0';
		elsif (rising_edge(clk) ) then
			Constants <= Constants_from_HBM;
			ConstantID_8L <= SectorID_8L_from_HBM;
			ModuleID <= ModuleID_from_HBM;
			--SectorID_13L <= SectorID_13L_from_HBM;
			valid_constants <= Constants_Ready_from_HBM;
		end if;
	end process constants_pipe;


end behavioral;
