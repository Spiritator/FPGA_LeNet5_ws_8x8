`timescale 1ns / 1ps


module mac_unit(clk,rst,load_wght,ifmap_in,wght_in,psum_in,ifmap_out,wght_out,psum_out);

parameter wd=8,in=4,fi=3;

input clk,rst,load_wght;
input signed [wd-1:0] ifmap_in,wght_in;
input signed [2*wd-1:0] psum_in;
output signed [wd-1:0] ifmap_out,wght_out;
output signed [2*wd-1:0] psum_out;
reg signed [2*wd-1:0] psum_out;

reg signed [wd-1:0] ifmap_r,wght_r;

wire signed [2*wd-1:0] mulout,psum;
wire signed [2*wd:0] addout;

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        ifmap_r<={wd{1'd0}};  
        wght_r<={wd{1'd0}};  
        psum_out<={(2*wd-1){1'd0}};  
    end 
    else 
    begin
        ifmap_r<=ifmap_in;
        psum_out<=psum;
        if (load_wght) 
        begin
            wght_r<=wght_in;
        end 
        else 
        begin
            wght_r<=wght_r;
        end
    end
end

assign mulout=ifmap_r*wght_r;
assign addout={psum_in[2*wd-1],psum_in}+{mulout[2*wd-1],mulout};
assign psum=addout[2*wd-1:0];

assign ifmap_out=ifmap_r;
assign wght_out=wght_r;

endmodule
