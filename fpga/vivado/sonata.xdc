# default unless otherwise specified:
set_property IOSTANDARD LVCMOS18 [get_ports *]

set_property -dict { PACKAGE_PIN  P15  IOSTANDARD LVCMOS18 } [get_ports { MAINCLK }];
set_property -dict { PACKAGE_PIN  R11  IOSTANDARD LVCMOS18 } [get_ports { NRST }];

set_property -dict { PACKAGE_PIN  C17  IOSTANDARD   LVCMOS18 } [get_ports { ss2_tx }];
set_property -dict { PACKAGE_PIN  D18  IOSTANDARD   LVCMOS18 } [get_ports { ss2_rx }];

set_property -dict { PACKAGE_PIN  B13  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[0] }];
set_property -dict { PACKAGE_PIN  B14  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[1] }];
set_property -dict { PACKAGE_PIN  C12  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[2] }];
set_property -dict { PACKAGE_PIN  B12  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[3] }];
set_property -dict { PACKAGE_PIN  B11  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[4] }];
set_property -dict { PACKAGE_PIN  A11  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[5] }];
set_property -dict { PACKAGE_PIN  F13  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[6] }];
set_property -dict { PACKAGE_PIN  F14  IOSTANDARD   LVCMOS18 } [get_ports { USRLED[7] }];

set_property -dict { PACKAGE_PIN   K6  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[0] }];
set_property -dict { PACKAGE_PIN   L1  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[1] }];
set_property -dict { PACKAGE_PIN   M1  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[2] }];
set_property -dict { PACKAGE_PIN   K3  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[3] }];
set_property -dict { PACKAGE_PIN   L3  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[4] }];
set_property -dict { PACKAGE_PIN   N2  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[5] }];
set_property -dict { PACKAGE_PIN   N1  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[6] }];
set_property -dict { PACKAGE_PIN   M3  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[7] }];
set_property -dict { PACKAGE_PIN   M2  IOSTANDARD   LVCMOS18 } [get_ports { CHERIERR[8] }];

set_property -dict { PACKAGE_PIN   K5  IOSTANDARD   LVCMOS18 } [get_ports { LED_LEGACY }];
set_property -dict { PACKAGE_PIN   L4  IOSTANDARD   LVCMOS18 } [get_ports { LED_CHERI  }];
set_property -dict { PACKAGE_PIN   L6  IOSTANDARD   LVCMOS18 } [get_ports { LED_HALTED }];
set_property -dict { PACKAGE_PIN   L5  IOSTANDARD   LVCMOS18 } [get_ports { LED_BOOTOK }];



set_property -dict { PACKAGE_PIN  D12  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[0] }];
set_property -dict { PACKAGE_PIN  D13  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[1] }];
set_property -dict { PACKAGE_PIN  B16  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[2] }];
set_property -dict { PACKAGE_PIN  B17  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[3] }];
set_property -dict { PACKAGE_PIN  A15  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[4] }];
set_property -dict { PACKAGE_PIN  A16  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[5] }];
set_property -dict { PACKAGE_PIN  A13  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[6] }];
set_property -dict { PACKAGE_PIN  A14  IOSTANDARD   LVCMOS18 } [get_ports { USRSW[7] }];

set_property -dict { PACKAGE_PIN   F5  IOSTANDARD   LVCMOS18 } [get_ports { NAVSW[0] }];
set_property -dict { PACKAGE_PIN   D8  IOSTANDARD   LVCMOS18 } [get_ports { NAVSW[1] }];
set_property -dict { PACKAGE_PIN   C7  IOSTANDARD   LVCMOS18 } [get_ports { NAVSW[2] }];
set_property -dict { PACKAGE_PIN   E7  IOSTANDARD   LVCMOS18 } [get_ports { NAVSW[3] }];
set_property -dict { PACKAGE_PIN   D7  IOSTANDARD   LVCMOS18 } [get_ports { NAVSW[4] }];

set_property -dict { PACKAGE_PIN   D3  IOSTANDARD   LVCMOS18 } [get_ports { SELSW[0] }];
set_property -dict { PACKAGE_PIN   F4  IOSTANDARD   LVCMOS18 } [get_ports { SELSW[1] }];
set_property -dict { PACKAGE_PIN   F3  IOSTANDARD   LVCMOS18 } [get_ports { SELSW[2] }];

set_property -dict { PACKAGE_PIN  M16  IOSTANDARD   LVCMOS18 } [get_ports { FPGAIO_TURBO }];
set_property -dict { PACKAGE_PIN  G13  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[0] }];
set_property -dict { PACKAGE_PIN  D14  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[1] }];
set_property -dict { PACKAGE_PIN  C14  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[2] }];
set_property -dict { PACKAGE_PIN   C9  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[3] }];
set_property -dict { PACKAGE_PIN   B9  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[4] }];
set_property -dict { PACKAGE_PIN   B8  IOSTANDARD   LVCMOS18 } [get_ports { ANALOG_DIGITAL[5] }];

#set_property IOSTANDARD ANALOG [get_ports { vauxp0 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxn0 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxp1 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxn1 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxp8 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxn8 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxp12 }]; 
#set_property IOSTANDARD ANALOG [get_ports { vauxn12 }]; 

set_property -dict { PACKAGE_PIN   B1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[0] }];
set_property -dict { PACKAGE_PIN   E2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[1] }];
set_property -dict { PACKAGE_PIN   H1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[2] }];
set_property -dict { PACKAGE_PIN   A1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[3] }];
set_property -dict { PACKAGE_PIN   E1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[4] }];
set_property -dict { PACKAGE_PIN   B2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[5] }];
set_property -dict { PACKAGE_PIN   C1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[6] }];
set_property -dict { PACKAGE_PIN   D2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_DQ[7] }];

set_property -dict { PACKAGE_PIN   F1  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_RWDS }];
set_property -dict { PACKAGE_PIN   H2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_CKP }];
set_property -dict { PACKAGE_PIN   G2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_CKN }];
set_property -dict { PACKAGE_PIN   C2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_nRST }];
set_property -dict { PACKAGE_PIN   J2  IOSTANDARD   LVCMOS18 } [get_ports { HYPERRAM_CS }];


set_property PULLTYPE PULLUP [get_ports SELSW]
set_property PULLTYPE PULLUP [get_ports NAVSW]
set_property PULLTYPE PULLUP [get_ports USRSW]

#
# clocks:
create_clock -period 40.000 -name MAINCLK -waveform {0.000 20.000} [get_nets MAINCLK]
#create_clock -period 10.000 -name PLL_CLK1 -waveform {0.000 5.000} [get_nets PLL_CLK1]
create_generated_clock -name progclk  [get_pins {U_progclk/U_mmcm/CLKOUT0}]


set_input_delay -clock MAINCLK -add_delay 0.000 [get_ports USRSW]
set_input_delay -clock MAINCLK -add_delay 0.000 [get_ports NAVSW]
set_input_delay -clock MAINCLK -add_delay 0.000 [get_ports SELSW]

set_output_delay -clock MAINCLK 0.000 [get_ports USRLED]
set_output_delay -clock MAINCLK 0.000 [get_ports CHERIERR]
set_output_delay -clock MAINCLK 0.000 [get_ports LED_LEGACY]
set_output_delay -clock MAINCLK 0.000 [get_ports LED_CHERI]
set_output_delay -clock MAINCLK 0.000 [get_ports LED_HALTED]
set_output_delay -clock MAINCLK 0.000 [get_ports LED_BOOTOK]

set_false_path -to [get_ports USRLED]
set_false_path -to [get_ports CHERIERR]
set_false_path -to [get_ports LED_LEGACY]
set_false_path -to [get_ports LED_CHERI]
set_false_path -to [get_ports LED_HALTED]
set_false_path -to [get_ports LED_BOOTOK]


set imax  0.500
set imin -0.500
set omax  0.500
set omin -0.500

# input is system synchronous
set PROGCLK_HALF_PERIOD 10.0000
set_input_delay -clock progclk -max [expr $PROGCLK_HALF_PERIOD + $imax]  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS }]
set_input_delay -clock progclk -min [expr $PROGCLK_HALF_PERIOD - $imin]  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS }]
set_input_delay -clock progclk -max [expr $PROGCLK_HALF_PERIOD + $imax]  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS }] -clock_fall -add_delay
set_input_delay -clock progclk -min [expr $PROGCLK_HALF_PERIOD - $imin]  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS }] -clock_fall -add_delay

# output is source synchronous
set_output_delay -clock progclk -max $omax  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS HYPERRAM_CS }]
set_output_delay -clock progclk -min $omin  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS HYPERRAM_CS }]
set_output_delay -clock progclk -max $omax  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS HYPERRAM_CS }] -clock_fall -add_delay
set_output_delay -clock progclk -min $omin  [get_ports { HYPERRAM_DQ HYPERRAM_RWDS HYPERRAM_CS }] -clock_fall -add_delay


set_clock_groups -asynchronous \
                 -group [get_clocks progclk ] \
                 -group [get_clocks MAINCLK ]


set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets mainclk_buf]
