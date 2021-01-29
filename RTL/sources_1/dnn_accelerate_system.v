`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/29 18:28:58
// Design Name: 
// Module Name: dnn_accelerate_system
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

`define C_S_AXI_DATA_WIDTH 64
`define C_S_AXI_ADDR_WIDTH 5

module dnn_accelerate_system(   m00_axi_aclk,m00_axi_aresetn,
                                m00_axi_arready,m00_axi_arvalid,m00_axi_araddr,m00_axi_arlen,m00_axi_arsize,m00_axi_arburst,m00_axi_arprot,m00_axi_arcache,
                                m00_axi_rready,m00_axi_rvalid,m00_axi_rdata,m00_axi_rresp,m00_axi_rlast,
                                m00_axi_awready,m00_axi_awvalid,m00_axi_awaddr,m00_axi_awlen,m00_axi_awsize,m00_axi_awburst,m00_axi_awprot,m00_axi_awcache,
                                m00_axi_wready,m00_axi_wvalid,m00_axi_wdata,m00_axi_wstrb,m00_axi_wlast,
                                m00_axi_bresp,m00_axi_bvalid,m00_axi_bready,
                                s00_axi_aclk,s00_axi_aresetn,
                                s00_axi_awaddr,s00_axi_awprot,s00_axi_awvalid,s00_axi_awready,
                                s00_axi_wdata,s00_axi_wstrb,s00_axi_wvalid,s00_axi_wready,
                                s00_axi_bresp,s00_axi_bvalid,s00_axi_bready,
                                s00_axi_araddr,s00_axi_arprot,s00_axi_arvalid,s00_axi_arready,
                                s00_axi_rdata,s00_axi_rresp,s00_axi_rvalid,s00_axi_rready
                                );

parameter wd=8;

// AXI4 IO
/*                                                                                                                  
               AAA               XXXXXXX       XXXXXXXIIIIIIIIII     444444444       IIIIIIIIII     OOOOOOOOO     
              A:::A              X:::::X       X:::::XI::::::::I    4::::::::4       I::::::::I   OO:::::::::OO   
             A:::::A             X:::::X       X:::::XI::::::::I   4:::::::::4       I::::::::I OO:::::::::::::OO 
            A:::::::A            X::::::X     X::::::XII::::::II  4::::44::::4       II::::::IIO:::::::OOO:::::::O
           A:::::::::A           XXX:::::X   X:::::XXX  I::::I   4::::4 4::::4         I::::I  O::::::O   O::::::O
          A:::::A:::::A             X:::::X X:::::X     I::::I  4::::4  4::::4         I::::I  O:::::O     O:::::O
         A:::::A A:::::A             X:::::X:::::X      I::::I 4::::4   4::::4         I::::I  O:::::O     O:::::O
        A:::::A   A:::::A             X:::::::::X       I::::I4::::444444::::444       I::::I  O:::::O     O:::::O
       A:::::A     A:::::A            X:::::::::X       I::::I4::::::::::::::::4       I::::I  O:::::O     O:::::O
      A:::::AAAAAAAAA:::::A          X:::::X:::::X      I::::I4444444444:::::444       I::::I  O:::::O     O:::::O
     A:::::::::::::::::::::A        X:::::X X:::::X     I::::I          4::::4         I::::I  O:::::O     O:::::O
    A:::::AAAAAAAAAAAAA:::::A    XXX:::::X   X:::::XXX  I::::I          4::::4         I::::I  O::::::O   O::::::O
   A:::::A             A:::::A   X::::::X     X::::::XII::::::II        4::::4       II::::::IIO:::::::OOO:::::::O
  A:::::A               A:::::A  X:::::X       X:::::XI::::::::I      44::::::44     I::::::::I OO:::::::::::::OO 
 A:::::A                 A:::::A X:::::X       X:::::XI::::::::I      4::::::::4     I::::::::I   OO:::::::::OO   
AAAAAAA                   AAAAAAAXXXXXXX       XXXXXXXIIIIIIIIII      4444444444     IIIIIIIIII     OOOOOOOOO     
*/

input m00_axi_aclk;
input m00_axi_aresetn;
// AXI4 Master Read Address Channel
input m00_axi_arready;
output m00_axi_arvalid;
output [`C_M_AXI_ADDR_WIDTH-1:0] m00_axi_araddr;
output [7:0] m00_axi_arlen;
output [2:0] m00_axi_arsize;
output [1:0] m00_axi_arburst;
output [2:0] m00_axi_arprot;
output [3:0] m00_axi_arcache;
// AXI4 Master Read Data Channel
output m00_axi_rready;
input m00_axi_rvalid ;
input [`C_M_AXI_DATA_WIDTH-1:0] m00_axi_rdata;
input [1:0] m00_axi_rresp;
input m00_axi_rlast;
//AXI4 Master Write Address Channel
input m00_axi_awready;
output m00_axi_awvalid;
output [`C_M_AXI_ADDR_WIDTH-1:0] m00_axi_awaddr;
output [7:0] m00_axi_awlen;
output [2:0] m00_axi_awsize;
output [1:0] m00_axi_awburst;
output [2:0] m00_axi_awprot;
output [3:0] m00_axi_awcache;
//AXI4 Master Write Data Channel
input m00_axi_wready;
output m00_axi_wvalid;
output [`C_M_AXI_DATA_WIDTH-1:0] m00_axi_wdata;
output [(`C_M_AXI_DATA_WIDTH/8)-1:0] m00_axi_wstrb;
output m00_axi_wlast;
//AXI4 Master Write Response Channel 
input [1:0] m00_axi_bresp;
input m00_axi_bvalid;
output m00_axi_bready;

// AXI light IO
/*                                                                                                                                                                                  
               AAA               XXXXXXX       XXXXXXXIIIIIIIIII     LLLLLLLLLLL                SSSSSSSSSSSSSSS      IIIIIIIIII     OOOOOOOOO     
              A:::A              X:::::X       X:::::XI::::::::I     L:::::::::L              SS:::::::::::::::S     I::::::::I   OO:::::::::OO   
             A:::::A             X:::::X       X:::::XI::::::::I     L:::::::::L             S:::::SSSSSS::::::S     I::::::::I OO:::::::::::::OO 
            A:::::::A            X::::::X     X::::::XII::::::II     LL:::::::LL             S:::::S     SSSSSSS     II::::::IIO:::::::OOO:::::::O
           A:::::::::A           XXX:::::X   X:::::XXX  I::::I         L:::::L               S:::::S                   I::::I  O::::::O   O::::::O
          A:::::A:::::A             X:::::X X:::::X     I::::I         L:::::L               S:::::S                   I::::I  O:::::O     O:::::O
         A:::::A A:::::A             X:::::X:::::X      I::::I         L:::::L                S::::SSSS                I::::I  O:::::O     O:::::O
        A:::::A   A:::::A             X:::::::::X       I::::I         L:::::L                 SS::::::SSSSS           I::::I  O:::::O     O:::::O
       A:::::A     A:::::A            X:::::::::X       I::::I         L:::::L                   SSS::::::::SS         I::::I  O:::::O     O:::::O
      A:::::AAAAAAAAA:::::A          X:::::X:::::X      I::::I         L:::::L                      SSSSSS::::S        I::::I  O:::::O     O:::::O
     A:::::::::::::::::::::A        X:::::X X:::::X     I::::I         L:::::L                           S:::::S       I::::I  O:::::O     O:::::O
    A:::::AAAAAAAAAAAAA:::::A    XXX:::::X   X:::::XXX  I::::I         L:::::L         LLLLLL            S:::::S       I::::I  O::::::O   O::::::O
   A:::::A             A:::::A   X::::::X     X::::::XII::::::II     LL:::::::LLLLLLLLL:::::LSSSSSSS     S:::::S     II::::::IIO:::::::OOO:::::::O
  A:::::A               A:::::A  X:::::X       X:::::XI::::::::I     L::::::::::::::::::::::LS::::::SSSSSS:::::S     I::::::::I OO:::::::::::::OO 
 A:::::A                 A:::::A X:::::X       X:::::XI::::::::I     L::::::::::::::::::::::LS:::::::::::::::SS      I::::::::I   OO:::::::::OO   
AAAAAAA                   AAAAAAAXXXXXXX       XXXXXXXIIIIIIIIII     LLLLLLLLLLLLLLLLLLLLLLLL SSSSSSSSSSSSSSS        IIIIIIIIII     OOOOOOOOO     
*/

input wire s00_axi_aclk;
input wire s00_axi_aresetn;
//AXI Light write address channel
input wire [`C_S_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
input wire [2:0] s00_axi_awprot;
input wire s00_axi_awvalid;
output wire s00_axi_awready;
//AXI Light write data channel
input wire [`C_S_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
input wire [(`C_S_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
input wire s00_axi_wvalid;
output wire s00_axi_wready;
//AXI Light write respond channel
output wire [1:0] s00_axi_bresp;
output wire s00_axi_bvalid;
input wire s00_axi_bready;
//AXI Light read address channel
input wire [`C_S_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
input wire [2:0] s00_axi_arprot;
input wire s00_axi_arvalid;
output wire s00_axi_arready;
//AXI Light read data channel
output wire [`C_S_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
output wire [1:0] s00_axi_rresp;
output wire s00_axi_rvalid;
input wire s00_axi_rready;


// IPIC IO
/*                                                                                           
IIIIIIIIIIPPPPPPPPPPPPPPPPP   IIIIIIIIII      CCCCCCCCCCCCC     IIIIIIIIII     OOOOOOOOO     
I::::::::IP::::::::::::::::P  I::::::::I   CCC::::::::::::C     I::::::::I   OO:::::::::OO   
I::::::::IP::::::PPPPPP:::::P I::::::::I CC:::::::::::::::C     I::::::::I OO:::::::::::::OO 
II::::::IIPP:::::P     P:::::PII::::::IIC:::::CCCCCCCC::::C     II::::::IIO:::::::OOO:::::::O
  I::::I    P::::P     P:::::P  I::::I C:::::C       CCCCCC       I::::I  O::::::O   O::::::O
  I::::I    P::::P     P:::::P  I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P::::PPPPPP:::::P   I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P:::::::::::::PP    I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P::::PPPPPPPPP      I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P::::P              I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P::::P              I::::IC:::::C                     I::::I  O:::::O     O:::::O
  I::::I    P::::P              I::::I C:::::C       CCCCCC       I::::I  O::::::O   O::::::O
II::::::IIPP::::::PP          II::::::IIC:::::CCCCCCCC::::C     II::::::IIO:::::::OOO:::::::O
I::::::::IP::::::::P          I::::::::I CC:::::::::::::::C     I::::::::I OO:::::::::::::OO 
I::::::::IP::::::::P          I::::::::I   CCC::::::::::::C     I::::::::I   OO:::::::::OO   
IIIIIIIIIIPPPPPPPPPP          IIIIIIIIII      CCCCCCCCCCCCC     IIIIIIIIII     OOOOOOOOO     
*/
// IPIC ctrl
wire ip2bus_mstrd_req;
wire ip2bus_mstwr_req;
wire [`C_M_AXI_ADDR_WIDTH-1:0]ip2bus_mst_addr;
wire [(`C_M_AXI_DATA_WIDTH/8)-1:0]ip2bus_mst_be;
wire [`C_LENGTH_WIDTH-1:0]ip2bus_mst_length;
wire ip2bus_mst_type;
wire ip2bus_mst_lock;
wire ip2bus_mst_reset;
wire bus2ip_mst_cmdack;
wire bus2ip_mst_cmplt;
wire bus2ip_mst_error;
wire bus2ip_mst_rearbitrate;
wire bus2ip_mst_cmd_timeout;
//IPIC read
wire [`C_NATIVE_DATA_WIDTH-1:0]bus2ip_mstrd_d;
wire [(`C_M_AXI_DATA_WIDTH/8)-1:0]bus2ip_mstrd_rem;
wire bus2ip_mstrd_sof_n;
wire bus2ip_mstrd_eof_n;
wire bus2ip_mstrd_src_rdy_n;
wire bus2ip_mstrd_src_dsc_n;
wire ip2bus_mstrd_dst_rdy_n;
wire ip2bus_mstrd_dst_dsc_n;
//IPIC Write
wire [`C_NATIVE_DATA_WIDTH-1:0]ip2bus_mstwr_d;
wire [(`C_M_AXI_DATA_WIDTH/8)-1:0]ip2bus_mstwr_rem;
wire ip2bus_mstwr_src_rdy_n;
wire ip2bus_mstwr_src_dsc_n;
wire ip2bus_mstwr_sof_n;
wire ip2bus_mstwr_eof_n;
wire bus2ip_mstwr_dst_rdy_n;
wire bus2ip_mstwr_dst_dsc_n;

// PE Array & Data Fetching Controller IO
/*                                                                          
PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE     &&&&&&&&&&                                 tttt                            lllllll      IIIIIIIIII     OOOOOOOOO     
P::::::::::::::::P  E::::::::::::::::::::E    &::::::::::&                             ttt:::t                            l:::::l      I::::::::I   OO:::::::::OO   
P::::::PPPPPP:::::P E::::::::::::::::::::E   &::::&&&:::::&                            t:::::t                            l:::::l      I::::::::I OO:::::::::::::OO 
PP:::::P     P:::::PEE::::::EEEEEEEEE::::E  &::::&   &::::&                            t:::::t                            l:::::l      II::::::IIO:::::::OOO:::::::O
  P::::P     P:::::P  E:::::E       EEEEEE  &::::&   &::::&      ccccccccccccccccttttttt:::::ttttttt   rrrrr   rrrrrrrrr   l::::l        I::::I  O::::::O   O::::::O
  P::::P     P:::::P  E:::::E                &::::&&&::::&     cc:::::::::::::::ct:::::::::::::::::t   r::::rrr:::::::::r  l::::l        I::::I  O:::::O     O:::::O
  P::::PPPPPP:::::P   E::::::EEEEEEEEEE      &::::::::::&     c:::::::::::::::::ct:::::::::::::::::t   r:::::::::::::::::r l::::l        I::::I  O:::::O     O:::::O
  P:::::::::::::PP    E:::::::::::::::E       &:::::::&&     c:::::::cccccc:::::ctttttt:::::::tttttt   rr::::::rrrrr::::::rl::::l        I::::I  O:::::O     O:::::O
  P::::PPPPPPPPP      E:::::::::::::::E     &::::::::&   &&&&c::::::c     ccccccc      t:::::t          r:::::r     r:::::rl::::l        I::::I  O:::::O     O:::::O
  P::::P              E::::::EEEEEEEEEE    &:::::&&::&  &:::&c:::::c                   t:::::t          r:::::r     rrrrrrrl::::l        I::::I  O:::::O     O:::::O
  P::::P              E:::::E             &:::::&  &::&&:::&&c:::::c                   t:::::t          r:::::r            l::::l        I::::I  O:::::O     O:::::O
  P::::P              E:::::E       EEEEEE&:::::&   &:::::&  c::::::c     ccccccc      t:::::t    ttttttr:::::r            l::::l        I::::I  O::::::O   O::::::O
PP::::::PP          EE::::::EEEEEEEE:::::E&:::::&    &::::&  c:::::::cccccc:::::c      t::::::tttt:::::tr:::::r           l::::::l     II::::::IIO:::::::OOO:::::::O
P::::::::P          E::::::::::::::::::::E&::::::&&&&::::::&& c:::::::::::::::::c      tt::::::::::::::tr:::::r           l::::::l     I::::::::I OO:::::::::::::OO 
P::::::::P          E::::::::::::::::::::E &&::::::::&&&::::&  cc:::::::::::::::c        tt:::::::::::ttr:::::r           l::::::l     I::::::::I   OO:::::::::OO   
PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE   &&&&&&&&   &&&&&    cccccccccccccccc          ttttttttttt  rrrrrrr           llllllll     IIIIIIIIII     OOOOOOOOO     
*/

// operation flags
wire rst,AXI4_error;

// operation flow
wire config_load,config_done,op_go,op_done,bias_write,write_halt;
wire dataload_ready,tile_done;
wire [3:0] FSM_comp;
wire [3:0] FSM_data;
wire wght_load,ifmap_load,ofmap_offload,padding,maxpooling;
wire read_request,write_request,axi_rst;

// data wire
wire [`C_M_AXI_ADDR_WIDTH-1:0] ctrl_addr;
wire [`C_LENGTH_WIDTH-1:3] ctrl_mst_length;
wire [`C_NATIVE_DATA_WIDTH-1:0] ctrl_din;
wire [`C_NATIVE_DATA_WIDTH-1:0] ctrl_dout;

// BRAM ctrl
wire ifmap_en,wght_en,ofmap_en,ifmap_ready,wght_ready;
wire [7:0] ifmap_wen,wght_wen;
wire [9:0] ifmap_addrin;
wire [9:0] wght_addrin;
wire [9:0] ofmap_addrin;
wire [8*wd-1:0] ifmap_din,wght_din;
wire [8*wd-1:0] ofmap_dout;

// tile config
wire psum_split_condense;
wire [5:0] ifmapR,ifmapC,ofmapR,ofmapC,ifmapRpad,ifmapCpad;
wire [2:0] kernelR,kernelC;
wire [9:0] inchannel;
wire [4:0] outchannel;
wire [1:0] bias_len;

wire psum_split_condense_val,padding_val,maxpooling_val;
wire [1:0] bias_len_val;
assign psum_split_condense_val=psum_split_condense;
assign padding_val=padding;
assign bias_len_val=bias_len;
assign maxpooling_val=maxpooling;


// systolic PE array & BRAM
accelerator_top accelerater_ws8x8_bram( .clk(m00_axi_aclk),.rst(rst),
                                        .ifmap_en(ifmap_en),.wght_en(wght_en),.ofmap_en(ofmap_en),.config_load(config_load),.config_done(config_done),
                                        .op_go(op_go),.ifmap_ready(ifmap_ready),.wght_ready(wght_ready),.op_done(op_done),
                                        .bias_write(bias_write),.ifmap_wen(ifmap_wen),.wght_wen(wght_wen),.ifmap_addrin(ifmap_addrin),.wght_addrin(wght_addrin),.ofmap_addrin(ofmap_addrin),.ifmap_din(ifmap_din),.wght_din(wght_din),
                                        .psum_split_condense(psum_split_condense),.maxpooling(maxpooling),.ifmapR(ifmapRpad),.ifmapC(ifmapCpad),.ofmapR(ofmapR),.ofmapC(ofmapC),.kernelR(kernelR),.kernelC(kernelC),.inchannel(inchannel),.outchannel(outchannel),
                                        .dataload_ready(dataload_ready),.tile_done(tile_done),.FSM(FSM_comp),.ofmap_dout(ofmap_dout));

// AXI Lite Slave port
axi_lite_wrapper AXI_lite(  .s00_axi_aclk(s00_axi_aclk), .s00_axi_aresetn(s00_axi_aresetn), .s00_axi_awaddr(s00_axi_awaddr), .s00_axi_awprot(s00_axi_awprot), 
                            .s00_axi_awvalid(s00_axi_awvalid), .s00_axi_awready(s00_axi_awready), 
                            .s00_axi_wdata(s00_axi_wdata), .s00_axi_wstrb(s00_axi_wstrb), .s00_axi_wvalid(s00_axi_wvalid), .s00_axi_wready(s00_axi_wready),
		                    .s00_axi_bresp(s00_axi_bresp), .s00_axi_bvalid(s00_axi_bvalid), .s00_axi_bready(s00_axi_bready),
		                    .s00_axi_araddr(s00_axi_araddr), .s00_axi_arprot(s00_axi_arprot), .s00_axi_arvalid(s00_axi_arvalid), .s00_axi_arready(s00_axi_arready),
		                    .s00_axi_rdata(s00_axi_rdata), .s00_axi_rresp(s00_axi_rresp), .s00_axi_rvalid(s00_axi_rvalid), .s00_axi_rready(s00_axi_rready),
                            .dataload_ready(dataload_ready), .tile_done(tile_done), .op_done(op_done), .AXI4_cmdack(bus2ip_mst_cmdack), .AXI4_error(AXI4_error), .FSM_comp(FSM_comp), .FSM_data(FSM_data),

                            .psum_split_condense_val(psum_split_condense_val),
		                    .padding_val(padding_val),
		                    .bias_len_val(bias_len_val),
		                    .maxpooling_val(maxpooling_val),
                            
                            .rst(rst), .axi_rst(axi_rst), .config_load(config_load), .config_done(config_done), .op_go(op_go),
                            .psum_split_condense(psum_split_condense), .padding(padding), .maxpooling(maxpooling), .ifmapR(ifmapR), .ifmapC(ifmapC), .ofmapR(ofmapR), .ofmapC(ofmapC), .kernelR(kernelR), .kernelC(kernelC), .inchannel(inchannel), .outchannel(outchannel), .bias_len(bias_len),
                            .wght_load(wght_load), .ifmap_load(ifmap_load), .ofmap_offload(ofmap_offload), .ctrl_addr(ctrl_addr), .ctrl_mst_length(ctrl_mst_length)
                            
                            
                            );

// data fetching controller
data_fectch_ctrl data_control_unit( .clk(m00_axi_aclk), .rst(rst), .axi_rst(axi_rst), 
                                    .wght_load(wght_load), .ifmap_load(ifmap_load), .ofmap_offload(ofmap_offload), .padding(padding),
                                    .psum_split_condense(psum_split_condense), .ifmapR(ifmapR), .ifmapC(ifmapC), .ofmapR(ofmapR), .ofmapC(ofmapC), .kernelR(kernelR), .kernelC(kernelC), .inchannel(inchannel), .outchannel(outchannel), .bias_len(bias_len), .ifmapRpad(ifmapRpad), .ifmapCpad(ifmapCpad), .current_state(FSM_data),
                                    .ifmap_en(ifmap_en), .wght_en(wght_en), .ofmap_en(ofmap_en), .config_load(config_load), .config_done(config_done), .op_go(op_go), .ifmap_ready(ifmap_ready), .wght_ready(wght_ready), .op_done(op_done), .bias_write(bias_write), .write_halt(write_halt), .ifmap_wen(ifmap_wen), .wght_wen(wght_wen), 
                                    .ifmap_addrin(ifmap_addrin), .wght_addrin(wght_addrin), .ofmap_addrin(ofmap_addrin), .dataload_ready(dataload_ready), .tile_done(tile_done), .PE_state(FSM_comp), 
                                    .ctrl_addr(ctrl_addr), .ctrl_mst_length(ctrl_mst_length), .ctrl_din(ctrl_din), .ctrl_dout(ctrl_dout),
                                    .ip2bus_mstrd_req(ip2bus_mstrd_req), .ip2bus_mstwr_req(ip2bus_mstwr_req), .ip2bus_mst_addr(ip2bus_mst_addr), .ip2bus_mst_be(ip2bus_mst_be), .ip2bus_mst_length(ip2bus_mst_length), .ip2bus_mst_type(ip2bus_mst_type), .ip2bus_mst_lock(ip2bus_mst_lock), .ip2bus_mst_reset(ip2bus_mst_reset), 
                                    .bus2ip_mst_cmdack(bus2ip_mst_cmdack), .bus2ip_mst_cmplt(bus2ip_mst_cmplt), .bus2ip_mst_error(bus2ip_mst_error), .bus2ip_mst_rearbitrate(bus2ip_mst_rearbitrate), .bus2ip_mst_timeout(bus2ip_mst_cmd_timeout),
                                    .bus2ip_mstrd_d(bus2ip_mstrd_d), .bus2ip_mstrd_rem(bus2ip_mstrd_rem), .bus2ip_mstrd_sof_n(bus2ip_mstrd_sof_n), .bus2ip_mstrd_eof_n(bus2ip_mstrd_eof_n), .bus2ip_mstrd_src_rdy_n(bus2ip_mstrd_src_rdy_n), .bus2ip_mstrd_src_dsc_n(bus2ip_mstrd_src_dsc_n), .ip2bus_mstrd_dst_rdy_n(ip2bus_mstrd_dst_rdy_n), .ip2bus_mstrd_dst_dsc_n(ip2bus_mstrd_dst_dsc_n), 
                                    .ip2bus_mstwr_d(ip2bus_mstwr_d), .ip2bus_mstwr_rem(ip2bus_mstwr_rem), .ip2bus_mstwr_src_rdy_n(ip2bus_mstwr_src_rdy_n), .ip2bus_mstwr_src_dsc_n(ip2bus_mstwr_src_dsc_n), .ip2bus_mstwr_sof_n(ip2bus_mstwr_sof_n), .ip2bus_mstwr_eof_n(ip2bus_mstwr_eof_n), .bus2ip_mstwr_dst_rdy_n(bus2ip_mstwr_dst_rdy_n), .bus2ip_mstwr_dst_dsc_n(bus2ip_mstwr_dst_dsc_n)
                                    );

data_dispatcher axi_full_dispatch(.clk(m00_axi_aclk),.FSM_data(FSM_data),.write_halt(write_halt),.ctrl2pe(ctrl_dout),.pe2ctrl(ctrl_din),.ifmap_din(ifmap_din),.wght_din(wght_din),.ofmap_dout(ofmap_dout));

// LogiCORE AXI4 Master Burst
axi_master_burst AXI_full ( .m_axi_aclk(m00_axi_aclk),.m_axi_aresetn(m00_axi_aresetn),.md_error(AXI4_error),.m_axi_arready(m00_axi_arready),
                            .m_axi_arvalid(m00_axi_arvalid),.m_axi_araddr(m00_axi_araddr),.m_axi_arlen(m00_axi_arlen),.m_axi_arsize(m00_axi_arsize),
                            .m_axi_arburst(m00_axi_arburst),.m_axi_arprot(m00_axi_arprot),.m_axi_arcache(m00_axi_arcache),
                            //-- MMap Read Data Channel 
                            .m_axi_rready(m00_axi_rready),.m_axi_rvalid(m00_axi_rvalid),.m_axi_rdata(m00_axi_rdata),.m_axi_rresp(m00_axi_rresp),.m_axi_rlast(m00_axi_rlast),
                            //AXI4 Master Write Channel
                            .m_axi_awready(m00_axi_awready),.m_axi_awvalid(m00_axi_awvalid),.m_axi_awaddr(m00_axi_awaddr),.m_axi_awlen(m00_axi_awlen),.m_axi_awsize(m00_axi_awsize),
                            .m_axi_awburst(m00_axi_awburst),.m_axi_awprot(m00_axi_awprot),.m_axi_awcache(m00_axi_awcache),
                            //Write Data Channel 
                            .m_axi_wready(m00_axi_wready),.m_axi_wvalid(m00_axi_wvalid),.m_axi_wdata(m00_axi_wdata),.m_axi_wstrb(m00_axi_wstrb),.m_axi_wlast(m00_axi_wlast),
                            //Write Response Channel 
                            .m_axi_bready(m00_axi_bready),.m_axi_bvalid(m00_axi_bvalid),.m_axi_bresp(m00_axi_bresp),
                            //IPIC Request/Qualifiers
                            .ip2bus_mstrd_req(ip2bus_mstrd_req),.ip2bus_mstwr_req(ip2bus_mstwr_req),.ip2bus_mst_addr(ip2bus_mst_addr),.ip2bus_mst_length(ip2bus_mst_length),
                            .ip2bus_mst_be(ip2bus_mst_be),.ip2bus_mst_type(ip2bus_mst_type),.ip2bus_mst_lock(ip2bus_mst_lock),.ip2bus_mst_reset(ip2bus_mst_reset),
                            //IPIC Request Status Reply
                            .bus2ip_mst_cmdack(bus2ip_mst_cmdack),.bus2ip_mst_cmplt(bus2ip_mst_cmplt),.bus2ip_mst_error(bus2ip_mst_error),.bus2ip_mst_rearbitrate(bus2ip_mst_rearbitrate),
                            .bus2ip_mst_cmd_timeout(bus2ip_mst_cmd_timeout),
                            //IPIC Read LocalLink Channel
                            .bus2ip_mstrd_d(bus2ip_mstrd_d),.bus2ip_mstrd_rem(bus2ip_mstrd_rem),.bus2ip_mstrd_sof_n(bus2ip_mstrd_sof_n),.bus2ip_mstrd_eof_n(bus2ip_mstrd_eof_n),
                            .bus2ip_mstrd_src_rdy_n(bus2ip_mstrd_src_rdy_n),.bus2ip_mstrd_src_dsc_n(bus2ip_mstrd_src_dsc_n),.ip2bus_mstrd_dst_rdy_n(ip2bus_mstrd_dst_rdy_n),
                            .ip2bus_mstrd_dst_dsc_n(ip2bus_mstrd_dst_dsc_n),
                            //IPIC Write LocalLink Channel
                            .ip2bus_mstwr_d(ip2bus_mstwr_d),.ip2bus_mstwr_rem(ip2bus_mstwr_rem),.ip2bus_mstwr_sof_n(ip2bus_mstwr_sof_n),.ip2bus_mstwr_eof_n(ip2bus_mstwr_eof_n),
                            .ip2bus_mstwr_src_rdy_n(ip2bus_mstwr_src_rdy_n),.ip2bus_mstwr_src_dsc_n(ip2bus_mstwr_src_dsc_n),.bus2ip_mstwr_dst_rdy_n(bus2ip_mstwr_dst_rdy_n),
                            .bus2ip_mstwr_dst_dsc_n(bus2ip_mstwr_dst_dsc_n));    


endmodule
