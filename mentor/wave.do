onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/clk
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/reset
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/ModuleID
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/valid_module
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/Coordinates_exp_float
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/valid_exp_result
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/halt_out
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/halt_in
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/Coordinates_exp_float_i
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/coordinates_exp_empty
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/coordinates_exp_almost_full
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/ModuleID_i
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/modules_empty
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/modules_almost_full
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/calculating
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/read_enable
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_module
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_coordinate
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_count
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_counter
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_module
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_phi_coordinate
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_eta_coordinate
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_count
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_counter
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_ssid_center
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_ssid_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_neighborhood_halt
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_converter_halt
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_neighborhood_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/pix_SSID_neighbors
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_ssid_center
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_ssid_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_neighborhood_halt
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_converter_halt
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_neighborhood_valid
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/strip_SSID_neighbors
add wave -noupdate -childformat {{/extrapolator_tb/Extrapolator/SSmap/ssid_in(38) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(37) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(36) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(35) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(34) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(33) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(32) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(31) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(30) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(29) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(28) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(27) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(26) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(25) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(24) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(23) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(22) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(21) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(20) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(19) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(18) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(17) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(16) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(15) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(14) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(13) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(12) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(11) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(10) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(9) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(8) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(7) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(6) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(5) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(4) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(3) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(2) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(1) -radix unsigned} {/extrapolator_tb/Extrapolator/SSmap/ssid_in(0) -radix unsigned}} -expand -subitemconfig {/extrapolator_tb/Extrapolator/SSmap/ssid_in(38) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(37) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(36) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(35) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(34) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(33) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(32) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(31) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(30) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(29) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(28) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(27) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(26) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(25) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(24) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(23) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(22) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(21) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(20) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(19) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(18) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(17) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(16) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(15) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(14) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(13) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(12) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(11) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(10) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(9) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(8) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(7) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(6) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(5) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(4) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(3) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(2) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(1) {-radix unsigned} /extrapolator_tb/Extrapolator/SSmap/ssid_in(0) {-radix unsigned}} /extrapolator_tb/Extrapolator/SSmap/ssid_in
add wave -noupdate -expand /extrapolator_tb/Extrapolator/SSmap/ssid_write
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/ssid_empty
add wave -noupdate -expand /extrapolator_tb/Extrapolator/SSmap/ssid_almost_full
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {44075723721 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 423
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits fs
update
WaveRestoreZoom {43832400777 fs} {44517817521 fs}
