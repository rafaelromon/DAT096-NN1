// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Thu May  6 14:23:17 2021
// Host        : ED4220-09 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub z:/git/github/DAT096-NN1/src/ip/ila_0/ila_0_stub.v
// Design      : ila_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "ila,Vivado 2019.2" *)
module ila_0(clk, probe0, probe1, probe2, probe3, probe4, probe5, 
  probe6, probe7, probe8, probe9, probe10, probe11, probe12, probe13, probe14)
/* synthesis syn_black_box black_box_pad_pin="clk,probe0[3:0],probe1[0:0],probe2[0:0],probe3[2:0],probe4[27:0],probe5[0:0],probe6[0:0],probe7[0:0],probe8[511:0],probe9[0:0],probe10[0:0],probe11[0:0],probe12[511:0],probe13[0:0],probe14[0:0]" */;
  input clk;
  input [3:0]probe0;
  input [0:0]probe1;
  input [0:0]probe2;
  input [2:0]probe3;
  input [27:0]probe4;
  input [0:0]probe5;
  input [0:0]probe6;
  input [0:0]probe7;
  input [511:0]probe8;
  input [0:0]probe9;
  input [0:0]probe10;
  input [0:0]probe11;
  input [511:0]probe12;
  input [0:0]probe13;
  input [0:0]probe14;
endmodule
