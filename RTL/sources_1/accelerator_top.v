`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/18 14:43:23
// Design Name: 
// Module Name: accelerator_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module accelerator_top(clk,rst,ifmap_en,wght_en,ofmap_en,config_load,config_done,op_go,ifmap_ready,wght_ready,op_done,
                       bias_write,ifmap_wen,wght_wen,ifmap_addrin,wght_addrin,ofmap_addrin,ifmap_din,wght_din,
                       psum_split_condense,maxpooling,relu,tile_order_first,tile_order_last,
                       ifmapR,ifmapC,ofmapR,ofmapC,kernelR,kernelC,inchannel,outchannel,
                       dataload_ready,tile_done,FSM,ofmap_dout);
    
parameter wd=8,in=4,fi=3;

input clk,rst,ifmap_en,wght_en,ofmap_en,config_load,config_done,op_go,ifmap_ready,wght_ready,op_done,bias_write;
input [7:0] ifmap_wen,wght_wen;
input [9:0] ifmap_addrin;
input [9:0] wght_addrin;
input [9:0] ofmap_addrin;
input [8*wd-1:0] ifmap_din,wght_din;

// tile config
input psum_split_condense,maxpooling,relu,tile_order_first,tile_order_last;
input [5:0] ifmapR,ifmapC,ofmapR,ofmapC;
input [2:0] kernelR,kernelC;
input [9:0] inchannel;
input [4:0] outchannel;

output dataload_ready,tile_done;
output [3:0] FSM;
output [8*wd-1:0] ofmap_dout;

// main ctrl IO
wire load_wght,sum_in_bias,load_bias;

// BRAM ctrl & IO
wire ifmap_en_b,wght_en_b,ofmap_en_a,ofmap_en_b,bias_en_a,bias_en_b;
wire bias_addrin,bias_addr_b;
wire [9:0] ifmap_addr_b;
wire [9:0] wght_addr_b;
wire [9:0] ofmap_addr_a,ofmap_addr_b;
wire [7:0] ifmap_wen_b,wght_wen_b,bias_wen_a,bias_wen_b;
wire [15:0] ofmap_wen_a,ofmap_wen_b;
wire [8*wd-1:0] ifmap_dout_a,ifmap_din_b,ifmap_dout_b,wght_din_a,wght_din_b,wght_dout_a,wght_dout_b,bias_din_a,bias_din_b,bias_dout_a,bias_dout_b;
wire [2*8*wd-1:0] ofmap_din_a,ofmap_din_b,ofmap_dout_a,ofmap_dout_b;

// PE array IO
wire signed [wd-1:0] ifmap0,ifmap1,ifmap2,ifmap3,ifmap4,ifmap5,ifmap6,ifmap7;
wire signed [wd-1:0] wght0,wght1,wght2,wght3,wght4,wght5,wght6,wght7;
wire signed [2*wd-1:0] sum_in0,sum_in1,sum_in2,sum_in3,sum_in4,sum_in5,sum_in6,sum_in7;
wire signed [2*wd-1:0] accum0,accum1,accum2,accum3,accum4,accum5,accum6,accum7;

// Pooling IO
wire [2*8*wd-1:0] ofmap_pool_out;


// MAC PE Array
systolic_pe_array MXU(  .clk(clk),.rst(rst),.load_wght(load_wght),
                        .ifmap0(ifmap0),.ifmap1(ifmap1),.ifmap2(ifmap2),.ifmap3(ifmap3),.ifmap4(ifmap4),.ifmap5(ifmap5),.ifmap6(ifmap6),.ifmap7(ifmap7),
                        .wght0(wght0),.wght1(wght1),.wght2(wght2),.wght3(wght3),.wght4(wght4),.wght5(wght5),.wght6(wght6),.wght7(wght7),
                        .sum_in0(sum_in0),.sum_in1(sum_in1),.sum_in2(sum_in2),.sum_in3(sum_in3),.sum_in4(sum_in4),.sum_in5(sum_in5),.sum_in6(sum_in6),.sum_in7(sum_in7),
                        .accum0(accum0),.accum1(accum1),.accum2(accum2),.accum3(accum3),.accum4(accum4),.accum5(accum5),.accum6(accum6),.accum7(accum7));

// BRAM buffers
ifmap_buffer_8KB ifmap_buf( .clka(clk),.ena(ifmap_en),.wea(ifmap_wen),.addra(ifmap_addrin),.dina(ifmap_din),.douta(ifmap_dout_a),
                            .clkb(clk),.enb(ifmap_en_b),.web(ifmap_wen_b),.addrb(ifmap_addr_b),.dinb(ifmap_din_b),.doutb(ifmap_dout_b));
                            
ofmap_buffer_16KB ofmap_buf(.clka(clk),.ena(ofmap_en_a),.wea(ofmap_wen_a),.addra(ofmap_addr_a),.dina(ofmap_din_a),.douta(ofmap_dout_a),
                            .clkb(clk),.enb(ofmap_en_b),.web(ofmap_wen_b),.addrb(ofmap_addr_b),.dinb(ofmap_din_b),.doutb(ofmap_dout_b));

kernel_buffer_8KB kernel_buf(.clka(clk),.ena(wght_en),.wea(wght_wen),.addra(wght_addrin),.dina(wght_din_a),.douta(wght_dout_a),
                             .clkb(clk),.enb(wght_en_b),.web(wght_wen_b),.addrb(wght_addr_b),.dinb(wght_din_b),.doutb(wght_dout_b));

bias_buffer_128bit bias_buf(.clka(clk),.ena(bias_en_a),.wea(bias_wen_a),.addra(bias_addrin),.dina(bias_din_a),.douta(bias_dout_a),
                            .clkb(clk),.enb(bias_en_b),.web(bias_wen_b),.addrb(bias_addr_b),.dinb(bias_din_b),.doutb(bias_dout_b));

// control unit
main_ctrl control_unit(.clk(clk), .rst(rst), .config_load(config_load), .config_done(config_done), .ifmap_ready(ifmap_ready), .wght_ready(wght_ready), .op_go(op_go), .op_done(op_done), .bias_write(bias_write),
                       .psum_split_condense(psum_split_condense), .maxpooling(maxpooling), .tile_order_first(tile_order_first), .tile_order_last(tile_order_last),
                       .ifmapR(ifmapR), .ifmapC(ifmapC), .ofmapR(ofmapR), .ofmapC(ofmapC), .kernelR(kernelR), .kernelC(kernelC), .inchannel(inchannel), .outchannel(outchannel),
                       .load_wght(load_wght), .data_ready(dataload_ready), .sum_in_bias(sum_in_bias), .tile_done(tile_done), .current_state(FSM),
                       .ofmap_en(ofmap_en), .ofmap_addrin(ofmap_addrin),
                       .ifmap_en_b(ifmap_en_b), .wght_en_b(wght_en_b), .ofmap_en_a(ofmap_en_a), .ofmap_en_b(ofmap_en_b), .bias_en_a(bias_en_a), .bias_en_b(bias_en_b),
                       .bias_addr_b(bias_addr_b), .ifmap_addr_b(ifmap_addr_b), .wght_addr_b(wght_addr_b), .ofmap_addr_a(ofmap_addr_a), .ofmap_addr_b(ofmap_addr_b),
                       .ifmap_wen_b(ifmap_wen_b), .wght_wen_b(wght_wen_b), .ofmap_wen_a(ofmap_wen_a), .ofmap_wen_b(ofmap_wen_b), .bias_wen_a(bias_wen_a), .bias_wen_b(bias_wen_b));

// PE array wiring
assign ifmap0=ifmap_dout_b[  wd-1:   0];
assign ifmap1=ifmap_dout_b[2*wd-1:  wd];
assign ifmap2=ifmap_dout_b[3*wd-1:2*wd];
assign ifmap3=ifmap_dout_b[4*wd-1:3*wd];
assign ifmap4=ifmap_dout_b[5*wd-1:4*wd];
assign ifmap5=ifmap_dout_b[6*wd-1:5*wd];
assign ifmap6=ifmap_dout_b[7*wd-1:6*wd];
assign ifmap7=ifmap_dout_b[8*wd-1:7*wd];
assign wght0=wght_dout_b[  wd-1:   0];
assign wght1=wght_dout_b[2*wd-1:  wd];
assign wght2=wght_dout_b[3*wd-1:2*wd];
assign wght3=wght_dout_b[4*wd-1:3*wd];
assign wght4=wght_dout_b[5*wd-1:4*wd];
assign wght5=wght_dout_b[6*wd-1:5*wd];
assign wght6=wght_dout_b[7*wd-1:6*wd];
assign wght7=wght_dout_b[8*wd-1:7*wd];
assign sum_in0= sum_in_bias ? {{in+1{bias_dout_b[  wd-1]}},bias_dout_b[  wd-1:   0],{fi{1'b0}}} : ofmap_dout_a[ 2*wd-1:    0];
assign sum_in1= sum_in_bias ? {{in+1{bias_dout_b[2*wd-1]}},bias_dout_b[2*wd-1:  wd],{fi{1'b0}}} : ofmap_dout_a[ 4*wd-1: 2*wd];
assign sum_in2= sum_in_bias ? {{in+1{bias_dout_b[3*wd-1]}},bias_dout_b[3*wd-1:2*wd],{fi{1'b0}}} : ofmap_dout_a[ 6*wd-1: 4*wd];
assign sum_in3= sum_in_bias ? {{in+1{bias_dout_b[4*wd-1]}},bias_dout_b[4*wd-1:3*wd],{fi{1'b0}}} : ofmap_dout_a[ 8*wd-1: 6*wd];
assign sum_in4= sum_in_bias ? {{in+1{bias_dout_b[5*wd-1]}},bias_dout_b[5*wd-1:4*wd],{fi{1'b0}}} : ofmap_dout_a[10*wd-1: 8*wd];
assign sum_in5= sum_in_bias ? {{in+1{bias_dout_b[6*wd-1]}},bias_dout_b[6*wd-1:5*wd],{fi{1'b0}}} : ofmap_dout_a[12*wd-1:10*wd];
assign sum_in6= sum_in_bias ? {{in+1{bias_dout_b[7*wd-1]}},bias_dout_b[7*wd-1:6*wd],{fi{1'b0}}} : ofmap_dout_a[14*wd-1:12*wd];
assign sum_in7= sum_in_bias ? {{in+1{bias_dout_b[8*wd-1]}},bias_dout_b[8*wd-1:7*wd],{fi{1'b0}}} : ofmap_dout_a[16*wd-1:14*wd];
assign ofmap_din_b[ 2*wd-1:    0]= maxpooling ? ofmap_pool_out[ 2*wd-1:    0] : accum0;
assign ofmap_din_b[ 4*wd-1: 2*wd]= maxpooling ? ofmap_pool_out[ 4*wd-1: 2*wd] : accum1;
assign ofmap_din_b[ 6*wd-1: 4*wd]= maxpooling ? ofmap_pool_out[ 6*wd-1: 4*wd] : accum2;
assign ofmap_din_b[ 8*wd-1: 6*wd]= maxpooling ? ofmap_pool_out[ 8*wd-1: 6*wd] : accum3;
assign ofmap_din_b[10*wd-1: 8*wd]= maxpooling ? ofmap_pool_out[10*wd-1: 8*wd] : accum4;
assign ofmap_din_b[12*wd-1:10*wd]= maxpooling ? ofmap_pool_out[12*wd-1:10*wd] : accum5;
assign ofmap_din_b[14*wd-1:12*wd]= maxpooling ? ofmap_pool_out[14*wd-1:12*wd] : accum6;
assign ofmap_din_b[16*wd-1:14*wd]= maxpooling ? ofmap_pool_out[16*wd-1:14*wd] : accum7;

// BRAM wiring
assign bias_addrin=wght_addrin[0];
assign load_bias = FSM == 4'd2;
assign wght_din_a = load_bias ? {8*wd{1'b0}} : wght_din;
assign bias_din_a = load_bias ? wght_din : {8*wd{1'b0}};

assign ifmap_din_b=64'd0;
assign wght_din_b=64'd0;
assign bias_din_b=64'd0;
assign ofmap_din_a=128'd0;

// output truncate and ReLU unit
activation_outtrunc relu_trunc0(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[ 2*wd-1:    0]),.ofmap(ofmap_dout[  wd-1:   0]));
activation_outtrunc relu_trunc1(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[ 4*wd-1: 2*wd]),.ofmap(ofmap_dout[2*wd-1:  wd]));
activation_outtrunc relu_trunc2(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[ 6*wd-1: 4*wd]),.ofmap(ofmap_dout[3*wd-1:2*wd]));
activation_outtrunc relu_trunc3(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[ 8*wd-1: 6*wd]),.ofmap(ofmap_dout[4*wd-1:3*wd]));
activation_outtrunc relu_trunc4(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[10*wd-1: 8*wd]),.ofmap(ofmap_dout[5*wd-1:4*wd]));
activation_outtrunc relu_trunc5(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[12*wd-1:10*wd]),.ofmap(ofmap_dout[6*wd-1:5*wd]));
activation_outtrunc relu_trunc6(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[14*wd-1:12*wd]),.ofmap(ofmap_dout[7*wd-1:6*wd]));
activation_outtrunc relu_trunc7(.ofmap_en(ofmap_en),.relu(relu),.psum_pxl(ofmap_dout_a[16*wd-1:14*wd]),.ofmap(ofmap_dout[8*wd-1:7*wd]));

pooling_compare pool_unit(.clk(clk),.rst(rst),.poolwrite(ofmap_wen_b[0]),.ifmap_pool_in(ifmap_dout_b),.ofmap_pool_out(ofmap_pool_out));

endmodule
