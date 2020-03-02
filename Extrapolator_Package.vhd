library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package Extrapolator_Package is

-- Constants for layers
constant N_PIX_Layers_Stage1 : integer := 1;
constant N_STRIP_Layers_Stage1 : integer := 7;
constant N_Layers_Stage1 : integer := N_PIX_Layers_Stage1 + N_STRIP_Layers_Stage1;
constant N_Coordinates_Stage1 : integer := 2*N_PIX_Layers_Stage1 + N_STRIP_Layers_Stage1;

constant N_PIX_Layers_Extrapolated : integer := 4;
constant N_STRIP_Layers_Extrapolated : integer := 1;
constant N_Layers_Extrapolated : integer := N_PIX_Layers_Extrapolated + N_STRIP_Layers_Extrapolated;
constant N_Coordinates_Extrapolated : integer := 2*N_PIX_Layers_Extrapolated + N_STRIP_Layers_Extrapolated;

constant N_PIX_Layers_Stage2 : integer := N_PIX_Layers_Stage1 + N_PIX_Layers_Extrapolated;
constant N_STRIP_Layers_Stage2 : integer := N_STRIP_Layers_Stage1 + N_STRIP_Layers_Extrapolated;
constant N_Layers_Stage2 : integer := N_PIX_Layers_Stage2 + N_STRIP_Layers_Stage2;
constant N_Coordinates_Stage2 : integer := 2*N_PIX_Layers_Stage2 + N_STRIP_Layers_Stage2;

type coordinate_array_stage1_int is array (N_Coordinates_Stage1-1 downto 0) of std_logic_vector(15 downto 0);
type coordinate_array_stage1_float is array (N_Coordinates_Stage1-1 downto 0) of std_logic_vector(31 downto 0);
type coordinate_array_exp_float is array (N_Coordinates_Extrapolated-1 downto 0) of std_logic_vector(31 downto 0);
type layer_map_stage1 is array (N_Layers_Stage1-1 downto 0) of integer range N_Layers_Stage2-1 downto 0;
constant Stage1_Layers : layer_map_stage1 := (11, 10, 9, 8, 7, 6, 5, 0);


-- Constants for Extrapolation Constants
constant N_Constants_Bit : integer := 32;
constant N_Constants : integer := 90;
constant N_Matrix_Row : integer := N_Coordinates_Extrapolated;
constant N_Matrix_Col : integer := N_Coordinates_Stage1;

type constant_row_array is array (N_Matrix_Col downto 0) of std_logic_vector(N_Constants_Bit-1 downto 0);
type constant_array is array (N_Matrix_Row-1 downto 0) of constant_row_array;
type constant_flag_array is array (N_Matrix_Row-1 downto 0) of std_logic_vector(N_Matrix_Col downto 0);

constant ONE_float : std_logic_vector(31 downto 0) := X"3F800000";
constant TWO_float : std_logic_vector(31 downto 0) := X"40000000";

constant ModuleID_Length : integer := 18;
type module_array is array (N_Layers_Extrapolated-1 downto 0) of std_logic_vector(ModuleID_Length-1 downto 0);


-- Data Blocks
constant Header_Length : integer := 6;
constant Header_Flag : std_logic_vector(7 downto 0) := X"AB";
constant Footer_Length : integer := 3;
constant Footer_Flag : std_logic_vector(7 downto 0) := X"CD";
constant Track_Length : integer := 3;
constant Flag_Length : integer := 8;
constant Flag_Bit : integer := 56;

-- Event Header
constant L0ID_Length : integer := 40;
constant L0ID_Word : integer := 0;
constant L0ID_Bit : integer := 0;

-- Track Block Header
constant Hitmap_Length : integer := 13;
constant Hitmap_Word : integer := 0;
constant Hitmap_Bit : integer := 13;
constant Detmap_Length : integer := 13;
constant Detmap_Word : integer := 0;
constant Detmap_Bit : integer := 0;
constant SectorID_8L_Length : integer := 16;
constant SectorID_8L_Word : integer := 1;
constant SectorID_8L_Bit : integer := 48;
constant SectorID_13L_Length : integer := 16;
constant SectorID_13L_Word : integer := 1;
constant SectorID_13L_Bit : integer := 32;

-- Pixal Cluster
constant Pix_Eta_Length : integer := 13;
constant Pix_Eta_Bit : integer := 19;
constant Pix_Phi_Length : integer := 13;
constant Pix_Phi_Bit : integer := 6;

-- Strip Cluster
constant Strip_Idx_Length : integer := 11;
constant Strip_Idx_Bit : integer := 4;


end package Extrapolator_Package;


package body Extrapolator_Package is

end package body Extrapolator_Package;
