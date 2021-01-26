`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/23 01:00:39
// Design Name: 
// Module Name: pooling_compare
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


module pooling_compare(clk,rst,poolwrite,ifmap_pool_in,ofmap_pool_out);

parameter wd=8,in=4,fi=3;

input clk,rst,poolwrite;
input [8*wd-1:0] ifmap_pool_in;
output [2*8*wd-1:0] ofmap_pool_out;

wire greater0,greater1,greater2,greater3,greater4,greater5,greater6,greater7;
wire signed [wd-1:0] ifmap0,ifmap1,ifmap2,ifmap3,ifmap4,ifmap5,ifmap6,ifmap7;
wire signed [wd-1:0] mxpl0,mxpl1,mxpl2,mxpl3,mxpl4,mxpl5,mxpl6,mxpl7;
reg signed [wd-1:0] cmpr0,cmpr1,cmpr2,cmpr3,cmpr4,cmpr5,cmpr6,cmpr7;
wire signed [2*wd-1:0] ofmap0,ofmap1,ofmap2,ofmap3,ofmap4,ofmap5,ofmap6,ofmap7;

assign ifmap0=ifmap_pool_in[  wd-1:   0];
assign ifmap1=ifmap_pool_in[2*wd-1:  wd];
assign ifmap2=ifmap_pool_in[3*wd-1:2*wd];
assign ifmap3=ifmap_pool_in[4*wd-1:3*wd];
assign ifmap4=ifmap_pool_in[5*wd-1:4*wd];
assign ifmap5=ifmap_pool_in[6*wd-1:5*wd];
assign ifmap6=ifmap_pool_in[7*wd-1:6*wd];
assign ifmap7=ifmap_pool_in[8*wd-1:7*wd];

assign greater0=ifmap0>cmpr0;
assign greater1=ifmap1>cmpr1;
assign greater2=ifmap2>cmpr2;
assign greater3=ifmap3>cmpr3;
assign greater4=ifmap4>cmpr4;
assign greater5=ifmap5>cmpr5;
assign greater6=ifmap6>cmpr6;
assign greater7=ifmap7>cmpr7;

assign mxpl0 = greater0 ? ifmap0 : cmpr0 ;
assign mxpl1 = greater1 ? ifmap1 : cmpr1 ;
assign mxpl2 = greater2 ? ifmap2 : cmpr2 ;
assign mxpl3 = greater3 ? ifmap3 : cmpr3 ;
assign mxpl4 = greater4 ? ifmap4 : cmpr4 ;
assign mxpl5 = greater5 ? ifmap5 : cmpr5 ;
assign mxpl6 = greater6 ? ifmap6 : cmpr6 ;
assign mxpl7 = greater7 ? ifmap7 : cmpr7 ;

assign ofmap0={{in+1{mxpl0[7]}},mxpl0,{fi{1'b0}}};
assign ofmap1={{in+1{mxpl1[7]}},mxpl1,{fi{1'b0}}};
assign ofmap2={{in+1{mxpl2[7]}},mxpl2,{fi{1'b0}}};
assign ofmap3={{in+1{mxpl3[7]}},mxpl3,{fi{1'b0}}};
assign ofmap4={{in+1{mxpl4[7]}},mxpl4,{fi{1'b0}}};
assign ofmap5={{in+1{mxpl5[7]}},mxpl5,{fi{1'b0}}};
assign ofmap6={{in+1{mxpl6[7]}},mxpl6,{fi{1'b0}}};
assign ofmap7={{in+1{mxpl7[7]}},mxpl7,{fi{1'b0}}};

assign ofmap_pool_out={ofmap7,ofmap6,ofmap5,ofmap4,ofmap3,ofmap2,ofmap1,ofmap0};

always @(posedge clk or posedge rst) 
begin
    if (rst) begin
        cmpr0<={1'b1,{wd-1{1'b0}}};
        cmpr1<={1'b1,{wd-1{1'b0}}};
        cmpr2<={1'b1,{wd-1{1'b0}}};
        cmpr3<={1'b1,{wd-1{1'b0}}};
        cmpr4<={1'b1,{wd-1{1'b0}}};
        cmpr5<={1'b1,{wd-1{1'b0}}};
        cmpr6<={1'b1,{wd-1{1'b0}}};
        cmpr7<={1'b1,{wd-1{1'b0}}};
    end else begin
        if (poolwrite) begin
            cmpr0<={1'b1,{wd-1{1'b0}}};
            cmpr1<={1'b1,{wd-1{1'b0}}};
            cmpr2<={1'b1,{wd-1{1'b0}}};
            cmpr3<={1'b1,{wd-1{1'b0}}};
            cmpr4<={1'b1,{wd-1{1'b0}}};
            cmpr5<={1'b1,{wd-1{1'b0}}};
            cmpr6<={1'b1,{wd-1{1'b0}}};
            cmpr7<={1'b1,{wd-1{1'b0}}};
        end else begin
            cmpr0<=mxpl0;
            cmpr1<=mxpl1;
            cmpr2<=mxpl2;
            cmpr3<=mxpl3;
            cmpr4<=mxpl4;
            cmpr5<=mxpl5;
            cmpr6<=mxpl6;
            cmpr7<=mxpl7;
        end
    end
end

endmodule
