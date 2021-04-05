// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Fri Mar  5 14:53:15 2021
// Host        : ED4225-09 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub z:/DAT096-NN1/src/ip/image_buffer/image_buffer_stub.v
// Design      : image_buffer
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module image_buffer(clka, ena, wea, addra, dina, clkb, enb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[10:0],dina[127:0],clkb,enb,addrb[10:0],doutb[127:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [10:0]addra;
  input [127:0]dina;
  input clkb;
  input enb;
  input [10:0]addrb;
  output [127:0]doutb;
endmodule
