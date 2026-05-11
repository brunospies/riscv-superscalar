################################################
# Original script: Camille Leroux
# Adapted by Mathias Michelotti and Bruno Henrique Spies
# IMS Laboratory Bordeaux
# Design Compiler synthesis script
################################################

################################################
# 1. INITIALIZATION
################################################

# execute setup script
source ./synopsys_dc.setup

# top level
set MON_TOP_LEVEL RISCV_superscalar

# architecture name
set MON_ARCHI structural

# clock port name
set CLK_PORT clock

# target frequency (MHz)
set FREQ_MHZ 30.0

# RTL path
set RTL_PATH ../../rtl/core/

# clock period (ns)
set CLK_PERIOD [expr 1000.0 / $FREQ_MHZ]

# timing parameters
set CLK_SKEW 0.0
set JITTER 0.0
set MARGIN 0.0

set CLK_UNCERTAINTY [expr $CLK_SKEW + $JITTER + $MARGIN]

# IO delays
set INPUT_DELAY  [expr 0.1 * $CLK_PERIOD]
set OUTPUT_DELAY [expr 0.1 * $CLK_PERIOD]

################################################
# 2. LIBRARIES
################################################

define_design_lib WORK -path ./WORK

################################################
# 3. ANALYZE RTL FILES
################################################

puts "== ANALYZE VHDL FILES =="

# =========================================================
# PACKAGES
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}RISCV_package.vhd

# =========================================================
# LOW LEVEL BLOCKS
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}RegisterNbits.vhd
analyze -library WORK -format vhdl ${RTL_PATH}shift_unit.vhd
analyze -library WORK -format vhdl ${RTL_PATH}ImmediateDataExtractor.vhd
analyze -library WORK -format vhdl ${RTL_PATH}CSR_module.vhd

# =========================================================
# COMBINATIONAL BLOCKS
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}ALU.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Decode_unit.vhd
# analyze -library WORK -format vhdl ${RTL_PATH}BranchDetection_unit.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Forwarding_unit.vhd
analyze -library WORK -format vhdl ${RTL_PATH}HazardDetection_unit.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Double_issue_dep.vhd

# =========================================================
# PIPELINE STAGES
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}Stage_ID.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Stage_EX.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Stage_MEM.vhd
analyze -library WORK -format vhdl ${RTL_PATH}Stage_WB.vhd

# =========================================================
# ARCHITECTURAL BLOCKS
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}RegisterFile.vhd
analyze -library WORK -format vhdl ${RTL_PATH}BTB_SuperScalar.vhd
analyze -library WORK -format vhdl ${RTL_PATH}ControlPath.vhd
analyze -library WORK -format vhdl ${RTL_PATH}DataPath.vhd

# =========================================================
# CPU CORE ONLY
# =========================================================

analyze -library WORK -format vhdl ${RTL_PATH}RISCV_superscalar.vhd

################################################
# 4. ELABORATION
################################################

puts "== ELABORATION =="

elaborate $MON_TOP_LEVEL \
          -arch $MON_ARCHI \
          -lib WORK

current_design $MON_TOP_LEVEL

link

uniquify

################################################
# 5. APPLY TIMING CONSTRAINTS
################################################

puts "== APPLY CONSTRAINTS =="

# create clock
create_clock -name my_clock \
              -period $CLK_PERIOD \
              [get_ports $CLK_PORT]

# avoid clock optimization
set_dont_touch_network my_clock

# wireload model
set_wire_load_mode segmented

# clock uncertainty
set_clock_uncertainty -setup \
    $CLK_UNCERTAINTY \
    [get_clocks my_clock]

set_clock_uncertainty -hold \
    $CLK_UNCERTAINTY \
    [get_clocks my_clock]

# input delays
set_input_delay \
    $INPUT_DELAY \
    -clock my_clock \
    [remove_from_collection \
        [all_inputs] \
        [get_ports $CLK_PORT]]

# output delays
set_output_delay \
    $OUTPUT_DELAY \
    -clock my_clock \
    [all_outputs]

################################################
# 6. DESIGN CHECK
################################################

puts "== CHECK DESIGN =="

check_design

################################################
# 7. SYNTHESIS
################################################

puts "== COMPILE ULTRA =="

compile_ultra

################################################
# 8. REPORTS
################################################

file mkdir report

puts "== GENERATING REPORTS =="

report_timing > ./report/$MON_TOP_LEVEL.timing
report_area   > ./report/$MON_TOP_LEVEL.area
report_power  > ./report/$MON_TOP_LEVEL.power
report_clock  > ./report/$MON_TOP_LEVEL.clk
report_qor    > ./report/$MON_TOP_LEVEL.qor

################################################
# 9. EXPORT RESULTS
################################################

puts "== EXPORT RESULTS =="

# sdf
write_sdf ./$MON_TOP_LEVEL\_syn.sdf

# synthesized netlist
write -hierarchy \
      -format verilog \
      -output ./$MON_TOP_LEVEL\_syn.v

# constraints for P&R
write_sdc ./$MON_TOP_LEVEL\_syn.sdc

################################################
# 10. SAVE DESIGN
################################################

write -hierarchy -format ddc \
      -output ./$MON_TOP_LEVEL.ddc

puts "== SYNTHESIS COMPLETED SUCCESSFULLY =="
