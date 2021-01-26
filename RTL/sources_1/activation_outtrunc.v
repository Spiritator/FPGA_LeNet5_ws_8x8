`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/27 18:38:47
// Design Name: 
// Module Name: activation_outtrunc
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


module activation_outtrunc(ofmap_en,psum_pxl,ofmap);

parameter wd=8,in=4,fi=3;

input ofmap_en;
input signed [2*wd-1:0] psum_pxl;
output signed [wd-1:0] ofmap;
reg signed [wd-1:0] ofmap;

always @(ofmap_en or psum_pxl) 
begin
    if (ofmap_en) 
    begin
        if (psum_pxl[2*wd-1]) 
        begin
            ofmap={wd{1'b0}};
        end 
        else 
        begin
            ofmap=psum_pxl[in+2*fi:fi];
        end
    end 
    else 
    begin
        ofmap={wd{1'b0}};
    end
end

endmodule
