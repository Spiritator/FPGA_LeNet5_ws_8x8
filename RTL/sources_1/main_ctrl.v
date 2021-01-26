`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/27 18:33:20
// Design Name: 
// Module Name: main_ctrl
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


module main_ctrl(clk, rst, config_load, config_done, ifmap_ready, wght_ready, op_go, op_done, bias_write,
                 psum_split_condense, maxpooling, ifmapR, ifmapC, ofmapR, ofmapC, kernelR, kernelC, inchannel, outchannel,
                 load_wght, data_ready, sum_in_bias, tile_done, current_state,
                 ofmap_en, ofmap_addrin,
                 ifmap_en_b, wght_en_b, ofmap_en_a, ofmap_en_b, bias_en_a, bias_en_b,
                 bias_addr_b, ifmap_addr_b, wght_addr_b, ofmap_addr_a, ofmap_addr_b,
                 ifmap_wen_b, wght_wen_b, ofmap_wen_a, ofmap_wen_b, bias_wen_a, bias_wen_b);

parameter wd=8;
parameter idle=4'd0, load_tile_config=4'd1, load_data_b=4'd2, load_data=4'd3, PE_shift_wght=4'd4, slice_check=4'd5, MAC_op=4'd6, offload_ofmap=4'd7, ready_go=4'd8, pooling=4'd9;


input clk,rst, config_load, config_done, ifmap_ready, wght_ready, op_go, op_done, bias_write;
// tile config
input psum_split_condense,maxpooling;
input [5:0] ifmapR,ifmapC,ofmapR,ofmapC;
input [2:0] kernelR,kernelC;
input [9:0] inchannel;
input [4:0] outchannel;

output load_wght,data_ready,sum_in_bias,tile_done;
reg load_wght,data_ready,tile_done;
output [3:0] current_state;
reg [3:0] current_state, next_state;

reg ifmap_loaded, wght_loaded, bias_loaded, wght_shift_done, check_done;
wire slice_done,ofmap_write;
reg [1:0] substate_slccheck;
reg [2:0] Kridx,Kcidx;
reg [5:0] Oridx,Ocidx;
reg [9:0] Psplitidx;
reg [1:0] Ochidx;
wire [9:0] n_psum_slices,npslccon,npslcinch;
wire [1:0] outchsplit;
wire [5:0] Orref,Ocref;
wire [2:0] Krref,Kcref;
wire [1:0] Ochref,ofmap_order_ovf;
wire [9:0] Psplitref;
wire [3:0] slice_order_ovf;
reg [9:0] slc_ifmap_addr_base,slc_ifmap_addr_mv,slc_iaddrb_ps,slc_iaddrb_kc;
wire [9:0] slc_ofmap_addr_sumin;
reg [9:0] slc_ofmap_addr_base,slc_ofmap_addr_mv;
reg [9:0] slc_wght_addr_base,slc_waddrb_out,slc_waddrb_kc,slc_waddrb_kr;
reg [2:0] slc_wght_addr_mv;

reg [9:0] i2dsize,krichsize,k2dichsize;
reg [9:0] o2dsize;

reg poolwrite;
wire [4:0] pool_order_ovf;

// BRAM ctrl & IO
input ofmap_en;
input [9:0] ofmap_addrin;
output ifmap_en_b,wght_en_b,ofmap_en_a,ofmap_en_b,bias_en_a,bias_en_b;
reg ifmap_en_b,wght_en_b,ofmap_en_a,ofmap_en_b,bias_en_a,bias_en_b;
output bias_addr_b;
output [9:0] ifmap_addr_b;
output [9:0] wght_addr_b;
output [9:0] ofmap_addr_a,ofmap_addr_b;
output [7:0] ifmap_wen_b,wght_wen_b,bias_wen_a,bias_wen_b;
reg [7:0] ifmap_wen_b,wght_wen_b,bias_wen_a,bias_wen_b;
output [15:0] ofmap_wen_a,ofmap_wen_b;
reg [15:0] ofmap_wen_a,ofmap_wen_b;

// ofmap buffer addr delay
reg [9:0] ofbufD0,ofbufD1,ofbufD2,ofbufD3,ofbufD4,ofbufD5,ofbufD6,ofbufD7,ofbufD8,ofbufD9,ofbufDa,ofbufDb,ofbufDc,ofbufDd,ofbufDe,ofbufDf,ofbufDg,ofbufDh;
reg [17:0] ofbufshift_wen,ofbufshift_done;

// tile config calculation
//                                                           ffffffffffffffff    iiii                      
//                                                          f::::::::::::::::f  i::::i                     
//                                                         f::::::::::::::::::f  iiii                      
//                                                         f::::::fffffff:::::f                            
//     cccccccccccccccc   ooooooooooo   nnnn  nnnnnnnn     f:::::f       ffffffiiiiiii    ggggggggg   ggggg
//   cc:::::::::::::::c oo:::::::::::oo n:::nn::::::::nn   f:::::f             i:::::i   g:::::::::ggg::::g
//  c:::::::::::::::::co:::::::::::::::on::::::::::::::nn f:::::::ffffff        i::::i  g:::::::::::::::::g
// c:::::::cccccc:::::co:::::ooooo:::::onn:::::::::::::::nf::::::::::::f        i::::i g::::::ggggg::::::gg
// c::::::c     ccccccco::::o     o::::o  n:::::nnnn:::::nf::::::::::::f        i::::i g:::::g     g:::::g 
// c:::::c             o::::o     o::::o  n::::n    n::::nf:::::::ffffff        i::::i g:::::g     g:::::g 
// c:::::c             o::::o     o::::o  n::::n    n::::n f:::::f              i::::i g:::::g     g:::::g 
// c::::::c     ccccccco::::o     o::::o  n::::n    n::::n f:::::f              i::::i g::::::g    g:::::g 
// c:::::::cccccc:::::co:::::ooooo:::::o  n::::n    n::::nf:::::::f            i::::::ig:::::::ggggg:::::g 
//  c:::::::::::::::::co:::::::::::::::o  n::::n    n::::nf:::::::f            i::::::i g::::::::::::::::g 
//   cc:::::::::::::::c oo:::::::::::oo   n::::n    n::::nf:::::::f            i::::::i  gg::::::::::::::g 
//     cccccccccccccccc   ooooooooooo     nnnnnn    nnnnnnfffffffff            iiiiiiii    gggggggg::::::g 
//                                                                                                 g:::::g 
//                                                                                     gggggg      g:::::g 
//                                                                                     g:::::gg   gg:::::g 
//                                                                                      g::::::ggg:::::::g 
//                                                                                       gg:::::::::::::g  
//                                                                                         ggg::::::ggg    
//                                                                                            gggggg       

assign npslccon={7'd0,kernelC};
assign npslcinch={3'd0, inchannel[9:3] + ( |inchannel[2:0] ) };
assign n_psum_slices=psum_split_condense ? npslccon : npslcinch;
assign outchsplit=outchannel[4:3] + ( |outchannel[2:0] );
assign Orref=ofmapR-1'b1;
assign Ocref=ofmapC-1'b1;
assign Krref=kernelR-1'b1;
assign Kcref=kernelC-1'b1;
assign Ochref=outchsplit-1'b1;
assign Psplitref=n_psum_slices-1'b1;
assign slice_order_ovf={Ochidx==Ochref, Kcidx==Kcref, Kridx==Krref, Psplitidx==Psplitref};
assign ofmap_order_ovf={Ocidx==Ocref, Oridx==Orref};
assign pool_order_ovf={ofmap_order_ovf,slice_order_ovf[0],slice_order_ovf[2:1]};

assign sum_in_bias= ~((|Kcidx) | (|Kridx) | (|Psplitidx));
assign ifmap_addr_b=slc_ifmap_addr_base+slc_ifmap_addr_mv;
assign wght_addr_b=slc_wght_addr_base+slc_wght_addr_mv;
assign bias_addr_b=Ochidx[0];
assign slc_ofmap_addr_sumin=slc_ofmap_addr_base+slc_ofmap_addr_mv;
assign ofmap_addr_a = ofmap_en ? ofmap_addrin : slc_ofmap_addr_sumin;
assign ofmap_addr_b = maxpooling ? ofbufD0 : ofbufDh;

assign ofmap_write=ofbufshift_wen[17];
assign slice_done=ofbufshift_done[17];

// address gen pipline
always @(posedge clk) 
begin
    o2dsize<=ofmapR*ofmapC;
    i2dsize<=ifmapR*ifmapC;
    krichsize<=kernelR*n_psum_slices;
    k2dichsize<=krichsize*kernelC;
end


// FFFFFFFFFFFFFFFFFFFFFF   SSSSSSSSSSSSSSS MMMMMMMM               MMMMMMMM
// F::::::::::::::::::::F SS:::::::::::::::SM:::::::M             M:::::::M
// F::::::::::::::::::::FS:::::SSSSSS::::::SM::::::::M           M::::::::M
// FF::::::FFFFFFFFF::::FS:::::S     SSSSSSSM:::::::::M         M:::::::::M
//   F:::::F       FFFFFFS:::::S            M::::::::::M       M::::::::::M
//   F:::::F             S:::::S            M:::::::::::M     M:::::::::::M
//   F::::::FFFFFFFFFF    S::::SSSS         M:::::::M::::M   M::::M:::::::M
//   F:::::::::::::::F     SS::::::SSSSS    M::::::M M::::M M::::M M::::::M
//   F:::::::::::::::F       SSS::::::::SS  M::::::M  M::::M::::M  M::::::M
//   F::::::FFFFFFFFFF          SSSSSS::::S M::::::M   M:::::::M   M::::::M
//   F:::::F                         S:::::SM::::::M    M:::::M    M::::::M
//   F:::::F                         S:::::SM::::::M     MMMMM     M::::::M
// FF:::::::FF           SSSSSSS     S:::::SM::::::M               M::::::M
// F::::::::FF           S::::::SSSSSS:::::SM::::::M               M::::::M
// F::::::::FF           S:::::::::::::::SS M::::::M               M::::::M
// FFFFFFFFFFF            SSSSSSSSSSSSSSS   MMMMMMMM               MMMMMMMM
                                                                        
always @(posedge clk or posedge rst) 
begin
    if (rst) 
        current_state <= idle; 
    else 
        current_state <= next_state; 
end

always @(current_state or config_load or config_done or bias_write or data_ready or op_go or tile_done or check_done or wght_shift_done or slice_done or op_done or maxpooling) 
begin
    case (current_state)
        idle: 
        begin
            if (config_load) 
                next_state=load_tile_config;
            else 
                next_state=idle;
        end
        load_tile_config:
        begin
            if (config_done) 
            begin
                if (maxpooling) 
                    next_state=load_data; 
                else
                    next_state=load_data_b; 
            end
            else 
                next_state=load_tile_config;
        end
        load_data_b:
        begin
            if (bias_write) 
                next_state=load_data_b;
            else 
                next_state=load_data;
        end
        load_data:
        begin
            if (data_ready) 
                next_state=ready_go;
            else 
                next_state=load_data;
        end
        ready_go:
        begin
            if (op_go) 
                next_state=slice_check;
            else
                next_state=ready_go;
        end
        slice_check:
        begin
            if (tile_done) 
                next_state=offload_ofmap;
            else 
            begin
                if (maxpooling) 
                    next_state=pooling;
                else 
                begin
                    if (check_done) 
                        next_state=PE_shift_wght;
                    else 
                        next_state=slice_check;
                end
            end
        end
        PE_shift_wght:
        begin
            if (wght_shift_done) 
                next_state=MAC_op;
            else 
                next_state=PE_shift_wght;
        end
        MAC_op:
        begin
            if (slice_done) 
                next_state=slice_check;
            else 
                next_state=MAC_op;
        end
        offload_ofmap:
        begin
            if (op_done) 
                next_state=idle;
            else 
                next_state=offload_ofmap;
        end
        pooling:
        begin
            if (tile_done) 
                next_state=offload_ofmap;
            else
                next_state=pooling;
        end
        default: 
            next_state=idle;
    endcase
end

// combinational output
//                                                             bbbbbbbb                                                                                                                                                  
//                                                             b::::::b              iiii                                             tttt            iiii                                                       lllllll 
//                                                             b::::::b             i::::i                                         ttt:::t           i::::i                                                      l:::::l 
//                                                             b::::::b              iiii                                          t:::::t            iiii                                                       l:::::l 
//                                                              b:::::b                                                            t:::::t                                                                       l:::::l 
//     cccccccccccccccc   ooooooooooo      mmmmmmm    mmmmmmm   b:::::bbbbbbbbb    iiiiiiinnnn  nnnnnnnn      aaaaaaaaaaaaa  ttttttt:::::ttttttt    iiiiiii    ooooooooooo   nnnn  nnnnnnnn      aaaaaaaaaaaaa    l::::l 
//   cc:::::::::::::::c oo:::::::::::oo  mm:::::::m  m:::::::mm b::::::::::::::bb  i:::::in:::nn::::::::nn    a::::::::::::a t:::::::::::::::::t    i:::::i  oo:::::::::::oo n:::nn::::::::nn    a::::::::::::a   l::::l 
//  c:::::::::::::::::co:::::::::::::::om::::::::::mm::::::::::mb::::::::::::::::b  i::::in::::::::::::::nn   aaaaaaaaa:::::at:::::::::::::::::t     i::::i o:::::::::::::::on::::::::::::::nn   aaaaaaaaa:::::a  l::::l 
// c:::::::cccccc:::::co:::::ooooo:::::om::::::::::::::::::::::mb:::::bbbbb:::::::b i::::inn:::::::::::::::n           a::::atttttt:::::::tttttt     i::::i o:::::ooooo:::::onn:::::::::::::::n           a::::a  l::::l 
// c::::::c     ccccccco::::o     o::::om:::::mmm::::::mmm:::::mb:::::b    b::::::b i::::i  n:::::nnnn:::::n    aaaaaaa:::::a      t:::::t           i::::i o::::o     o::::o  n:::::nnnn:::::n    aaaaaaa:::::a  l::::l 
// c:::::c             o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b i::::i  n::::n    n::::n  aa::::::::::::a      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n  aa::::::::::::a  l::::l 
// c:::::c             o::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b i::::i  n::::n    n::::n a::::aaaa::::::a      t:::::t           i::::i o::::o     o::::o  n::::n    n::::n a::::aaaa::::::a  l::::l 
// c::::::c     ccccccco::::o     o::::om::::m   m::::m   m::::mb:::::b     b:::::b i::::i  n::::n    n::::na::::a    a:::::a      t:::::t    tttttt i::::i o::::o     o::::o  n::::n    n::::na::::a    a:::::a  l::::l 
// c:::::::cccccc:::::co:::::ooooo:::::om::::m   m::::m   m::::mb:::::bbbbbb::::::bi::::::i n::::n    n::::na::::a    a:::::a      t::::::tttt:::::ti::::::io:::::ooooo:::::o  n::::n    n::::na::::a    a:::::a l::::::l
//  c:::::::::::::::::co:::::::::::::::om::::m   m::::m   m::::mb::::::::::::::::b i::::::i n::::n    n::::na:::::aaaa::::::a      tt::::::::::::::ti::::::io:::::::::::::::o  n::::n    n::::na:::::aaaa::::::a l::::::l
//   cc:::::::::::::::c oo:::::::::::oo m::::m   m::::m   m::::mb:::::::::::::::b  i::::::i n::::n    n::::n a::::::::::aa:::a       tt:::::::::::tti::::::i oo:::::::::::oo   n::::n    n::::n a::::::::::aa:::al::::::l
//     cccccccccccccccc   ooooooooooo   mmmmmm   mmmmmm   mmmmmmbbbbbbbbbbbbbbbb   iiiiiiii nnnnnn    nnnnnn  aaaaaaaaaa  aaaa         ttttttttttt  iiiiiiii   ooooooooooo     nnnnnn    nnnnnn  aaaaaaaaaa  aaaallllllll

always @(current_state or ofmap_write or sum_in_bias or ofmap_en or poolwrite) 
begin
    ifmap_wen_b={8{1'b0}};
    wght_wen_b={8{1'b0}};
    bias_wen_b={8{1'b0}};
    ofmap_wen_a={16{1'b0}};

    case (current_state)
        idle: 
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        load_tile_config:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};

        end
        load_data_b:
        begin
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
            bias_en_a=1'b1;
            bias_wen_a={8{1'b1}};
        end
        load_data:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        ready_go:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        slice_check:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        PE_shift_wght:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b1;
            wght_en_b=1'b1;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        MAC_op:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            ifmap_en_b=1'b1;
            ofmap_en_b=1'b1;
            ofmap_wen_b={16{ofmap_write}};
            if (sum_in_bias) 
            begin
                bias_en_b=1'b1;
                ofmap_en_a=1'b0;
            end 
            else 
            begin
                bias_en_b=1'b0;
                ofmap_en_a=1'b1;
            end
        end
        offload_ofmap:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b0;
            ofmap_en_a=ofmap_en;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
        pooling:
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b1;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b1;
            ofmap_wen_b={16{poolwrite}};
        end
        default: 
        begin
            bias_en_a=1'b0;
            bias_wen_a={8{1'b0}};
            load_wght=1'b0;
            wght_en_b=1'b0;
            bias_en_b=1'b0;
            ifmap_en_b=1'b1;
            ofmap_en_a=1'b0;
            ofmap_en_b=1'b0;
            ofmap_wen_b={16{1'b0}};
        end
            
    endcase
end

// sequential output
//                                                                                                                           tttt            iiii                    lllllll 
//                                                                                                                        ttt:::t           i::::i                   l:::::l 
//                                                                                                                        t:::::t            iiii                    l:::::l 
//                                                                                                                        t:::::t                                    l:::::l 
//     ssssssssss       eeeeeeeeeeee       qqqqqqqqq   qqqqquuuuuu    uuuuuu      eeeeeeeeeeee    nnnn  nnnnnnnn    ttttttt:::::ttttttt    iiiiiii   aaaaaaaaaaaaa    l::::l 
//   ss::::::::::s    ee::::::::::::ee    q:::::::::qqq::::qu::::u    u::::u    ee::::::::::::ee  n:::nn::::::::nn  t:::::::::::::::::t    i:::::i   a::::::::::::a   l::::l 
// ss:::::::::::::s  e::::::eeeee:::::ee q:::::::::::::::::qu::::u    u::::u   e::::::eeeee:::::een::::::::::::::nn t:::::::::::::::::t     i::::i   aaaaaaaaa:::::a  l::::l 
// s::::::ssss:::::se::::::e     e:::::eq::::::qqqqq::::::qqu::::u    u::::u  e::::::e     e:::::enn:::::::::::::::ntttttt:::::::tttttt     i::::i            a::::a  l::::l 
//  s:::::s  ssssss e:::::::eeeee::::::eq:::::q     q:::::q u::::u    u::::u  e:::::::eeeee::::::e  n:::::nnnn:::::n      t:::::t           i::::i     aaaaaaa:::::a  l::::l 
//    s::::::s      e:::::::::::::::::e q:::::q     q:::::q u::::u    u::::u  e:::::::::::::::::e   n::::n    n::::n      t:::::t           i::::i   aa::::::::::::a  l::::l 
//       s::::::s   e::::::eeeeeeeeeee  q:::::q     q:::::q u::::u    u::::u  e::::::eeeeeeeeeee    n::::n    n::::n      t:::::t           i::::i  a::::aaaa::::::a  l::::l 
// ssssss   s:::::s e:::::::e           q::::::q    q:::::q u:::::uuuu:::::u  e:::::::e             n::::n    n::::n      t:::::t    tttttt i::::i a::::a    a:::::a  l::::l 
// s:::::ssss::::::se::::::::e          q:::::::qqqqq:::::q u:::::::::::::::uue::::::::e            n::::n    n::::n      t::::::tttt:::::ti::::::ia::::a    a:::::a l::::::l
// s::::::::::::::s  e::::::::eeeeeeee   q::::::::::::::::q  u:::::::::::::::u e::::::::eeeeeeee    n::::n    n::::n      tt::::::::::::::ti::::::ia:::::aaaa::::::a l::::::l
//  s:::::::::::ss    ee:::::::::::::e    qq::::::::::::::q   uu::::::::uu:::u  ee:::::::::::::e    n::::n    n::::n        tt:::::::::::tti::::::i a::::::::::aa:::al::::::l
//   sssssssssss        eeeeeeeeeeeeee      qqqqqqqq::::::q     uuuuuuuu  uuuu    eeeeeeeeeeeeee    nnnnnn    nnnnnn          ttttttttttt  iiiiiiii  aaaaaaaaaa  aaaallllllll
//                                                  q:::::q                                                                                                                  
//                                                  q:::::q                                                                                                                  
//                                                 q:::::::q                                                                                                                 
//                                                 q:::::::q                                                                                                                 
//                                                 q:::::::q                                                                                                                 
//                                                 qqqqqqqqq                                                                                                                 

always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        ifmap_loaded<=1'b0;
        wght_loaded<=1'b0;
        bias_loaded<=1'b0;
        data_ready<=1'b0;
        Kridx<=3'd0;
        Kcidx<=3'd0;
        Oridx<=5'd0;
        Ocidx<=5'd0;
        Psplitidx<=10'd0;
        Ochidx<=1'b0;
        tile_done<=1'b0;
        check_done<=1'b0;
        substate_slccheck<=2'd0;
        slc_iaddrb_ps<=10'd0;
        slc_iaddrb_kc<=10'd0;
        slc_waddrb_out<=10'd0;
        slc_waddrb_kc<=10'd0;
        slc_waddrb_kr<=10'd0;
        slc_ifmap_addr_base<=10'd0;
        slc_ofmap_addr_base<=10'd0;
        slc_wght_addr_base<=10'd0;
        slc_ifmap_addr_mv<=10'd0;
        slc_ofmap_addr_mv<=10'd0;
        slc_wght_addr_mv<=3'd0;
        wght_shift_done<=1'b0;
        ofbufshift_done<=18'd0;
        ofbufshift_wen<=18'd0;
        poolwrite<=1'b0;
    end 
    else 
    begin
    case (current_state)
        idle: 
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=3'd0;
            Kcidx<=3'd0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            Psplitidx<=10'd0;
            Ochidx<=1'b0;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=10'd0;
            slc_iaddrb_kc<=10'd0;
            slc_waddrb_out<=10'd0;
            slc_waddrb_kc<=10'd0;
            slc_waddrb_kr<=10'd0;
            slc_ifmap_addr_base<=10'd0;
            slc_ofmap_addr_base<=10'd0;
            slc_wght_addr_base<=10'd0;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=16'd0;
            ofbufshift_wen<=16'd0;
            poolwrite<=1'b0;
        end
        load_tile_config:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=3'd0;
            Kcidx<=3'd0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            Psplitidx<=10'd0;
            Ochidx<=1'b0;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            poolwrite<=1'b0;
        end
        load_data_b:
        begin
            if (ifmap_ready) 
                ifmap_loaded<=1'b1;
            else 
                ifmap_loaded<=ifmap_loaded;
            if (wght_ready) 
                wght_loaded<=1'b1;
            else 
                wght_loaded<=wght_loaded;
            if (!bias_write) 
                bias_loaded<=1'b1;
            else 
                bias_loaded<=bias_loaded;
            data_ready<=1'b0;
            Kridx<=3'd0;
            Kcidx<=3'd0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            Psplitidx<=10'd0;
            Ochidx<=1'b0;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            poolwrite<=1'b0;
        end
        load_data:
        begin
            if (ifmap_ready) 
                ifmap_loaded<=1'b1;
            else 
                ifmap_loaded<=ifmap_loaded;
            if (wght_ready) 
                wght_loaded<=1'b1;
            else 
                wght_loaded<=wght_loaded;
            if (!bias_write) 
                bias_loaded<=1'b1;
            else 
                bias_loaded<=bias_loaded;

            if (maxpooling) begin
                if (ifmap_loaded)
                    data_ready<=1'b1;
                else
                    data_ready<=data_ready;
            end else begin
                if (bias_loaded && ifmap_loaded && wght_loaded)
                    data_ready<=1'b1;
                else
                    data_ready<=data_ready;
            end
            
            Kridx<=3'd0;
            Kcidx<=3'd0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            Psplitidx<=10'd0;
            Ochidx<=1'b0;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            poolwrite<=1'b0;
        end
        ready_go:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b1;
            Kridx<=3'd0;
            Kcidx<=3'd0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            Ochidx<=1'b0;
            Psplitidx<=-10'd1;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            poolwrite<=1'b0;
        end
        slice_check:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Oridx<=5'd0;
            Ocidx<=5'd0;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            poolwrite<=1'b1;

            substate_slccheck<=substate_slccheck+1'b1;

            case (substate_slccheck)
                2'd0: 
                begin
                    check_done<=1'b0;

                    slc_ifmap_addr_base<=slc_ifmap_addr_base;
                    slc_ofmap_addr_base<=slc_ofmap_addr_base;
                    slc_wght_addr_base<=slc_wght_addr_base;
                    slc_iaddrb_ps<=slc_iaddrb_ps;
                    slc_iaddrb_kc<=slc_iaddrb_kc;
                    slc_waddrb_out<=slc_waddrb_out;
                    slc_waddrb_kc<=slc_waddrb_kc;
                    slc_waddrb_kr<=slc_waddrb_kr;


                    if (psum_split_condense) 
                    begin
                        Kcidx<=3'd0;
                        Kridx<=3'd0;
                        case ({slice_order_ovf[3],slice_order_ovf[0]})
                            2'b01: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx+1'b1; 
                                Psplitidx<=10'd0;
                            end
                            2'b11: 
                            begin
                                tile_done<=1'b1;
                                Ochidx<=2'd0; 
                                Psplitidx<=10'd0;
                            end
                            default: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx; 
                                Psplitidx<=Psplitidx+1'b1;
                            end
                        endcase
                    end 
                    else // !psum_split_condense
                    begin
                        case (slice_order_ovf)
                            4'b0001,4'b0101,4'b1001,4'b1101: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx; 
                                Kcidx<=Kcidx;
                                Kridx<=Kridx+1'b1;
                                Psplitidx<=10'd0;
                            end
                            4'b0011,4'b1011: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx; 
                                Kcidx<=Kcidx+1'b1;
                                Kridx<=3'd0;
                                Psplitidx<=10'd0;
                            end
                            4'b0111: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx+1'b1; 
                                Kcidx<=3'd0;
                                Kridx<=3'd0;
                                Psplitidx<=10'd0;
                            end
                            4'b1111: 
                            begin
                                tile_done<=1'b1;
                                Ochidx<=2'd0; 
                                Kcidx<=3'd0;
                                Kridx<=3'd0;
                                Psplitidx<=10'd0;
                            end
                            default: 
                            begin
                                tile_done<=tile_done;
                                Ochidx<=Ochidx; 
                                Kcidx<=Kcidx;
                                Kridx<=Kridx;
                                Psplitidx<=Psplitidx+1'b1;
                            end
                        endcase
                    end
                end
                2'd1: // substate_slccheck
                begin
                    check_done<=1'b0;

                    tile_done<=tile_done;
                    Ochidx<=Ochidx; 
                    Kcidx<=Kcidx;
                    Kridx<=Kridx;
                    Psplitidx<=Psplitidx;

                    slc_ofmap_addr_base<=Ochidx*o2dsize;
                    slc_ifmap_addr_base<=slc_ifmap_addr_base;
                    slc_wght_addr_base<=slc_wght_addr_base;

                    if (psum_split_condense) 
                    begin
                        slc_iaddrb_ps<=Psplitidx*ifmapR;
                        slc_iaddrb_kc<=10'd0;
                        slc_waddrb_out<=Ochidx*n_psum_slices; 
                        slc_waddrb_kc<=10'd0;
                        slc_waddrb_kr<=10'd0; 
                    end 
                    else 
                    begin
                        slc_iaddrb_ps<=Psplitidx*i2dsize;
                        slc_iaddrb_kc<=Kcidx*ifmapR+Kridx;
                        slc_waddrb_out<=Ochidx*k2dichsize;
                        slc_waddrb_kc<=Kcidx*krichsize;
                        slc_waddrb_kr<=Kridx*n_psum_slices; 
                        
                    end
                end
                2'd2: // substate_slccheck
                begin
                    check_done<=1'b1;

                    tile_done<=tile_done;
                    Ochidx<=Ochidx; 
                    Kcidx<=Kcidx;
                    Kridx<=Kridx;
                    Psplitidx<=Psplitidx;

                    slc_ofmap_addr_base<=slc_ofmap_addr_base;
                    slc_iaddrb_ps<=slc_iaddrb_ps;
                    slc_iaddrb_kc<=slc_iaddrb_kc;
                    slc_waddrb_out<=slc_waddrb_out;
                    slc_waddrb_kc<=slc_waddrb_kc;
                    slc_waddrb_kr<=slc_waddrb_kr;

                    if (psum_split_condense) 
                    begin
                        slc_ifmap_addr_base<=slc_iaddrb_ps;
                        slc_wght_addr_base<=(slc_waddrb_out+Psplitidx)<<3; 
                    end 
                    else 
                    begin
                        slc_ifmap_addr_base<=slc_iaddrb_kc+slc_iaddrb_ps;
                        slc_wght_addr_base<=(slc_waddrb_out+slc_waddrb_kc+slc_waddrb_kr+Psplitidx)<<3; 
                    end
                end
                default: 
                begin
                    check_done<=check_done;
                    tile_done<=tile_done;
                    Ochidx<=Ochidx; 
                    Kcidx<=Kcidx;
                    Kridx<=Kridx;
                    Psplitidx<=Psplitidx;
                    slc_ofmap_addr_base<=slc_ofmap_addr_base;
                    slc_ifmap_addr_base<=slc_ifmap_addr_base;
                    slc_wght_addr_base<=slc_wght_addr_base;
                    slc_iaddrb_ps<=slc_iaddrb_ps;
                    slc_iaddrb_kc<=slc_iaddrb_kc;
                    slc_waddrb_out<=slc_waddrb_out;
                    slc_waddrb_kc<=slc_waddrb_kc;
                    slc_waddrb_kr<=slc_waddrb_kr;
                end
            endcase
        end
        PE_shift_wght:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=Kridx;
            Kcidx<=Kcidx;
            Oridx<=Oridx;
            Ocidx<=Ocidx;
            Psplitidx<=Psplitidx;
            Ochidx<=Ochidx;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_ofmap_addr_mv<=10'd0;
            poolwrite<=1'b0;
            
            if (slc_wght_addr_mv==3'd7) 
            begin
                slc_wght_addr_mv<=3'd0;
                wght_shift_done<=1'b1;
            end 
            else 
            begin
                slc_wght_addr_mv<=slc_wght_addr_mv+1'b1;
                wght_shift_done<=1'b0;
            end
        end
        MAC_op:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=Kridx;
            Kcidx<=Kcidx;
            Psplitidx<=Psplitidx;
            Ochidx<=Ochidx;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            poolwrite<=1'b0;

            ofbufshift_done<=ofbufshift_done<<1;
            ofbufshift_wen<=ofbufshift_wen<<1;
            ofbufshift_wen[0]<=1'b1;

            case (ofmap_order_ovf)
                2'b01: 
                begin
                    ofbufshift_done[0]<=ofbufshift_done[0];
                    Ocidx<=Ocidx+1'b1;
                    Oridx<=5'd0;
                end
                2'b11:
                begin
                    ofbufshift_done[0]<=1'b1;
                    Ocidx<=Ocidx;
                    Oridx<=Oridx;
                end
                default: 
                begin
                    ofbufshift_done[0]<=ofbufshift_done[0];
                    Ocidx<=Ocidx;
                    Oridx<=Oridx+1'b1;
                end
            endcase

            slc_ifmap_addr_mv<=Ocidx*ifmapR+Oridx;
            slc_ofmap_addr_mv<=Ocidx*ofmapR+Oridx;


        end
        offload_ofmap:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=Kridx;
            Kcidx<=Kcidx;
            Psplitidx<=Psplitidx;
            tile_done<=1'b1;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            slc_ofmap_addr_mv<=10'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            Ochidx<=2'd0;
            Ocidx<=5'd0;
            Oridx<=5'd0;
            poolwrite<=1'b0;
        end
        pooling:
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_wght_addr_mv<=3'd0;
            wght_shift_done<=1'b0;
            Ochidx<=2'd0;

            ofbufshift_done<=ofbufshift_done<<1;
            ofbufshift_wen<=ofbufshift_wen<<1;
            tile_done<=ofbufshift_done[1];
            poolwrite<=ofbufshift_wen[1];

            case (pool_order_ovf)
                5'b00001,5'b00101,5'b01001,5'b01101,5'b10001,5'b10101,5'b11001,5'b11101: 
                begin
                    Ocidx<=Ocidx;
                    Oridx<=Oridx;
                    Psplitidx<=Psplitidx;
                    Kcidx<=Kcidx+1'b1;
                    Kridx<=3'd0;
                    ofbufshift_done[0]<=1'b0;
                    ofbufshift_wen[0]<=1'b0;
                end
                5'b00011,5'b01011,5'b10011,5'b11011:
                begin
                    Ocidx<=Ocidx;
                    Oridx<=Oridx;
                    Psplitidx<=Psplitidx+1'b1;
                    Kcidx<=3'd0;
                    Kridx<=3'd0;
                    ofbufshift_done[0]<=1'b0;
                    ofbufshift_wen[0]<=1'b1;
                end
                5'b00111,5'b10111: 
                begin
                    Ocidx<=Ocidx;
                    Oridx<=Oridx+1'b1;
                    Psplitidx<=10'd0;
                    Kcidx<=3'd0;
                    Kridx<=3'd0;
                    ofbufshift_done[0]<=1'b0;
                    ofbufshift_wen[0]<=1'b1;
                end
                5'b01111: 
                begin
                    Ocidx<=Ocidx+1'b1;
                    Oridx<=5'd0;
                    Psplitidx<=10'd0;
                    Kcidx<=3'd0;
                    Kridx<=3'd0;
                    ofbufshift_done[0]<=1'b0;
                    ofbufshift_wen[0]<=1'b1;
                end
                5'b11111: 
                begin
                    Ocidx<=Ocidx;
                    Oridx<=Oridx;
                    Psplitidx<=Psplitidx;
                    Kcidx<=Kcidx;
                    Kridx<=Kridx;
                    ofbufshift_done[0]<=1'b1;
                    ofbufshift_wen[0]<=1'b1;
                end
                default: 
                begin
                    Ocidx<=Ocidx;
                    Oridx<=Oridx;
                    Psplitidx<=Psplitidx;
                    Kcidx<=Kcidx;
                    Kridx<=Kridx+1'b1;
                    ofbufshift_done[0]<=1'b0;
                    ofbufshift_wen[0]<=1'b0;
                end
            endcase

            // wegiht temporal reg borrowed
            slc_iaddrb_ps<=Psplitidx*i2dsize;
            slc_iaddrb_kc<={Ocidx[3:0],1'b0}*ifmapR+{Oridx[3:0],1'b0};
            slc_ifmap_addr_base<=slc_iaddrb_ps+slc_iaddrb_kc;

            slc_waddrb_out<=Kcidx*ifmapR+Kridx; // tmp slc_ifmap_addr_mv
            slc_waddrb_kc<=Psplitidx[1:0]*o2dsize; // tmp slc_ofmap_addr_base
            slc_waddrb_kr<=Ocidx*ofmapR+Oridx; // tmp slc_ofmap_addr_mv

            slc_ifmap_addr_mv<=slc_waddrb_out;
            slc_ofmap_addr_base<=slc_waddrb_kc;
            slc_ofmap_addr_mv<=slc_waddrb_kr;

        end
        default: 
        begin
            ifmap_loaded<=1'b0;
            wght_loaded<=1'b0;
            bias_loaded<=1'b0;
            data_ready<=1'b0;
            Kridx<=Kridx;
            Kcidx<=Kcidx;
            Psplitidx<=Psplitidx;
            tile_done<=1'b0;
            check_done<=1'b0;
            substate_slccheck<=2'd0;
            slc_iaddrb_ps<=slc_iaddrb_ps;
            slc_iaddrb_kc<=slc_iaddrb_kc;
            slc_waddrb_out<=slc_waddrb_out;
            slc_waddrb_kc<=slc_waddrb_kc;
            slc_waddrb_kr<=slc_waddrb_kr;
            slc_ifmap_addr_base<=slc_ifmap_addr_base;
            slc_ofmap_addr_base<=slc_ofmap_addr_base;
            slc_wght_addr_base<=slc_wght_addr_base;
            slc_ifmap_addr_mv<=10'd0;
            slc_wght_addr_mv<=3'd0;
            slc_ofmap_addr_mv<=10'd0;
            wght_shift_done<=1'b0;
            ofbufshift_done<=18'd0;
            ofbufshift_wen<=18'd0;
            Ochidx<=2'd0;
            Ocidx<=5'd0;
            Oridx<=5'd0;
            poolwrite<=1'b0;
        end        
    endcase
    end
end


// shift reg ofmap write add
always @(posedge clk or posedge rst) 
begin
    if (rst) 
    begin
        ofbufD0<=10'd0;
        ofbufD1<=10'd0;
        ofbufD2<=10'd0;
        ofbufD3<=10'd0;
        ofbufD4<=10'd0;
        ofbufD5<=10'd0;
        ofbufD6<=10'd0;
        ofbufD7<=10'd0;
        ofbufD8<=10'd0;
        ofbufD9<=10'd0;
        ofbufDa<=10'd0;
        ofbufDb<=10'd0;
        ofbufDc<=10'd0;
        ofbufDe<=10'd0;
        ofbufDf<=10'd0;
        ofbufDg<=10'd0;
        ofbufDh<=10'd0;
    end 
    else 
    begin
        ofbufD0<=ofmap_addr_a;
        ofbufD1<=ofbufD0;
        ofbufD2<=ofbufD1;
        ofbufD3<=ofbufD2;
        ofbufD4<=ofbufD3;
        ofbufD5<=ofbufD4;
        ofbufD6<=ofbufD5;
        ofbufD7<=ofbufD6;
        ofbufD8<=ofbufD7;
        ofbufD9<=ofbufD8;
        ofbufDa<=ofbufD9;
        ofbufDb<=ofbufDa;
        ofbufDc<=ofbufDb;
        ofbufDe<=ofbufDc;
        ofbufDf<=ofbufDe;
        ofbufDg<=ofbufDf;
        ofbufDh<=ofbufDg;
    end
end

endmodule
