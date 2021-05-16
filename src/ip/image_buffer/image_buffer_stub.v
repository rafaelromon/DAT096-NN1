// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Sun May 16 16:38:03 2021
// Host        : roach running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               D:/Cloud/Github/Chalmers/DAT096-NN1/src/ip/image_buffer/image_buffer_stub.v
// Design      : image_buffer
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7a200tfbg676-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_4,Vivado 2019.2" *)
module image_buffer(clka, ena, wea, addra, dina, douta, clkb, enb, web, addrb, 
  dinb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,wea[0:0],addra[2:0],dina[71:0],douta[71:0],clkb,enb,web[0:0],addrb[2:0],dinb[71:0],doutb[71:0]" */;
  input clka;
  input ena;
  input [0:0]wea;
  input [2:0]addra;
  input [71:0]dina;
  output [71:0]douta;
  input clkb;
  input enb;
  input [0:0]web;
  input [2:0]addrb;
  input [71:0]dinb;
  output [71:0]doutb;
endmodule
