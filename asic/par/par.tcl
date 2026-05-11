############################################################
# PLACE AND ROUTE SCRIPT
# RISCV SUPERSCALAR CORE ONLY
# AMS C35
# Adapted by Mathias Michelotti and Bruno Henrique Spies
############################################################

############################################################
# 1. DESIGN IMPORT
############################################################





#########################
###
### 1. DESIGN IMPORT
###
#########################

set AMS_DIR /opt/ams

setDesignMode -process 130 -flowEffort high

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default

set set_message_limit 100

# On définit le nom de notre Design
set DESIGN_NAME "RISCV_superscalar"

set defHierChar /

set synth_dir synthesis

############################################################
# DESIGN NAME
############################################################

set DESIGN_NAME "RISCV_superscalar"

set defHierChar /

############################################################
# SYNTHESIS DIRECTORY
############################################################

set synth_dir synthesis

############################################################
# IMPORT SYNTHESIZED NETLIST
############################################################

set init_verilog "../../${synth_dir}/${DESIGN_NAME}_syn.v"

set init_top_cell $DESIGN_NAME

set init_design_settop 1

set init_design_netlisttype Verilog

############################################################
# LEF FILES
############################################################

set init_lef_file "\
$AMS_DIR/cds/HK_C35/LEF/c35b3/c35b3.lef \
$AMS_DIR/cds/HK_C35/LEF/c35b3/CORELIB.lef"

############################################################
# MMMC
############################################################

set init_mmmc_file "../mmmc_definition.tcl"

set init_cpf_file {}

set init_import_mode {-treatUndefinedCellAsBbox 0 -keepEmptyModule 1}

set init_assign_buffer 0

############################################################
# GLOBAL NETS
############################################################

set init_pwr_net {vdd!}

set init_gnd_net {gnd!}

set init_oa_search_lib {}

############################################################
# IMPORT DESIGN
############################################################

init_design

############################################################
# 2. FLOORPLAN
############################################################

floorPlan \
    -site standard \
    -r 1.0 0.7 20 20 20 20

redraw

saveDesign ./${DESIGN_NAME}_floorplan.enc

############################################################
# 3. POWER PLANNING
############################################################

############################################################
# CORE RINGS
############################################################

addRing \
    -stacked_via_top_layer MET3 \
    -stacked_via_bottom_layer MET1 \
    -around core \
    -nets {gnd! vdd!} \
    -layer {bottom MET1 top MET1 right MET2 left MET2} \
    -width 1.6 \
    -spacing 1.6 \
    -offset 1.7

############################################################
# CHECK FLOORPLAN
############################################################

verifyGeometry
verify_drc
verifyConnectivity

clearDrc

saveDesign ./${DESIGN_NAME}_power.enc

############################################################
# 4. PLACEMENT
############################################################

############################################################
# MULTI CPU
############################################################

setMultiCpuUsage \
    -localCpu 4

############################################################
# PLACEMENT OPTIONS
############################################################

setPlaceMode \
    -congEffort medium \
    -timingDriven 1 \
    -clkGateAware 1 \
    -powerDriven 0 \
    -placeIOPins 1

############################################################
# PLACE CELLS
############################################################

placeDesign -prePlaceOpt

############################################################
# CHECK PLACEMENT
############################################################

checkPlace ${DESIGN_NAME}.checkPlace

refinePlace

saveDesign ./${DESIGN_NAME}_placed.enc

############################################################
# PRE CTS OPT
############################################################

setOptMode -fixFanoutLoad true

optDesign -preCTS

############################################################
# 5. CLOCK TREE SYNTHESIS
############################################################

cleanupSpecifyClockTree

############################################################
# CLOCK TREE FILE
############################################################

specifyClockTree -file ../Clock.ctstch

############################################################
# BUILD CLOCK TREE
############################################################

clockDesign \
    -specFile ../Clock.ctstch \
    -outDir clock_report

############################################################
# DELETE TRIAL ROUTE
############################################################

deleteTrialRoute

saveDesign ./${DESIGN_NAME}_CTS.enc

############################################################
# POST CTS OPT
############################################################

optDesign -postCTS

############################################################
# 6. POWER ROUTING
############################################################

############################################################
# GLOBAL NET CONNECT
############################################################

globalNetConnect gnd! \
    -type tielo \
    -verbose

globalNetConnect vdd! \
    -type tiehi \
    -verbose

############################################################
# CONNECT STD CELLS
############################################################

globalNetConnect vdd! \
    -type pgpin \
    -pin vdd! \
    -inst * \
    -verbose

globalNetConnect gnd! \
    -type pgpin \
    -pin gnd! \
    -inst * \
    -verbose

############################################################
# APPLY GLOBAL NETS
############################################################

applyGlobalNets

############################################################
# SPECIAL ROUTING
############################################################

sroute \
    -connect {corePin floatingStripe}

verifyGeometry

verify_drc

clearDrc

saveDesign ./${DESIGN_NAME}_preroute.enc

############################################################
# 7. ROUTING
############################################################

############################################################
# GLOBAL + DETAIL ROUTE
############################################################

routeDesign -globalDetail

############################################################
# POST ROUTE OPT
############################################################

setOptMode -fixFanoutLoad true

setAnalysisMode \
    -analysisType onChipVariation \
    -cppr both

optDesign -postRoute -hold

saveDesign ./${DESIGN_NAME}_postroute.enc

############################################################
# 8. ADD FILLERS
############################################################

addFiller \
    -cell \
    FILL1 \
    FILL2 \
    FILL5 \
    FILL10 \
    -prefix FILLER

############################################################
# FINAL CHECKS
############################################################

verifyGeometry

verify_drc

verifyConnectivity \
    -type regular \
    -error 1000 \
    -warning 50

verifyProcessAntenna

clearDrc

############################################################
# 9. REPORTS
############################################################

############################################################
# SETUP TIMING
############################################################

setAnalysisMode -checkType setup

report_timing

############################################################
# HOLD TIMING
############################################################

setAnalysisMode -checkType hold

report_timing

############################################################
# POWER
############################################################

report_power

############################################################
# AREA
############################################################

report_area

############################################################
# 10. EXPORT
############################################################

if { ! [ file exists ../Results ] } {
    file mkdir ../Results
}

############################################################
# ROUTED NETLIST
############################################################

saveNetlist \
    ../Results/${DESIGN_NAME}_routed.v

############################################################
# RC EXTRACTION
############################################################

rcOut \
    -setload ${DESIGN_NAME}.setload \
    -rc_corner rc_corner_worst

rcOut \
    -setres ${DESIGN_NAME}.setres \
    -rc_corner rc_corner_worst

rcOut \
    -spf ${DESIGN_NAME}.spf \
    -rc_corner rc_corner_worst

rcOut \
    -spef ${DESIGN_NAME}.spef \
    -rc_corner rc_corner_worst

############################################################
# TIMING REPORTS
############################################################

timeDesign \
    -reportOnly \
    -pathReports \
    -drvReports \
    -slackReports \
    -numPaths 50 \
    -prefix ${DESIGN_NAME} \
    -outDir timingReports

############################################################
# EXPORT SDF
############################################################

write_sdf \
    ../Results/${DESIGN_NAME}_routed.sdf

############################################################
# END
############################################################

echo "END OF PLACE AND ROUTE"
