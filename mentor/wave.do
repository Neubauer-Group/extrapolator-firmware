onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/floor/clk
add wave -noupdate /extrapolator_tb/Extrapolator/SSmap/floor/areset
add wave -noupdate -radix float32 /extrapolator_tb/Extrapolator/SSmap/floor/a
add wave -noupdate -radix unsigned /extrapolator_tb/Extrapolator/SSmap/floor/q
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {311981825 fs} 0}
quietly wave cursor active 1
configure wave -namecolwidth 272
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
WaveRestoreZoom {189073671 fs} {587123587 fs}
