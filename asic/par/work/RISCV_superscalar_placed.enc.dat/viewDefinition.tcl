create_library_set -name libset_min\
   -timing\
    [list /opt/ams/liberty/c35_1.8V/c35_CORELIB_BC.lib\
    /opt/ams/liberty/c35_1.8V/c35_IOLIB_3B_BC.lib]
create_library_set -name libset_max\
   -timing\
    [list /opt/ams/liberty/c35_1.8V/c35_CORELIB_WC.lib\
    /opt/ams/liberty/c35_1.8V/c35_IOLIB_3B_WC.lib]
create_rc_corner -name rc_corner_best\
   -cap_table /opt/ams/cds/HK_C35/LEF/encounter/c35b3-best.capTable\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_rc_corner -name rc_corner_worst\
   -cap_table /opt/ams/cds/HK_C35/LEF/encounter/c35b3-worst.capTable\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0
create_delay_corner -name delay_corner_max\
   -library_set libset_max\
   -rc_corner rc_corner_worst
create_delay_corner -name delay_corner_min\
   -library_set libset_min\
   -rc_corner rc_corner_best
create_delay_corner -name delay_corner_ocv\
   -rc_corner rc_corner_worst\
   -early_library_set libset_min\
   -late_library_set libset_max
create_constraint_mode -name constraint_mode\
   -sdc_files\
    [list ../../synthesis/RISCV_superscalar_syn.sdc]
create_analysis_view -name analysis_view_setup -constraint_mode constraint_mode -delay_corner delay_corner_max
create_analysis_view -name analysis_view_hold -constraint_mode constraint_mode -delay_corner delay_corner_min
set_analysis_view -setup [list analysis_view_setup] -hold [list analysis_view_hold]
