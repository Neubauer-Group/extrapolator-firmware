# extrapolator-firmware
Firmware for the HTT-TFM Extrapolator


# Instructions for simulating the code in ModelSim
- Open Extrapolator.qpf in **Quartus Prime**
- Open Compilation Dashboard
  - Click IP Generation  (This may take a while, its generating output files for the included IPs)
  - Click Analysis & Synthesis (compiling the vhd files)
  - Click EDA Netlist Writer
- Go to Tools > Generate SImulator Script for IP  (creates a file called ../mentor/msim_setup.tcl)
- Open a text editor
  - Open the file ../mentor/create_do_file.sh
  - Change the project folder variable to your path "set QSYS_SIMDIR /data/firmware/quartus/extrapolator"
- Open a Terminal window
  - cd ../mentor
  - source create_do_file.sh   (This will take the generated msim_setup.tcl and use it to create run_simulation.do)
- Open **ModelSim**
  - do  mentor/run_simulation.do
