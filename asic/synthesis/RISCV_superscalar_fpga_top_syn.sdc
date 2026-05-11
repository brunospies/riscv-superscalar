###################################################################

# Created by write_sdc on Sat May  9 15:35:56 2026

###################################################################
set sdc_version 2.0

set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA
set_wire_load_mode segmented
create_clock [get_ports clock]  -name my_clock  -period 25  -waveform {0 12.5}
set_clock_uncertainty 0  [get_clocks my_clock]
set_input_delay -clock my_clock  2.5  [get_ports reset]
set_input_delay -clock my_clock  2.5  [get_ports rx]
set_input_delay -clock my_clock  2.5  [get_ports mem_scan]
set_output_delay -clock my_clock  2.5  [get_ports tx]
set_output_delay -clock my_clock  2.5  [get_ports done_led]
