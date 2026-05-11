#######################################################
#                                                     #
#  Encounter Command Logging File                     #
#  Created on Mon May 11 09:59:21 2026                #
#                                                     #
#######################################################

#@(#)CDS: Encounter v13.13-s017_1 (64bit) 07/30/2013 13:03 (Linux 2.6)
#@(#)CDS: NanoRoute v13.13-s005 NR130716-1135/13_10-UB (database version 2.30, 190.4.1) {superthreading v1.19}
#@(#)CDS: CeltIC v13.13-s001_1 (64bit) 07/19/2013 04:50:05 (Linux 2.6.18-194.el5)
#@(#)CDS: AAE 13.13-e003 (64bit) 07/30/2013 (Linux 2.6.18-194.el5)
#@(#)CDS: CTE 13.13-s004_1 (64bit) Jul 30 2013 05:44:27 (Linux 2.6.18-194.el5)
#@(#)CDS: CPE v13.13-s001
#@(#)CDS: IQRC/TQRC 12.1.1-s225 (64bit) Wed Jun 12 20:28:41 PDT 2013 (Linux 2.6.18-194.el5)

set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
suppressMessage ENCEXT-2799
win
setDesignMode -process 130 -flowEffort high
set_global _enable_mmmc_by_default_flow      $CTE::mmmc_default
set defHierChar /
set defHierChar /
set init_verilog ../../synthesis/RISCV_superscalar_syn.v
set init_top_cell RISCV_superscalar
set init_design_settop 1
set init_design_netlisttype Verilog
set init_lef_file { /opt/ams/cds/HK_C35/LEF/c35b3/c35b3.lef  /opt/ams/cds/HK_C35/LEF/c35b3/CORELIB.lef}
set init_mmmc_file ../mmmc_definition.tcl
set init_cpf_file {}
set init_import_mode {-treatUndefinedCellAsBbox 0 -keepEmptyModule 1}
set init_assign_buffer 0
set init_pwr_net vdd!
set init_gnd_net gnd!
set init_oa_search_lib {}
init_design
