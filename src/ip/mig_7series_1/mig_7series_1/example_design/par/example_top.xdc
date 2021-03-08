##################################################################################################
## 
##  Xilinx, Inc. 2010            www.xilinx.com 
##  Mon Mar  8 15:01:36 2021

##  Generated by MIG Version 4.2
##  
##################################################################################################
##  File name :       example_top.xdc
##  Details :     Constraints file
##                    FPGA Family:       ARTIX7
##                    FPGA Part:         XC7A200T-FBG676
##                    Speedgrade:        -2
##                    Design Entry:      VHDL
##                    Frequency:         333.32999999999998 MHz
##                    Time Period:       3000 ps
##################################################################################################

##################################################################################################
## Controller 0
## Memory Device: DDR3_SDRAM->SODIMMs->MT8JTF12864HZ-1G6
## Data Width: 64
## Time Period: 3000
## Data Mask: 1
##################################################################################################
############## NET - IOSTANDARD ##################


# PadFunction: IO_L9N_T1_DQS_16 
set_property IOSTANDARD LVCMOS25 [get_ports {init_calib_complete}]
set_property PACKAGE_PIN A18 [get_ports {init_calib_complete}]

# PadFunction: IO_L10N_T1_16 
set_property IOSTANDARD LVCMOS25 [get_ports {tg_compare_error}]
set_property PACKAGE_PIN A19 [get_ports {tg_compare_error}]

