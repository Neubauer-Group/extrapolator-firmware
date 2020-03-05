rm run_simulation.do
touch run_simulation.do

# This is the project folder
echo "set QSYS_SIMDIR /data/firmware/quartus/extrapolator" >> run_simulation.do

# This is the IP core simulation Setup Script, created by Quartus
echo "source \$QSYS_SIMDIR/mentor/msim_setup.tcl" >> run_simulation.do

echo "dev_com" >> run_simulation.do
echo "com" >> run_simulation.do

# List of all the files in the project (that arent IP cores)
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_tb.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Package.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Main.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Decoder.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Constants_Loader.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Matrix_Calculation.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_Row_Solver.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_SSMap.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_SSID_Converter.vhd" >> run_simulation.do
echo "vcom -work work \$QSYS_SIMDIR/Extrapolator_SSID_Neighborhood.vhd" >> run_simulation.do


echo "set TOP_LEVEL_NAME extrapolator_tb" >> run_simulation.do
echo "elab" >> run_simulation.do
echo "view signals" >> run_simulation.do
#echo "run -a" >> run_simulation.do


# This attaches the IP Core Simulation Script
echo | cat msim_setup.tcl >> run_simulation.do

# This is the waveform configuration file, created by ModelSim
echo "do \$QSYS_SIMDIR/mentor/wave.do " >> run_simulation.do
