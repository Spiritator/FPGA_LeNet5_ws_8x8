`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/19 12:47:49
// Design Name: 
// Module Name: tilting_registers
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


module tilting_registers(clk,rst,D0_in,D1_in,D2_in,D3_in,D4_in,D5_in,D6_in,D7_in,D0_out,D1_out,D2_out,D3_out,D4_out,D5_out,D6_out,D7_out);

parameter wl=8;

input clk,rst;
input [wl-1:0] D0_in,D1_in,D2_in,D3_in,D4_in,D5_in,D6_in,D7_in;
output [wl-1:0] D0_out,D1_out,D2_out,D3_out,D4_out,D5_out,D6_out,D7_out;

reg [wl-1:0] D1R0;
reg [wl-1:0] D2R0,D2R1;
reg [wl-1:0] D3R0,D3R1,D3R2;
reg [wl-1:0] D4R0,D4R1,D4R2,D4R3;
reg [wl-1:0] D5R0,D5R1,D5R2,D5R3,D5R4;
reg [wl-1:0] D6R0,D6R1,D6R2,D6R3,D6R4,D6R5;
reg [wl-1:0] D7R0,D7R1,D7R2,D7R3,D7R4,D7R5,D7R6;

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        D1R0<={wl{1'b0}};
        D2R0<={wl{1'b0}};
        D2R1<={wl{1'b0}};
        D3R0<={wl{1'b0}};
        D3R1<={wl{1'b0}};
        D3R2<={wl{1'b0}};
        D4R0<={wl{1'b0}};
        D4R1<={wl{1'b0}};
        D4R2<={wl{1'b0}};
        D4R3<={wl{1'b0}};
        D5R0<={wl{1'b0}};
        D5R1<={wl{1'b0}};
        D5R2<={wl{1'b0}};
        D5R3<={wl{1'b0}};
        D5R4<={wl{1'b0}};
        D6R0<={wl{1'b0}};
        D6R1<={wl{1'b0}};
        D6R2<={wl{1'b0}};
        D6R3<={wl{1'b0}};
        D6R4<={wl{1'b0}};
        D6R5<={wl{1'b0}};
        D7R0<={wl{1'b0}};
        D7R1<={wl{1'b0}};
        D7R2<={wl{1'b0}};
        D7R3<={wl{1'b0}};
        D7R4<={wl{1'b0}};
        D7R5<={wl{1'b0}};
        D7R6<={wl{1'b0}};
    end 
    else 
    begin
        D1R0<=D1_in;
        D2R0<=D2_in;
        D2R1<=D2R0;
        D3R0<=D3_in;
        D3R1<=D3R0;
        D3R2<=D3R1;
        D4R0<=D4_in;
        D4R1<=D4R0;
        D4R2<=D4R1;
        D4R3<=D4R2;
        D5R0<=D5_in;
        D5R1<=D5R0;
        D5R2<=D5R1;
        D5R3<=D5R2;
        D5R4<=D5R3;
        D6R0<=D6_in;
        D6R1<=D6R0;
        D6R2<=D6R1;
        D6R3<=D6R2;
        D6R4<=D6R3;
        D6R5<=D6R4;
        D7R0<=D7_in;
        D7R1<=D7R0;
        D7R2<=D7R1;
        D7R3<=D7R2;
        D7R4<=D7R3;
        D7R5<=D7R4;
        D7R6<=D7R5;
    end
end

assign D0_out=D0_in;
assign D1_out=D1R0;
assign D2_out=D2R1;
assign D3_out=D3R2;
assign D4_out=D4R3;
assign D5_out=D5R4;
assign D6_out=D6R5;
assign D7_out=D7R6;

endmodule
