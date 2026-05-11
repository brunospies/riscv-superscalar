############################################################
# MMMC DEFINITION FILE
# RISCV SUPERSCALAR
# AMS C35
############################################################

############################################################
# LIBRARY SETS
############################################################

# WORST CASE
create_library_set \
   -name libset_max \
   -timing [list \
      ${AMS_DIR}/liberty/c35_1.8V/c35_CORELIB_WC.lib \
      ${AMS_DIR}/liberty/c35_1.8V/c35_IOLIB_3B_WC.lib \
   ]

# BEST CASE
create_library_set \
   -name libset_min \
   -timing [list \
      ${AMS_DIR}/liberty/c35_1.8V/c35_CORELIB_BC.lib \
      ${AMS_DIR}/liberty/c35_1.8V/c35_IOLIB_3B_BC.lib \
   ]

############################################################
# RC CORNERS
############################################################

# WORST RC
create_rc_corner \
   -name rc_corner_worst \
   -cap_table ${AMS_DIR}/cds/HK_C35/LEF/encounter/c35b3-worst.capTable

# BEST RC
create_rc_corner \
   -name rc_corner_best \
   -cap_table ${AMS_DIR}/cds/HK_C35/LEF/encounter/c35b3-best.capTable

############################################################
# DELAY CORNERS
############################################################

# SETUP ANALYSIS
create_delay_corner \
   -name delay_corner_max \
   -library_set libset_max \
   -rc_corner rc_corner_worst

# HOLD ANALYSIS
create_delay_corner \
   -name delay_corner_min \
   -library_set libset_min \
   -rc_corner rc_corner_best

############################################################
# OCV CORNER (OPTIONAL)
############################################################

create_delay_corner \
   -name delay_corner_ocv \
   -rc_corner rc_corner_worst \
   -early_library_set libset_min \
   -late_library_set libset_max

############################################################
# CONSTRAINT MODE
############################################################

create_constraint_mode \
   -name constraint_mode \
   -sdc_files [list ../../synthesis/RISCV_superscalar_syn.sdc]

############################################################
# ANALYSIS VIEWS
############################################################

# SETUP VIEW
create_analysis_view \
   -name analysis_view_setup \
   -constraint_mode constraint_mode \
   -delay_corner delay_corner_max

# HOLD VIEW
create_analysis_view \
   -name analysis_view_hold \
   -constraint_mode constraint_mode \
   -delay_corner delay_corner_min

############################################################
# APPLY ANALYSIS VIEWS
############################################################

set_analysis_view \
   -setup [list analysis_view_setup] \
   -hold  [list analysis_view_hold]

############################################################
# END
############################################################
