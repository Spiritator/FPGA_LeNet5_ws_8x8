`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/08 13:46:43
// Design Name: 
// Module Name: data_dispatcher
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

`define C_M_AXI_ADDR_WIDTH 32
`define C_M_AXI_DATA_WIDTH 64
`define C_MAX_BURST_LEN 256
`define C_ADDR_PIPE_DEPTH 1 
`define C_LENGTH_WIDTH 14
`define C_NATIVE_DATA_WIDTH 64


module data_dispatcher(clk,FSM_data,write_halt,ctrl2pe,pe2ctrl,ifmap_din,wght_din,ofmap_dout);

parameter idle=4'd0, load_wght_req=4'd1, load_wght_burst=4'd2, load_wght_cmplt=4'd3, load_ifmap_req=4'd4, load_ifmap_burst=4'd5, load_ifmap_cmplt=4'd6, ifmap_filling_zero=4'd7, offload_ofmap_req=4'd8, offload_ofmap_burst=4'd9, offload_ofmap_cmplt=4'd10;

input clk;
input [3:0] FSM_data;
input write_halt;

input [`C_NATIVE_DATA_WIDTH-1:0] ctrl2pe;
output [`C_NATIVE_DATA_WIDTH-1:0] pe2ctrl;
output reg [`C_NATIVE_DATA_WIDTH-1:0] ifmap_din,wght_din;
input [`C_NATIVE_DATA_WIDTH-1:0] ofmap_dout;

reg [`C_NATIVE_DATA_WIDTH-1:0] ifmapD0,ifmapD1,ofmapHold;

always @(posedge clk) 
begin
    if (write_halt)
        ofmapHold<=ofmapHold;
    else
        ofmapHold<=ofmap_dout;
    
    ifmapD0<=ctrl2pe;
    ifmapD1<=ifmapD0;
end

assign pe2ctrl= write_halt ? ofmapHold : ofmap_dout;

always @(FSM_data or ctrl2pe or ifmapD1) 
begin
    case (FSM_data)
        load_wght_req,load_wght_burst,load_wght_cmplt: 
        begin
            wght_din=ctrl2pe;
            ifmap_din=`C_NATIVE_DATA_WIDTH'd0;
        end
        load_ifmap_req,load_ifmap_burst,load_ifmap_cmplt:
        begin
            wght_din=`C_NATIVE_DATA_WIDTH'd0;
            ifmap_din=ifmapD1;
        end
        ifmap_filling_zero:
        begin
            wght_din=`C_NATIVE_DATA_WIDTH'd0;
            ifmap_din=`C_NATIVE_DATA_WIDTH'd0;
        end
        default: 
        begin
            wght_din=`C_NATIVE_DATA_WIDTH'd0;
            ifmap_din=`C_NATIVE_DATA_WIDTH'd0;
        end
    endcase
end

endmodule
