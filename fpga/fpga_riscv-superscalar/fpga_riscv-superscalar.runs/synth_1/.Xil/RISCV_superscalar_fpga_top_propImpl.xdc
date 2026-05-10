set_property SRC_FILE_INFO {cfile:C:/Users/Bruno/OneDrive/Documents/ENSEIRB/S8/Projet-Thematique/riscv-superscalar/fpga_riscv-superscalar/fpga_riscv-superscalar.srcs/constrs_1/new/NexysA7_100t.xdc rfile:../../../fpga_riscv-superscalar.srcs/constrs_1/new/NexysA7_100t.xdc id:1} [current_design]
set_property src_info {type:XDC file:1 line:8 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clock }]; #IO_L12P_T1_MRCC_35 Sch=clk100mhz
set_property src_info {type:XDC file:1 line:14 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN L16   IOSTANDARD LVCMOS33 } [get_ports { reset }]; #IO_L3N_T0_DQS_EMCCLK_14 Sch=sw[1]
set_property src_info {type:XDC file:1 line:32 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN K15   IOSTANDARD LVCMOS33 } [get_ports { done_led }]; #IO_L24P_T3_RS1_15 Sch=led[1]
set_property src_info {type:XDC file:1 line:78 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { mem_scan }]; #IO_L9P_T1_DQS_14 Sch=btnc
set_property src_info {type:XDC file:1 line:186 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN C4    IOSTANDARD LVCMOS33 } [get_ports { rx }]; #IO_L7P_T1_AD6P_35 Sch=uart_txd_in
set_property src_info {type:XDC file:1 line:187 export:INPUT save:INPUT read:READ} [current_design]
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { tx }]; #IO_L11N_T1_SRCC_35 Sch=uart_rxd_out
