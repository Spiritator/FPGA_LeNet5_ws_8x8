`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/12/29 18:28:58
// Design Name: 
// Module Name: data_fectch_ctrl
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

module data_fectch_ctrl(clk, rst, axi_rst, wght_load, ifmap_load, ofmap_offload, padding,
                        psum_split_condense, ifmapR, ifmapC, ofmapR, ofmapC, kernelR, kernelC, inchannel, outchannel, bias_len, ifmapRpad, ifmapCpad, current_state,
                        ifmap_en, wght_en, ofmap_en, config_load, config_done, op_go, ifmap_ready, wght_ready, op_done, bias_write, write_halt, ifmap_wen, wght_wen, 
                        ifmap_addrin, wght_addrin, ofmap_addrin, dataload_ready, tile_done, PE_state, 
                        ctrl_addr, ctrl_mst_length, ctrl_din, ctrl_dout,
                        ip2bus_mstrd_req, ip2bus_mstwr_req, ip2bus_mst_addr, ip2bus_mst_be, ip2bus_mst_length, ip2bus_mst_type, ip2bus_mst_lock, ip2bus_mst_reset, 
                        bus2ip_mst_cmdack, bus2ip_mst_cmplt, bus2ip_mst_error, bus2ip_mst_rearbitrate, bus2ip_mst_timeout,
                        bus2ip_mstrd_d, bus2ip_mstrd_rem, bus2ip_mstrd_sof_n, bus2ip_mstrd_eof_n, bus2ip_mstrd_src_rdy_n, bus2ip_mstrd_src_dsc_n, ip2bus_mstrd_dst_rdy_n, ip2bus_mstrd_dst_dsc_n, 
                        ip2bus_mstwr_d, ip2bus_mstwr_rem, ip2bus_mstwr_src_rdy_n, ip2bus_mstwr_src_dsc_n, ip2bus_mstwr_sof_n, ip2bus_mstwr_eof_n, bus2ip_mstwr_dst_rdy_n, bus2ip_mstwr_dst_dsc_n
                        );

parameter wd=8;
// FSM of data fetching controller
parameter idle=4'd0, load_wght_req=4'd1, load_wght_burst=4'd2, load_wght_cmplt=4'd3, load_ifmap_req=4'd4, load_ifmap_burst=4'd5, load_ifmap_cmplt=4'd6, ifmap_filling_zero=4'd7, offload_ofmap_req=4'd8, offload_ofmap_burst=4'd9, offload_ofmap_cmplt=4'd10;
parameter fill_left=2'd0, fill_up=2'd1, fill_down=2'd2, fill_right=2'd3;
// FSM of computation controller
parameter load_tile_config=4'd1, load_data_b=4'd2, load_data=4'd3, PE_shift_wght=4'd4, slice_check=4'd5, MAC_op=4'd6, offload_ofmap=4'd7, ready_go=4'd8, pooling=4'd9;

// Data Fetch ctrl
input clk,rst,wght_load,ifmap_load,ofmap_offload,padding;

// Tile Shape Info
input psum_split_condense;
input [5:0] ifmapR,ifmapC,ofmapR,ofmapC;
input [2:0] kernelR,kernelC;
input [9:0] inchannel;
input [4:0] outchannel;
input [1:0] bias_len;
output [5:0] ifmapRpad,ifmapCpad;

// FSM
output [3:0] current_state;
reg [3:0] current_state, next_state;


// PE array ctrl
output reg ifmap_en,wght_en,ofmap_en,ifmap_ready,wght_ready,op_done,bias_write,write_halt;
output reg [7:0] ifmap_wen;
output reg [7:0] wght_wen;
output reg [9:0] ifmap_addrin;
output reg [9:0] wght_addrin;
output reg [9:0] ofmap_addrin;
input config_load,config_done,op_go,dataload_ready,tile_done;
input [3:0] PE_state;


// IPIC ctrl
input axi_rst;
input [`C_M_AXI_ADDR_WIDTH-1:0] ctrl_addr;
input [`C_LENGTH_WIDTH-1:3] ctrl_mst_length;
input [`C_NATIVE_DATA_WIDTH-1:0] ctrl_din;
output [`C_NATIVE_DATA_WIDTH-1:0] ctrl_dout;
//IPIC command Interface
output reg ip2bus_mstrd_req;
output reg ip2bus_mstwr_req;
output [`C_M_AXI_ADDR_WIDTH-1:0]ip2bus_mst_addr;
output reg [(`C_M_AXI_DATA_WIDTH/8)-1:0]ip2bus_mst_be;
output [`C_LENGTH_WIDTH-1:0]ip2bus_mst_length;
output reg ip2bus_mst_type;
output ip2bus_mst_lock;
output ip2bus_mst_reset;
input bus2ip_mst_cmdack;
input bus2ip_mst_cmplt;
input bus2ip_mst_error;
input bus2ip_mst_rearbitrate;
input bus2ip_mst_timeout;
//IPIC read
input [`C_NATIVE_DATA_WIDTH-1:0]bus2ip_mstrd_d;
input [(`C_M_AXI_DATA_WIDTH/8)-1:0]bus2ip_mstrd_rem;
input bus2ip_mstrd_sof_n;
input bus2ip_mstrd_eof_n;
input bus2ip_mstrd_src_rdy_n;
input bus2ip_mstrd_src_dsc_n;
output reg ip2bus_mstrd_dst_rdy_n;
output reg ip2bus_mstrd_dst_dsc_n;
//IPIC Write
output [`C_NATIVE_DATA_WIDTH-1:0]ip2bus_mstwr_d;
output [(`C_M_AXI_DATA_WIDTH/8)-1:0]ip2bus_mstwr_rem;
output reg ip2bus_mstwr_src_rdy_n;
output reg ip2bus_mstwr_src_dsc_n;
output reg ip2bus_mstwr_sof_n;
output reg ip2bus_mstwr_eof_n;
input bus2ip_mstwr_dst_rdy_n;
input bus2ip_mstwr_dst_dsc_n;


// data shape counters
wire [9:0] n_psum_slices,npslccon,npslcinch;
wire [1:0] outchsplit;
wire [5:0] Irref,Icref;
wire [9:0] Psplitref;
wire [2:0] ifmap_order_ovf;
wire [1:0] padr,padc;
reg [5:0] ifmapRpad,ifmapCpad,ifmapRinner,ifmapCinner;
reg [5:0] Iridx,Icidx;
reg [9:0] Psplitidx;
wire bias_ovf;
reg [9:0] i2dsize,slc_iaddrb_ic,slc_iaddrb_ps;
reg [9:0] o2dsize,ofmapsize;
wire [9:0] offofref;

reg [9:0] burst_cnt;

// state flags
wire zerofilled;
reg wr_cache;
reg [1:0] fill_step,rdydly;

/*
                                                          ffffffffffffffff    iiii                      
                                                         f::::::::::::::::f  i::::i                     
                                                        f::::::::::::::::::f  iiii                      
                                                        f::::::fffffff:::::f                            
    cccccccccccccccc   ooooooooooo   nnnn  nnnnnnnn     f:::::f       ffffffiiiiiii    ggggggggg   ggggg
  cc:::::::::::::::c oo:::::::::::oo n:::nn::::::::nn   f:::::f             i:::::i   g:::::::::ggg::::g
 c:::::::::::::::::co:::::::::::::::on::::::::::::::nn f:::::::ffffff        i::::i  g:::::::::::::::::g
c:::::::cccccc:::::co:::::ooooo:::::onn:::::::::::::::nf::::::::::::f        i::::i g::::::ggggg::::::gg
c::::::c     ccccccco::::o     o::::o  n:::::nnnn:::::nf::::::::::::f        i::::i g:::::g     g:::::g 
c:::::c             o::::o     o::::o  n::::n    n::::nf:::::::ffffff        i::::i g:::::g     g:::::g 
c:::::c             o::::o     o::::o  n::::n    n::::n f:::::f              i::::i g:::::g     g:::::g 
c::::::c     ccccccco::::o     o::::o  n::::n    n::::n f:::::f              i::::i g::::::g    g:::::g 
c:::::::cccccc:::::co:::::ooooo:::::o  n::::n    n::::nf:::::::f            i::::::ig:::::::ggggg:::::g 
 c:::::::::::::::::co:::::::::::::::o  n::::n    n::::nf:::::::f            i::::::i g::::::::::::::::g 
  cc:::::::::::::::c oo:::::::::::oo   n::::n    n::::nf:::::::f            i::::::i  gg::::::::::::::g 
    cccccccccccccccc   ooooooooooo     nnnnnn    nnnnnnfffffffff            iiiiiiii    gggggggg::::::g 
                                                                                                g:::::g 
                                                                                    gggggg      g:::::g 
                                                                                    g:::::gg   gg:::::g 
                                                                                     g::::::ggg:::::::g 
                                                                                      gg:::::::::::::g  
                                                                                        ggg::::::ggg    
                                                                                           gggggg       
*/

// tile config calculation
assign npslccon=10'd1;
assign npslcinch={3'd0, inchannel[9:3] + ( |inchannel[2:0] ) };
assign n_psum_slices=psum_split_condense ? npslccon : npslcinch;
assign outchsplit=outchannel[4:3] + ( |outchannel[2:0] );
assign Irref=ifmapRinner-1'b1;
assign Icref=ifmapCinner-1'b1;
assign offofref=ofmapsize-2'd2;
assign padr=padding ? kernelR[2:1] : 2'd0;
assign padc=padding ? kernelC[2:1] : 2'd0;
assign Psplitref=n_psum_slices-1'b1;
assign ifmap_order_ovf={Psplitidx==Psplitref, Icidx==Icref, Iridx==Irref};

assign bias_ovf = wght_addrin[1:0]==bias_len-1'b1;
assign zerofilled = (fill_step==2'd3 && ifmap_ready==1'b1);

// addr gen pipeline
always @(posedge clk) 
begin
    i2dsize<=ifmapRpad*ifmapCpad;
    o2dsize<=ofmapR*ofmapC;
    ofmapsize<=o2dsize*outchsplit;

    if (padding) 
    begin
        ifmapCpad<=ifmapC+kernelC-1'b1;
        ifmapRpad<=ifmapR+kernelR-1'b1;
        ifmapCinner<=ifmapC+padc;
        ifmapRinner<=ifmapR+padr;
    end 
    else 
    begin
        ifmapCpad<=ifmapC;
        ifmapRpad<=ifmapR;
        ifmapCinner<=ifmapC;
        ifmapRinner=ifmapR;
    end
end

// IPIC 
assign ip2bus_mstwr_rem = 8'b00000000;
assign ip2bus_mstwr_d = ctrl_din;
assign ctrl_dout = bus2ip_mstrd_d;
assign ip2bus_mst_addr = ctrl_addr;
assign ip2bus_mst_length = {ctrl_mst_length,3'b0};
assign ip2bus_mst_lock = 1'b0;
assign ip2bus_mst_reset = axi_rst;

/*
FFFFFFFFFFFFFFFFFFFFFF   SSSSSSSSSSSSSSS MMMMMMMM               MMMMMMMM
F::::::::::::::::::::F SS:::::::::::::::SM:::::::M             M:::::::M
F::::::::::::::::::::FS:::::SSSSSS::::::SM::::::::M           M::::::::M
FF::::::FFFFFFFFF::::FS:::::S     SSSSSSSM:::::::::M         M:::::::::M
  F:::::F       FFFFFFS:::::S            M::::::::::M       M::::::::::M
  F:::::F             S:::::S            M:::::::::::M     M:::::::::::M
  F::::::FFFFFFFFFF    S::::SSSS         M:::::::M::::M   M::::M:::::::M
  F:::::::::::::::F     SS::::::SSSSS    M::::::M M::::M M::::M M::::::M
  F:::::::::::::::F       SSS::::::::SS  M::::::M  M::::M::::M  M::::::M
  F::::::FFFFFFFFFF          SSSSSS::::S M::::::M   M:::::::M   M::::::M
  F:::::F                         S:::::SM::::::M    M:::::M    M::::::M
  F:::::F                         S:::::SM::::::M     MMMMM     M::::::M
FF:::::::FF           SSSSSSS     S:::::SM::::::M               M::::::M
F::::::::FF           S::::::SSSSSS:::::SM::::::M               M::::::M
F::::::::FF           S:::::::::::::::SS M::::::M               M::::::M
FFFFFFFFFFF            SSSSSSSSSSSSSSS   MMMMMMMM               MMMMMMMM
*/

always @(posedge clk or posedge rst) 
begin
    if (rst) 
        current_state <= idle; 
    else 
        current_state <= next_state; 
end

always @(current_state or bus2ip_mst_cmdack or wght_load or ifmap_load or ofmap_offload or bus2ip_mstrd_sof_n or bus2ip_mstrd_eof_n or bus2ip_mst_cmplt or padding or zerofilled or ip2bus_mstwr_sof_n or ip2bus_mstwr_eof_n) 
begin
    case (current_state)
        idle: 
        begin
            case ({wght_load,ifmap_load,ofmap_offload})
                3'b100: next_state=load_wght_req;
                3'b010: next_state=load_ifmap_req;
                3'b001: next_state=offload_ofmap_req;
                default: next_state=idle;
            endcase
        end
        load_wght_req:
        begin
            if (!bus2ip_mst_cmdack)
                next_state=load_wght_req;
            else
                next_state=load_wght_burst;
        end
        load_wght_burst:
        begin
            if (bus2ip_mstrd_eof_n)
                next_state=load_wght_burst;
            else
                next_state=load_wght_cmplt;
        end
        load_wght_cmplt:
        begin
            if (bus2ip_mst_cmplt)
                next_state=idle;
            else
                next_state=load_wght_cmplt;
        end
        load_ifmap_req:
        begin
            if (!bus2ip_mst_cmdack)
                next_state=load_ifmap_req;
            else
                next_state=load_ifmap_burst;
        end
        load_ifmap_burst:
        begin
            if (bus2ip_mstrd_eof_n)
                next_state=load_ifmap_burst;
            else
                next_state=load_ifmap_cmplt;
        end
        load_ifmap_cmplt:
        begin
            if (bus2ip_mst_cmplt)
                if (padding)
                   next_state=ifmap_filling_zero; 
                else
                    next_state=idle;
            else
                next_state=load_ifmap_cmplt;
        end
        ifmap_filling_zero:
        begin
            if (zerofilled)
                next_state=idle;
            else
                next_state=ifmap_filling_zero;
        end
        offload_ofmap_req:
        begin
            if (!bus2ip_mst_cmdack)
                next_state=offload_ofmap_req;
            else
                next_state=offload_ofmap_burst;
        end
        offload_ofmap_burst:
        begin
            if (ip2bus_mstwr_eof_n) 
                next_state=offload_ofmap_burst;
            else
                next_state=offload_ofmap_cmplt;
        end
        offload_ofmap_cmplt:
        begin
            if (bus2ip_mst_cmplt)
                next_state=idle;
            else
                next_state=offload_ofmap_cmplt;
        end
        default: 
            next_state=idle;
    endcase
end

/*
                                                                                                           bbbbbbbb            
DDDDDDDDDDDDD      FFFFFFFFFFFFFFFFFFFFFF             CCCCCCCCCCCCC                                        b::::::b            
D::::::::::::DDD   F::::::::::::::::::::F          CCC::::::::::::C                                        b::::::b            
D:::::::::::::::DD F::::::::::::::::::::F        CC:::::::::::::::C                                        b::::::b            
DDD:::::DDDDD:::::DFF::::::FFFFFFFFF::::F       C:::::CCCCCCCC::::C                                         b:::::b            
  D:::::D    D:::::D F:::::F       FFFFFF      C:::::C       CCCCCC   ooooooooooo      mmmmmmm    mmmmmmm   b:::::bbbbbbbbb    
  D:::::D     D:::::DF:::::F                  C:::::C               oo:::::::::::oo  mm:::::::m  m:::::::mm b::::::::::::::bb  
  D:::::D     D:::::DF::::::FFFFFFFFFF        C:::::C              o:::::::::::::::om::::::::::mm::::::::::mb::::::::::::::::b 
  D:::::D     D:::::DF:::::::::::::::F        C:::::C              o:::::ooooo:::::om::::::::::::::::::::::mb:::::bbbbb:::::::b
  D:::::D     D:::::DF:::::::::::::::F        C:::::C              o::::o     o::::om:::::mmm::::::mmm:::::mb:::::b    b::::::b
  D:::::D     D:::::DF::::::FFFFFFFFFF        C:::::C              o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
  D:::::D     D:::::DF:::::F                  C:::::C              o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
  D:::::D    D:::::D F:::::F                   C:::::C       CCCCCCo::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
DDD:::::DDDDD:::::DFF:::::::FF                  C:::::CCCCCCCC::::Co:::::ooooo:::::om::::m   m::::m   m::::mb:::::bbbbbb::::::b
D:::::::::::::::DD F::::::::FF                   CC:::::::::::::::Co:::::::::::::::om::::m   m::::m   m::::mb::::::::::::::::b 
D::::::::::::DDD   F::::::::FF                     CCC::::::::::::C oo:::::::::::oo m::::m   m::::m   m::::mb:::::::::::::::b  
DDDDDDDDDDDDD      FFFFFFFFFFF                        CCCCCCCCCCCCC   ooooooooooo   mmmmmm   mmmmmm   mmmmmmbbbbbbbbbbbbbbbb   
*/


always @(current_state) 
begin
    case (current_state)
        idle: 
        begin
            ip2bus_mstrd_req=1'b0;
            ip2bus_mstwr_req=1'b0;
            ip2bus_mst_be=8'b00000000;
            ip2bus_mst_type=1'b0;
        end
        load_wght_req:
        begin
            ip2bus_mstrd_req=1'b1;
            ip2bus_mstwr_req=1'b0;
            ip2bus_mst_be=8'b11111111;
            ip2bus_mst_type=1'b1;
        end
        load_ifmap_req:
        begin
            ip2bus_mstrd_req=1'b1;
            ip2bus_mstwr_req=1'b0;
            ip2bus_mst_be=8'b11111111;
            ip2bus_mst_type=1'b1;
        end
        offload_ofmap_req:
        begin
            ip2bus_mstrd_req=1'b0;
            ip2bus_mstwr_req=1'b1;
            ip2bus_mst_be=8'b11111111;
            ip2bus_mst_type=1'b1;
        end
        default: 
        begin
            ip2bus_mstrd_req=1'b0;
            ip2bus_mstwr_req=1'b0;
            ip2bus_mst_be=8'b00000000;
            ip2bus_mst_type=1'b0;
        end
    endcase
end


/*
DDDDDDDDDDDDD      FFFFFFFFFFFFFFFFFFFFFF        SSSSSSSSSSSSSSS                                         
D::::::::::::DDD   F::::::::::::::::::::F      SS:::::::::::::::S                                        
D:::::::::::::::DD F::::::::::::::::::::F     S:::::SSSSSS::::::S                                        
DDD:::::DDDDD:::::DFF::::::FFFFFFFFF::::F     S:::::S     SSSSSSS                                        
  D:::::D    D:::::D F:::::F       FFFFFF     S:::::S                eeeeeeeeeeee       qqqqqqqqq   qqqqq
  D:::::D     D:::::DF:::::F                  S:::::S              ee::::::::::::ee    q:::::::::qqq::::q
  D:::::D     D:::::DF::::::FFFFFFFFFF         S::::SSSS          e::::::eeeee:::::ee q:::::::::::::::::q
  D:::::D     D:::::DF:::::::::::::::F          SS::::::SSSSS    e::::::e     e:::::eq::::::qqqqq::::::qq
  D:::::D     D:::::DF:::::::::::::::F            SSS::::::::SS  e:::::::eeeee::::::eq:::::q     q:::::q 
  D:::::D     D:::::DF::::::FFFFFFFFFF               SSSSSS::::S e:::::::::::::::::e q:::::q     q:::::q 
  D:::::D     D:::::DF:::::F                              S:::::Se::::::eeeeeeeeeee  q:::::q     q:::::q 
  D:::::D    D:::::D F:::::F                              S:::::Se:::::::e           q::::::q    q:::::q 
DDD:::::DDDDD:::::DFF:::::::FF                SSSSSSS     S:::::Se::::::::e          q:::::::qqqqq:::::q 
D:::::::::::::::DD F::::::::FF                S::::::SSSSSS:::::S e::::::::eeeeeeee   q::::::::::::::::q 
D::::::::::::DDD   F::::::::FF                S:::::::::::::::SS   ee:::::::::::::e    qq::::::::::::::q 
DDDDDDDDDDDDD      FFFFFFFFFFF                 SSSSSSSSSSSSSSS       eeeeeeeeeeeeee      qqqqqqqq::::::q 
                                                                                                 q:::::q 
                                                                                                 q:::::q 
                                                                                                q:::::::q
                                                                                                q:::::::q
                                                                                                q:::::::q
                                                                                                qqqqqqqqq
*/

always @(posedge clk or posedge rst) 
begin
    if(rst)
    begin
        ip2bus_mstwr_src_dsc_n <= 1'b1;
        ip2bus_mstrd_dst_dsc_n <= 1'b1;
    end
end

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        ip2bus_mstrd_dst_rdy_n<=1'b1;
        ip2bus_mstwr_src_rdy_n<=1'b1;
        ip2bus_mstwr_sof_n<=1'b1;
        ip2bus_mstwr_eof_n<=1'b1;
    end 
    else 
    begin
        case (current_state)
            idle: 
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b1;
                ip2bus_mstwr_src_rdy_n<=1'b1;
                ip2bus_mstwr_sof_n<=1'b1;
                ip2bus_mstwr_eof_n<=1'b1;
            end
            load_wght_req,load_wght_burst,load_ifmap_req,load_ifmap_burst:
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b0;
                ip2bus_mstwr_src_rdy_n<=1'b1;
                ip2bus_mstwr_sof_n<=1'b1;
                ip2bus_mstwr_eof_n<=1'b1;
            end
            load_wght_cmplt,load_ifmap_cmplt,ifmap_filling_zero,offload_ofmap_cmplt:
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b1;
                ip2bus_mstwr_src_rdy_n<=1'b1;
                ip2bus_mstwr_sof_n<=1'b1;
                ip2bus_mstwr_eof_n<=1'b1;
            end
            offload_ofmap_req:
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b1;
                ip2bus_mstwr_src_rdy_n<=1'b0;
                ip2bus_mstwr_sof_n<=1'b0;
                ip2bus_mstwr_eof_n<=1'b1;
            end
            offload_ofmap_burst:
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b1;
                ip2bus_mstwr_src_rdy_n<=1'b0;

                if (!bus2ip_mstwr_dst_rdy_n) 
                    ip2bus_mstwr_sof_n<=1'b1;
                else 
                    ip2bus_mstwr_sof_n<=ip2bus_mstwr_sof_n;

                if (burst_cnt==offofref)
                    ip2bus_mstwr_eof_n<=1'b0;
                else
                    ip2bus_mstwr_eof_n<=ip2bus_mstwr_eof_n;
            end
            default: 
            begin
                ip2bus_mstrd_dst_rdy_n<=1'b1;
                ip2bus_mstwr_src_rdy_n<=1'b1;
                ip2bus_mstwr_sof_n<=1'b1;
                ip2bus_mstwr_eof_n<=1'b1;
            end
        endcase
    end
end



/*
PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE             CCCCCCCCCCCCC                                        b::::::b            
P::::::::::::::::P  E::::::::::::::::::::E          CCC::::::::::::C                                        b::::::b            
P::::::PPPPPP:::::P E::::::::::::::::::::E        CC:::::::::::::::C                                        b::::::b            
PP:::::P     P:::::PEE::::::EEEEEEEEE::::E       C:::::CCCCCCCC::::C                                         b:::::b            
  P::::P     P:::::P  E:::::E       EEEEEE      C:::::C       CCCCCC   ooooooooooo      mmmmmmm    mmmmmmm   b:::::bbbbbbbbb    
  P::::P     P:::::P  E:::::E                  C:::::C               oo:::::::::::oo  mm:::::::m  m:::::::mm b::::::::::::::bb  
  P::::PPPPPP:::::P   E::::::EEEEEEEEEE        C:::::C              o:::::::::::::::om::::::::::mm::::::::::mb::::::::::::::::b 
  P:::::::::::::PP    E:::::::::::::::E        C:::::C              o:::::ooooo:::::om::::::::::::::::::::::mb:::::bbbbb:::::::b
  P::::PPPPPPPPP      E:::::::::::::::E        C:::::C              o::::o     o::::om:::::mmm::::::mmm:::::mb:::::b    b::::::b
  P::::P              E::::::EEEEEEEEEE        C:::::C              o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
  P::::P              E:::::E                  C:::::C              o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
  P::::P              E:::::E       EEEEEE      C:::::C       CCCCCCo::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b
PP::::::PP          EE::::::EEEEEEEE:::::E       C:::::CCCCCCCC::::Co:::::ooooo:::::om::::m   m::::m   m::::mb:::::bbbbbb::::::b
P::::::::P          E::::::::::::::::::::E        CC:::::::::::::::Co:::::::::::::::om::::m   m::::m   m::::mb::::::::::::::::b 
P::::::::P          E::::::::::::::::::::E          CCC::::::::::::C oo:::::::::::oo m::::m   m::::m   m::::mb:::::::::::::::b  
PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE             CCCCCCCCCCCCC   ooooooooooo   mmmmmm   mmmmmm   mmmmmmbbbbbbbbbbbbbbbb   
*/

always @(current_state or PE_state or bias_ovf or ip2bus_mstrd_dst_rdy_n or bus2ip_mstrd_src_rdy_n or rdydly) 
begin
    case (current_state)
        idle: 
        begin
            ifmap_en=1'b0;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b1;
        end
        load_wght_req:
        begin
            ifmap_en=1'b0;
            wght_en=1'b1;
            ofmap_en=1'b0;
            ifmap_wen=8'b00000000;
            wght_wen=8'b11111111;
            bias_write=1'b1;
        end
        load_wght_burst:
        begin
            ifmap_en=1'b0;
            wght_en=1'b1;
            ofmap_en=1'b0;
            ifmap_wen=8'b00000000;
            wght_wen=8'b11111111;
            if (PE_state==load_data_b) 
            begin
                if (bias_ovf && !ip2bus_mstrd_dst_rdy_n && !bus2ip_mstrd_src_rdy_n) 
                    bias_write=1'b0;
                else 
                    bias_write=1'b1;
            end 
            else 
                bias_write=1'b0;
        end
        load_wght_cmplt:
        begin
            ifmap_en=1'b0;
            wght_en=1'b1;
            ofmap_en=1'b0;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        load_ifmap_req:
        begin
            ifmap_en=1'b1;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen=8'b11111111;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        load_ifmap_burst:
        begin
            ifmap_en=1'b1;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen=8'b11111111;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        load_ifmap_cmplt:
        begin
            ifmap_en=1'b1;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen={8{~rdydly[1]}};
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        ifmap_filling_zero:
        begin
            ifmap_en=1'b1;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen=8'b11111111;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        offload_ofmap_req:
        begin
            ifmap_en=1'b0;
            wght_en=1'b0;
            ofmap_en=1'b1;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        offload_ofmap_burst:
        begin
            ifmap_en=1'b0;
            wght_en=1'b0;
            ofmap_en=1'b1;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        offload_ofmap_cmplt:
        begin
            ifmap_en=1'b0;
            wght_en=1'b0;
            ofmap_en=1'b1;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b0;
        end
        default: 
        begin
            ifmap_en=1'b0;
            wght_en=1'b0;
            ofmap_en=1'b0;
            ifmap_wen=8'b00000000;
            wght_wen=8'b00000000;
            bias_write=1'b1;
        end
    endcase
end


/*
PPPPPPPPPPPPPPPPP   EEEEEEEEEEEEEEEEEEEEEE        SSSSSSSSSSSSSSS                                         
P::::::::::::::::P  E::::::::::::::::::::E      SS:::::::::::::::S                                        
P::::::PPPPPP:::::P E::::::::::::::::::::E     S:::::SSSSSS::::::S                                        
PP:::::P     P:::::PEE::::::EEEEEEEEE::::E     S:::::S     SSSSSSS                                        
  P::::P     P:::::P  E:::::E       EEEEEE     S:::::S                eeeeeeeeeeee       qqqqqqqqq   qqqqq
  P::::P     P:::::P  E:::::E                  S:::::S              ee::::::::::::ee    q:::::::::qqq::::q
  P::::PPPPPP:::::P   E::::::EEEEEEEEEE         S::::SSSS          e::::::eeeee:::::ee q:::::::::::::::::q
  P:::::::::::::PP    E:::::::::::::::E          SS::::::SSSSS    e::::::e     e:::::eq::::::qqqqq::::::qq
  P::::PPPPPPPPP      E:::::::::::::::E            SSS::::::::SS  e:::::::eeeee::::::eq:::::q     q:::::q 
  P::::P              E::::::EEEEEEEEEE               SSSSSS::::S e:::::::::::::::::e q:::::q     q:::::q 
  P::::P              E:::::E                              S:::::Se::::::eeeeeeeeeee  q:::::q     q:::::q 
  P::::P              E:::::E       EEEEEE                 S:::::Se:::::::e           q::::::q    q:::::q 
PP::::::PP          EE::::::EEEEEEEE:::::E     SSSSSSS     S:::::Se::::::::e          q:::::::qqqqq:::::q 
P::::::::P          E::::::::::::::::::::E     S::::::SSSSSS:::::S e::::::::eeeeeeee   q::::::::::::::::q 
P::::::::P          E::::::::::::::::::::E     S:::::::::::::::SS   ee:::::::::::::e    qq::::::::::::::q 
PPPPPPPPPP          EEEEEEEEEEEEEEEEEEEEEE      SSSSSSSSSSSSSSS       eeeeeeeeeeeeee      qqqqqqqq::::::q 
                                                                                                  q:::::q 
                                                                                                  q:::::q 
                                                                                                 q:::::::q
                                                                                                 q:::::::q
                                                                                                 q:::::::q
                                                                                                 qqqqqqqqq
*/

always @(posedge clk or posedge rst) 
begin
    if (rst) begin
        ifmap_ready<=1'b0;
        wght_ready<=1'b0;
        op_done<=1'b0;
        ifmap_addrin<=10'd0;
        wght_addrin<=10'd0;
        ofmap_addrin<=10'd0;
        Iridx<=5'd0;
        Icidx<=5'd0;
        Psplitidx<=10'd0;
        slc_iaddrb_ps<=10'd0;
        slc_iaddrb_ic<=10'd0;
        fill_step<=2'd0;
        rdydly<=2'd0;
        burst_cnt<=10'd0;
        write_halt<=1'b0;
        wr_cache<=1'b0;
    end else begin
        case (current_state)
            idle: 
            begin
                if (op_go) 
                begin
                    ifmap_ready<=1'b0;
                    wght_ready<=1'b0;
                end 
                else 
                begin
                    ifmap_ready<=ifmap_ready;
                    wght_ready<=wght_ready;
                end

                if (config_load) 
                    op_done<=1'b0;
                else 
                    op_done<=op_done;

                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=fill_step;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
            load_wght_req:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=1'b0;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=fill_step;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
            load_wght_burst:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=1'b0;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;                
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=fill_step;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;

                if (!ip2bus_mstrd_dst_rdy_n && !bus2ip_mstrd_src_rdy_n) 
                begin
                    if ((PE_state==load_data_b) && bias_ovf) begin
                        wght_addrin<=10'd0;
                    end else begin
                        wght_addrin<=wght_addrin+1'b1;
                    end
                end else begin
                    wght_addrin<=wght_addrin;
                end
            end
            load_wght_cmplt:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=1'b1;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;
                wght_addrin<=wght_addrin;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=fill_step;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
            load_ifmap_req:
            begin
                ifmap_ready<=1'b0;
                wght_ready<=wght_ready;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=2'd0;
                rdydly<=2'd0;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
            load_ifmap_burst:
            begin
                ifmap_ready<=1'b0;
                wght_ready<=wght_ready;
                op_done<=1'b0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                fill_step<=2'd0;
                rdydly<=2'd0;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;

                if (!ip2bus_mstrd_dst_rdy_n && !bus2ip_mstrd_src_rdy_n) 
                begin
                    case (ifmap_order_ovf)
                        3'b001,3'b101: 
                        begin
                            Iridx<={3'd0,padr};
                            Icidx<=Icidx+1'b1;
                            Psplitidx<=Psplitidx;
                        end
                        3'b011:
                        begin
                            Iridx<={3'd0,padr};
                            Icidx<={3'd0,padc};
                            Psplitidx<=Psplitidx+1'b1;
                        end
                        3'b111:
                        begin
                            Iridx<=5'd0;
                            Icidx<=5'd0;
                            Psplitidx<=10'd0;
                        end
                        default: 
                        begin
                            Iridx<=Iridx+1'b1;
                            Icidx<=Icidx;
                            Psplitidx<=Psplitidx;
                        end
                    endcase
                end
                else
                begin
                    Iridx<=Iridx;
                    Icidx<=Icidx;
                    Psplitidx<=Psplitidx;
                end

                // if (psum_split_condense) 
                // begin
                //     slc_iaddrb_ps<=Psplitidx*ifmapRpad;
                //     slc_iaddrb_ic<=Iridx;
                // end 
                // else 
                // begin
                //     slc_iaddrb_ps<=Psplitidx*i2dsize;
                //     slc_iaddrb_ic<=Icidx*ifmapRpad+Iridx;
                // end
                
                slc_iaddrb_ps<=Psplitidx*i2dsize;
                slc_iaddrb_ic<=Icidx*ifmapRpad+Iridx;

                ifmap_addrin<=slc_iaddrb_ps+slc_iaddrb_ic;

            end
            load_ifmap_cmplt:
            begin
                wght_ready<=wght_ready;
                op_done<=1'b0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                fill_step<=2'd0;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;

                ifmap_ready<=rdydly[1];
                rdydly<=rdydly<<1;
                if (padding) 
                    rdydly[0]<=1'b0;
                else 
                    rdydly[0]<=1'b1;

                Iridx<=5'd0;
                Icidx<=5'd0;
                Psplitidx<=10'd0;

                slc_iaddrb_ps<=Psplitidx*i2dsize;
                slc_iaddrb_ic<=Icidx*ifmapRpad+Iridx;

                ifmap_addrin<=slc_iaddrb_ps+slc_iaddrb_ic;
            end
            ifmap_filling_zero:
            begin
                wght_ready<=wght_ready;
                op_done<=1'b0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                rdydly<=rdydly<<1;
                ifmap_ready<=rdydly[1];
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;

                case (fill_step)
                    2'd0: 
                    begin
                        rdydly[0]<=1'b0;
                        case ({Psplitidx==Psplitref,Icidx==padc-1'b1, Iridx==ifmapRpad-1'b1})
                            3'b001,3'b101:
                            begin
                                Iridx<=5'd0;
                                Icidx<=Icidx+1'b1;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end 
                            3'b011:
                            begin
                                Iridx<=5'd0;
                                Icidx<=5'd0;
                                Psplitidx<=Psplitidx+1'b1;
                                fill_step<=fill_step;
                            end
                            3'b111:
                            begin
                                Iridx<=5'd0;
                                Icidx<={3'd0,padc};
                                Psplitidx<=10'd0;
                                fill_step<=2'd1;
                            end
                            default: 
                            begin
                                Iridx<=Iridx+1'b1;
                                Icidx<=Icidx;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end
                        endcase
                    end
                    2'd1:
                    begin
                        rdydly[0]<=1'b0;
                        case ({Psplitidx==Psplitref,Icidx==Icref, Iridx==padr-1'b1})
                            3'b001,3'b101:
                            begin
                                Iridx<=5'd0;
                                Icidx<=Icidx+1'b1;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end 
                            3'b011:
                            begin
                                Iridx<=5'd0;
                                Icidx<={3'd0,padc};
                                Psplitidx<=Psplitidx+1'b1;
                                fill_step<=fill_step;
                            end
                            3'b111:
                            begin
                                Iridx<=ifmapRinner;
                                Icidx<={3'd0,padc};
                                Psplitidx<=10'd0;
                                fill_step<=2'd2;
                            end
                            default: 
                            begin
                                Iridx<=Iridx+1'b1;
                                Icidx<=Icidx;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end
                        endcase
                    end
                    2'd2:
                    begin
                        rdydly[0]<=1'b0;
                        case ({Psplitidx==Psplitref,Icidx==Icref, Iridx==ifmapRpad-1'b1})
                            3'b001,3'b101:
                            begin
                                Iridx<=ifmapRinner;
                                Icidx<=Icidx+1'b1;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end 
                            3'b011:
                            begin
                                Iridx<=ifmapRinner;
                                Icidx<={3'd0,padc};
                                Psplitidx<=Psplitidx+1'b1;
                                fill_step<=fill_step;
                            end
                            3'b111:
                            begin
                                Iridx<=5'd0;
                                Icidx<=ifmapCinner;
                                Psplitidx<=10'd0;
                                fill_step<=2'd3;
                            end
                            default: 
                            begin
                                Iridx<=Iridx+1'b1;
                                Icidx<=Icidx;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                            end
                        endcase
                    end
                    2'd3:
                    begin
                        case ({Psplitidx==Psplitref,Icidx==ifmapCpad-1'b1, Iridx==ifmapRpad-1'b1})
                            3'b001,3'b101:
                            begin
                                Iridx<=5'd0;
                                Icidx<=Icidx+1'b1;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                                rdydly[0]<=1'b0;
                            end 
                            3'b011:
                            begin
                                Iridx<=5'd0;
                                Icidx<=ifmapCinner;
                                Psplitidx<=Psplitidx+1'b1;
                                fill_step<=fill_step;
                                rdydly[0]<=1'b0;
                            end
                            3'b111:
                            begin
                                Iridx<=Iridx;
                                Icidx<=Icidx;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                                rdydly[0]<=1'b1;
                            end
                            default: 
                            begin
                                Iridx<=Iridx+1'b1;
                                Icidx<=Icidx;
                                Psplitidx<=Psplitidx;
                                fill_step<=fill_step;
                                rdydly[0]<=1'b0;
                            end
                        endcase
                    end
                    default: 
                    begin
                        Iridx<=Iridx;
                        Icidx<=Icidx;
                        Psplitidx<=Psplitidx;
                        fill_step<=fill_step;
                        ifmap_ready<=ifmap_ready;
                        rdydly[0]<=rdydly[0];
                    end
                endcase

                slc_iaddrb_ps<=Psplitidx*i2dsize;
                slc_iaddrb_ic<=Icidx*ifmapRpad+Iridx;

                ifmap_addrin<=slc_iaddrb_ps+slc_iaddrb_ic;

            end
            offload_ofmap_req:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=wght_ready;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=2'd0;
                rdydly<=rdydly;
                wr_cache<=1'b1;
                if (wr_cache) 
                begin
                    ofmap_addrin<=ofmap_addrin;
                    burst_cnt<=burst_cnt;
                    write_halt<=1'b1;
                end 
                else 
                begin
                    ofmap_addrin<=ofmap_addrin+1'b1;
                    burst_cnt<=ofmap_addrin;
                    write_halt<=1'b0;
                end
            end
            offload_ofmap_burst:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=wght_ready;
                op_done<=1'b0;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=2'd0;
                rdydly<=rdydly;
                wr_cache<=1'b1;

                if (!ip2bus_mstwr_src_rdy_n && !bus2ip_mstwr_dst_rdy_n) 
                begin
                    ofmap_addrin<=ofmap_addrin+1'b1;
                    burst_cnt<=ofmap_addrin;
                    write_halt<=1'b0;
                end 
                else 
                begin
                    ofmap_addrin<=ofmap_addrin;
                    burst_cnt<=burst_cnt;
                    write_halt<=1'b1;
                end
            end
            offload_ofmap_cmplt:
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=wght_ready;
                op_done<=1'b1;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=2'd0;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
            default: 
            begin
                ifmap_ready<=ifmap_ready;
                wght_ready<=wght_ready;
                op_done<=op_done;
                ifmap_addrin<=10'd0;
                wght_addrin<=10'd0;
                ofmap_addrin<=10'd0;
                Iridx<={3'd0,padr};
                Icidx<={3'd0,padc};
                Psplitidx<=10'd0;
                slc_iaddrb_ps<=10'd0;
                slc_iaddrb_ic<=10'd0;
                fill_step<=2'd0;
                rdydly<=rdydly;
                burst_cnt<=ofmap_addrin;
                write_halt<=1'b0;
                wr_cache<=1'b0;
            end
        endcase
    end
end



endmodule
