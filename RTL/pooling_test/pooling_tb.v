`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/23 15:27:06
// Design Name: 
// Module Name: poolint_tb
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

module pooling_tb (
    
);
    
	// Inputs
    reg clk;
    reg rst;
    reg ifmap_en;
    reg wght_en;
    reg ofmap_en;
    reg config_load;
    reg config_done;
    reg op_go;
    reg ifmap_ready;
    reg wght_ready;
    reg op_done;
    reg bias_write;
    reg [7:0] ifmap_wen;
    reg [7:0] wght_wen;
    reg [9:0] ifmap_addrin;
    reg [9:0] wght_addrin;
    reg [10:0] ofmap_addrin;
    reg [63:0] ifmap_din;
    reg [63:0] wght_din;
    reg psum_split_condense;
    reg maxpooling;
    reg [5:0] ifmapR;
    reg [5:0] ifmapC;
    reg [5:0] ofmapR;
    reg [5:0] ofmapC;
    reg [2:0] kernelR;
    reg [2:0] kernelC;
    reg [9:0] inchannel;
    reg [4:0] outchannel;

	// Outputs
    wire dataload_ready;
    wire tile_done;
    wire [3:0] FSM;
    wire [63:0] ofmap_dout;

	// Memory
    reg [63:0] L1_pool_ifmap_bus[0:783];
    reg [63:0] L1_pool_ofmap_bus[0:195];
    reg [63:0] L2_pool_ifmap_bus[0:391];
    reg [63:0] L2_pool_ofmap_bus[0:97];

    // Iterator
    integer i;

    // Instantiate the Unit Under Test (UUT)
	accelerator_top uut ( 
		.clk(clk), 
		.rst(rst), 
		.ifmap_en(ifmap_en),
        .wght_en(wght_en),
        .ofmap_en(ofmap_en),
        .config_load(config_load),
        .config_done(config_done),
        .op_go(op_go),
        .ifmap_ready(ifmap_ready),
        .wght_ready(wght_ready),
        .op_done(op_done),
        .bias_write(bias_write),
        .ifmap_wen(ifmap_wen),
        .wght_wen(wght_wen),
        .ifmap_addrin(ifmap_addrin),
        .wght_addrin(wght_addrin),
        .ofmap_addrin(ofmap_addrin),
        .ifmap_din(ifmap_din),
        .wght_din(wght_din),
        .psum_split_condense(psum_split_condense),
        .maxpooling(maxpooling),
        .ifmapR(ifmapR),
        .ifmapC(ifmapC),
        .ofmapR(ofmapR),
        .ofmapC(ofmapC),
        .kernelR(kernelR),
        .kernelC(kernelC),
        .inchannel(inchannel),
        .outchannel(outchannel),
        .dataload_ready(dataload_ready),
        .tile_done(tile_done),
        .FSM(FSM),
        .ofmap_dout(ofmap_dout)
    );

	always@(*)
	begin
		#5 clk<=~clk;
	end

	initial begin
		// Initialize Inputs
        clk = 1;
        rst = 0;
        ifmap_en = 0;
        wght_en = 0;
        ofmap_en = 0;
        config_load = 0;
        config_done = 0;
        op_go = 0;
        ifmap_ready = 0;
        wght_ready = 0;
        op_done = 0;
        bias_write = 0;
        ifmap_wen = 0;
        wght_wen = 0;
        ifmap_addrin = 0;
        wght_addrin = 0;
        ofmap_addrin = 0;
        ifmap_din = 0;
        wght_din = 0;
        psum_split_condense = 0;
        maxpooling = 0;
        ifmapR = 0;
        ifmapC = 0;
        ofmapR = 0;
        ofmapC = 0;
        kernelR = 0;
        kernelC = 0;
        inchannel = 0;
        outchannel = 0;

		// Wait 100 ns for global reset to finish
		#100 rst=1'b1; 
      	#10.1
		
		// Add stimulus here
		#10 rst=1'b0; 


/*                                    
LLLLLLLLLLL               1111111        PPPPPPPPPPPPPPPPP                                    lllllll 
L:::::::::L              1::::::1        P::::::::::::::::P                                   l:::::l 
L:::::::::L             1:::::::1        P::::::PPPPPP:::::P                                  l:::::l 
LL:::::::LL             111:::::1        PP:::::P     P:::::P                                 l:::::l 
  L:::::L                  1::::1          P::::P     P:::::P  ooooooooooo      ooooooooooo    l::::l 
  L:::::L                  1::::1          P::::P     P:::::Poo:::::::::::oo  oo:::::::::::oo  l::::l 
  L:::::L                  1::::1          P::::PPPPPP:::::Po:::::::::::::::oo:::::::::::::::o l::::l 
  L:::::L                  1::::l          P:::::::::::::PP o:::::ooooo:::::oo:::::ooooo:::::o l::::l 
  L:::::L                  1::::l          P::::PPPPPPPPP   o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                  1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                  1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L         LLLLLL   1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
LL:::::::LLLLLLLLL:::::L111::::::111     PP::::::PP         o:::::ooooo:::::oo:::::ooooo:::::ol::::::l
L::::::::::::::::::::::L1::::::::::1     P::::::::P         o:::::::::::::::oo:::::::::::::::ol::::::l
L::::::::::::::::::::::L1::::::::::1     P::::::::P          oo:::::::::::oo  oo:::::::::::oo l::::::l
LLLLLLLLLLLLLLLLLLLLLLLL111111111111     PPPPPPPPPP            ooooooooooo      ooooooooooo   llllllll

TTTTTTTTTTTTTTTTTTTTTTT  iiii  lllllll                               000000000     
T:::::::::::::::::::::T i::::i l:::::l                             00:::::::::00   
T:::::::::::::::::::::T  iiii  l:::::l                           00:::::::::::::00 
T:::::TT:::::::TT:::::T        l:::::l                          0:::::::000:::::::0
TTTTTT  T:::::T  TTTTTTiiiiiii  l::::l     eeeeeeeeeeee         0::::::0   0::::::0
        T:::::T        i:::::i  l::::l   ee::::::::::::ee       0:::::0     0:::::0
        T:::::T         i::::i  l::::l  e::::::eeeee:::::ee     0:::::0     0:::::0
        T:::::T         i::::i  l::::l e::::::e     e:::::e     0:::::0 000 0:::::0
        T:::::T         i::::i  l::::l e:::::::eeeee::::::e     0:::::0 000 0:::::0
        T:::::T         i::::i  l::::l e:::::::::::::::::e      0:::::0     0:::::0
        T:::::T         i::::i  l::::l e::::::eeeeeeeeeee       0:::::0     0:::::0
        T:::::T         i::::i  l::::l e:::::::e                0::::::0   0::::::0
      TT:::::::TT      i::::::il::::::le::::::::e               0:::::::000:::::::0
      T:::::::::T      i::::::il::::::l e::::::::eeeeeeee        00:::::::::::::00 
      T:::::::::T      i::::::il::::::l  ee:::::::::::::e          00:::::::::00   
      TTTTTTTTTTT      iiiiiiiillllllll    eeeeeeeeeeeeee            000000000     
*/                                    


        $readmemb("pool1_ifmap_tile0.mem",L1_pool_ifmap_bus);

        for ( i=0 ; i<196 ; i=i+1) 
        begin
            L1_pool_ofmap_bus[i]=64'd0;
        end

        // load tile config
        #10 config_load=1'b1;
        #10 psum_split_condense = 1'b0; maxpooling = 1'b1;
        ifmapR = 6'd28; ifmapC = 6'd28; ofmapR = 6'd14; ofmapC = 6'd14; 
        kernelR = 3'd2; kernelC = 3'd2;
        inchannel = 10'd8; outchannel = 5'd8;

        #10 config_load=1'b0; config_done=1'b1;

        // ifmap write
        #10 config_done=1'b0;        
        for (i = 0; i< 784; i=i+1) 
        begin
            #10 ifmap_en=1'b1; ifmap_wen=8'b11111111; ifmap_addrin=i; ifmap_din=L1_pool_ifmap_bus[i];
        end

        #10 ifmap_ready=1'b1; ifmap_en=1'b0; ifmap_wen=8'd0; ifmap_addrin=10'd0; ifmap_din=64'd0;
        
        while (!dataload_ready) 
        begin
            #10 ;
        end

        #10 ifmap_ready=1'b0;
        #10 op_go=1'b1;
        
        while (!tile_done) 
        begin
            #10 ;
        end

        #10 op_go=1'b0; 

        #10 ofmap_en=1'b1; ofmap_addrin=11'd0;
        #10 ofmap_addrin=11'd1;
        for (i = 2; i< 196; i=i+1)
        begin
            #10 ofmap_addrin=i; L1_pool_ofmap_bus[i-2]=ofmap_dout;
        end
        #10 L1_pool_ofmap_bus[194]=ofmap_dout;
        #10 L1_pool_ofmap_bus[195]=ofmap_dout;
        #10 ofmap_en=1'b0; ofmap_addrin=11'd0;

        #10 op_done=1'b1;

        #10 $writememb("pool1_ofmap_tile0.mem",L1_pool_ofmap_bus);

        #10 op_done=1'b0;



/*                                    
LLLLLLLLLLL               1111111        PPPPPPPPPPPPPPPPP                                    lllllll 
L:::::::::L              1::::::1        P::::::::::::::::P                                   l:::::l 
L:::::::::L             1:::::::1        P::::::PPPPPP:::::P                                  l:::::l 
LL:::::::LL             111:::::1        PP:::::P     P:::::P                                 l:::::l 
  L:::::L                  1::::1          P::::P     P:::::P  ooooooooooo      ooooooooooo    l::::l 
  L:::::L                  1::::1          P::::P     P:::::Poo:::::::::::oo  oo:::::::::::oo  l::::l 
  L:::::L                  1::::1          P::::PPPPPP:::::Po:::::::::::::::oo:::::::::::::::o l::::l 
  L:::::L                  1::::l          P:::::::::::::PP o:::::ooooo:::::oo:::::ooooo:::::o l::::l 
  L:::::L                  1::::l          P::::PPPPPPPPP   o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                  1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                  1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L         LLLLLL   1::::l          P::::P           o::::o     o::::oo::::o     o::::o l::::l 
LL:::::::LLLLLLLLL:::::L111::::::111     PP::::::PP         o:::::ooooo:::::oo:::::ooooo:::::ol::::::l
L::::::::::::::::::::::L1::::::::::1     P::::::::P         o:::::::::::::::oo:::::::::::::::ol::::::l
L::::::::::::::::::::::L1::::::::::1     P::::::::P          oo:::::::::::oo  oo:::::::::::oo l::::::l
LLLLLLLLLLLLLLLLLLLLLLLL111111111111     PPPPPPPPPP            ooooooooooo      ooooooooooo   llllllll

TTTTTTTTTTTTTTTTTTTTTTT  iiii  lllllll                            1111111   
T:::::::::::::::::::::T i::::i l:::::l                           1::::::1   
T:::::::::::::::::::::T  iiii  l:::::l                          1:::::::1   
T:::::TT:::::::TT:::::T        l:::::l                          111:::::1   
TTTTTT  T:::::T  TTTTTTiiiiiii  l::::l     eeeeeeeeeeee            1::::1   
        T:::::T        i:::::i  l::::l   ee::::::::::::ee          1::::1   
        T:::::T         i::::i  l::::l  e::::::eeeee:::::ee        1::::1   
        T:::::T         i::::i  l::::l e::::::e     e:::::e        1::::l   
        T:::::T         i::::i  l::::l e:::::::eeeee::::::e        1::::l   
        T:::::T         i::::i  l::::l e:::::::::::::::::e         1::::l   
        T:::::T         i::::i  l::::l e::::::eeeeeeeeeee          1::::l   
        T:::::T         i::::i  l::::l e:::::::e                   1::::l   
      TT:::::::TT      i::::::il::::::le::::::::e               111::::::111
      T:::::::::T      i::::::il::::::l e::::::::eeeeeeee       1::::::::::1
      T:::::::::T      i::::::il::::::l  ee:::::::::::::e       1::::::::::1
      TTTTTTTTTTT      iiiiiiiillllllll    eeeeeeeeeeeeee       111111111111
*/

        $readmemb("pool1_ifmap_tile1.mem",L1_pool_ifmap_bus);

        // load tile config
        #10 config_load=1'b1;
        #10 ;
        #10 config_load=1'b0; config_done=1'b1;

        // ifmap write
        #10 config_done=1'b0; 
        
        for (i = 0; i< 784; i=i+1) 
        begin
            #10 ifmap_en=1'b1; ifmap_wen=8'b11111111; ifmap_addrin=i; ifmap_din=L1_pool_ifmap_bus[i];
        end

        #10 ifmap_ready=1'b1; ifmap_en=1'b0; ifmap_wen=8'd0; ifmap_addrin=10'd0; ifmap_din=64'd0;
        
        while (!dataload_ready) 
        begin
            #10 ;
        end

        #10 ifmap_ready=1'b0; 
        #10 op_go=1'b1;
        
        while (!tile_done) 
        begin
            #10 ;
        end

        #10 op_go=1'b0; 

        #10 ofmap_en=1'b1; ofmap_addrin=11'd0;
        #10 ofmap_addrin=11'd1;
        for (i = 2; i< 196; i=i+1)
        begin
            #10 ofmap_addrin=i; L1_pool_ofmap_bus[i-2]=ofmap_dout;
        end
        #10 L1_pool_ofmap_bus[194]=ofmap_dout;
        #10 L1_pool_ofmap_bus[195]=ofmap_dout;
        #10 ofmap_en=1'b0; ofmap_addrin=11'd0;

        #10 op_done=1'b1;

        #10 $writememb("pool1_ofmap_tile1.mem",L1_pool_ofmap_bus);

        #10 op_done=1'b0;



/*      
LLLLLLLLLLL              222222222222222         PPPPPPPPPPPPPPPPP                                    lllllll 
L:::::::::L             2:::::::::::::::22       P::::::::::::::::P                                   l:::::l 
L:::::::::L             2::::::222222:::::2      P::::::PPPPPP:::::P                                  l:::::l 
LL:::::::LL             2222222     2:::::2      PP:::::P     P:::::P                                 l:::::l 
  L:::::L                           2:::::2        P::::P     P:::::P  ooooooooooo      ooooooooooo    l::::l 
  L:::::L                           2:::::2        P::::P     P:::::Poo:::::::::::oo  oo:::::::::::oo  l::::l 
  L:::::L                        2222::::2         P::::PPPPPP:::::Po:::::::::::::::oo:::::::::::::::o l::::l 
  L:::::L                   22222::::::22          P:::::::::::::PP o:::::ooooo:::::oo:::::ooooo:::::o l::::l 
  L:::::L                 22::::::::222            P::::PPPPPPPPP   o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                2:::::22222               P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L               2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L         LLLLLL2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
LL:::::::LLLLLLLLL:::::L2:::::2       222222     PP::::::PP         o:::::ooooo:::::oo:::::ooooo:::::ol::::::l
L::::::::::::::::::::::L2::::::2222222:::::2     P::::::::P         o:::::::::::::::oo:::::::::::::::ol::::::l
L::::::::::::::::::::::L2::::::::::::::::::2     P::::::::P          oo:::::::::::oo  oo:::::::::::oo l::::::l
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222     PPPPPPPPPP            ooooooooooo      ooooooooooo   llllllll

TTTTTTTTTTTTTTTTTTTTTTT  iiii  lllllll                               000000000     
T:::::::::::::::::::::T i::::i l:::::l                             00:::::::::00   
T:::::::::::::::::::::T  iiii  l:::::l                           00:::::::::::::00 
T:::::TT:::::::TT:::::T        l:::::l                          0:::::::000:::::::0
TTTTTT  T:::::T  TTTTTTiiiiiii  l::::l     eeeeeeeeeeee         0::::::0   0::::::0
        T:::::T        i:::::i  l::::l   ee::::::::::::ee       0:::::0     0:::::0
        T:::::T         i::::i  l::::l  e::::::eeeee:::::ee     0:::::0     0:::::0
        T:::::T         i::::i  l::::l e::::::e     e:::::e     0:::::0 000 0:::::0
        T:::::T         i::::i  l::::l e:::::::eeeee::::::e     0:::::0 000 0:::::0
        T:::::T         i::::i  l::::l e:::::::::::::::::e      0:::::0     0:::::0
        T:::::T         i::::i  l::::l e::::::eeeeeeeeeee       0:::::0     0:::::0
        T:::::T         i::::i  l::::l e:::::::e                0::::::0   0::::::0
      TT:::::::TT      i::::::il::::::le::::::::e               0:::::::000:::::::0
      T:::::::::T      i::::::il::::::l e::::::::eeeeeeee        00:::::::::::::00 
      T:::::::::T      i::::::il::::::l  ee:::::::::::::e          00:::::::::00   
      TTTTTTTTTTT      iiiiiiiillllllll    eeeeeeeeeeeeee            000000000     
*/                                                                                   


        $readmemb("pool2_ifmap_tile0.mem",L2_pool_ifmap_bus);

        for ( i=0 ; i<98 ; i=i+1) 
        begin
            L2_pool_ofmap_bus[i]=64'd0;
        end

        // load tile config
        #10 config_load=1'b1;
        #10 psum_split_condense = 1'b0;
        ifmapR = 6'd14; ifmapC = 6'd14; ofmapR = 6'd7; ofmapC = 6'd7; 
        kernelR = 3'd2; kernelC = 3'd2;
        inchannel = 10'd16; outchannel = 5'd16;

        #10 config_load=1'b0; config_done=1'b1;

        // ifmap write
        #10 config_done=1'b0; 
        
        for (i = 0; i< 392; i=i+1) 
        begin
            #10 ifmap_en=1'b1; ifmap_wen=8'b11111111; ifmap_addrin=i; ifmap_din=L2_pool_ifmap_bus[i];
        end

        #10 ifmap_ready=1'b1; ifmap_en=1'b0; ifmap_wen=8'd0; ifmap_addrin=10'd0; ifmap_din=64'd0;
        
        while (!dataload_ready) 
        begin
            #10 ;
        end

        #10 ifmap_ready=1'b0;
        #10 op_go=1'b1;
        
        while (!tile_done) 
        begin
            #10 ;
        end

        #10 op_go=1'b0; 

        #10 ofmap_en=1'b1; ofmap_addrin=11'd0;
        #10 ofmap_addrin=11'd1;
        for (i = 2; i< 98; i=i+1)
        begin
            #10 ofmap_addrin=i; L2_pool_ofmap_bus[i-2]=ofmap_dout;
        end
        #10 L2_pool_ofmap_bus[96]=ofmap_dout;
        #10 L2_pool_ofmap_bus[97]=ofmap_dout;
        #10 ofmap_en=1'b0; ofmap_addrin=11'd0;

        #10 op_done=1'b1;

        #10 $writememb("pool2_ofmap_tile0.mem",L2_pool_ofmap_bus);

        #10 op_done=1'b0;


/*                                                                            
LLLLLLLLLLL              222222222222222         PPPPPPPPPPPPPPPPP                                    lllllll 
L:::::::::L             2:::::::::::::::22       P::::::::::::::::P                                   l:::::l 
L:::::::::L             2::::::222222:::::2      P::::::PPPPPP:::::P                                  l:::::l 
LL:::::::LL             2222222     2:::::2      PP:::::P     P:::::P                                 l:::::l 
  L:::::L                           2:::::2        P::::P     P:::::P  ooooooooooo      ooooooooooo    l::::l 
  L:::::L                           2:::::2        P::::P     P:::::Poo:::::::::::oo  oo:::::::::::oo  l::::l 
  L:::::L                        2222::::2         P::::PPPPPP:::::Po:::::::::::::::oo:::::::::::::::o l::::l 
  L:::::L                   22222::::::22          P:::::::::::::PP o:::::ooooo:::::oo:::::ooooo:::::o l::::l 
  L:::::L                 22::::::::222            P::::PPPPPPPPP   o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                2:::::22222               P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L               2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L         LLLLLL2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
LL:::::::LLLLLLLLL:::::L2:::::2       222222     PP::::::PP         o:::::ooooo:::::oo:::::ooooo:::::ol::::::l
L::::::::::::::::::::::L2::::::2222222:::::2     P::::::::P         o:::::::::::::::oo:::::::::::::::ol::::::l
L::::::::::::::::::::::L2::::::::::::::::::2     P::::::::P          oo:::::::::::oo  oo:::::::::::oo l::::::l
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222     PPPPPPPPPP            ooooooooooo      ooooooooooo   llllllll
                                                                                        
TTTTTTTTTTTTTTTTTTTTTTT  iiii  lllllll                            1111111   
T:::::::::::::::::::::T i::::i l:::::l                           1::::::1   
T:::::::::::::::::::::T  iiii  l:::::l                          1:::::::1   
T:::::TT:::::::TT:::::T        l:::::l                          111:::::1   
TTTTTT  T:::::T  TTTTTTiiiiiii  l::::l     eeeeeeeeeeee            1::::1   
        T:::::T        i:::::i  l::::l   ee::::::::::::ee          1::::1   
        T:::::T         i::::i  l::::l  e::::::eeeee:::::ee        1::::1   
        T:::::T         i::::i  l::::l e::::::e     e:::::e        1::::l   
        T:::::T         i::::i  l::::l e:::::::eeeee::::::e        1::::l   
        T:::::T         i::::i  l::::l e:::::::::::::::::e         1::::l   
        T:::::T         i::::i  l::::l e::::::eeeeeeeeeee          1::::l   
        T:::::T         i::::i  l::::l e:::::::e                   1::::l   
      TT:::::::TT      i::::::il::::::le::::::::e               111::::::111
      T:::::::::T      i::::::il::::::l e::::::::eeeeeeee       1::::::::::1
      T:::::::::T      i::::::il::::::l  ee:::::::::::::e       1::::::::::1
      TTTTTTTTTTT      iiiiiiiillllllll    eeeeeeeeeeeeee       111111111111
*/                                                                            


        $readmemb("pool2_ifmap_tile1.mem",L2_pool_ifmap_bus);

        // load tile config
        #10 config_load=1'b1;
        #10 ;
        #10 config_load=1'b0; config_done=1'b1;

        // ifmap write
        #10 config_done=1'b0; 
        
        for (i = 0; i< 392; i=i+1) 
        begin
            #10 ifmap_en=1'b1; ifmap_wen=8'b11111111; ifmap_addrin=i; ifmap_din=L2_pool_ifmap_bus[i];
        end

        #10 ifmap_ready=1'b1; ifmap_en=1'b0; ifmap_wen=8'd0; ifmap_addrin=10'd0; ifmap_din=64'd0;
        
        while (!dataload_ready) 
        begin
            #10 ;
        end

        #10 ifmap_ready=1'b0;
        #10 op_go=1'b1;
        
        while (!tile_done) 
        begin
            #10 ;
        end

        #10 op_go=1'b0; 

        #10 ofmap_en=1'b1; ofmap_addrin=11'd0;
        #10 ofmap_addrin=11'd1;
        for (i = 2; i< 98; i=i+1)
        begin
            #10 ofmap_addrin=i; L2_pool_ofmap_bus[i-2]=ofmap_dout;
        end
        #10 L2_pool_ofmap_bus[96]=ofmap_dout;
        #10 L2_pool_ofmap_bus[97]=ofmap_dout;
        #10 ofmap_en=1'b0; ofmap_addrin=11'd0;

        #10 op_done=1'b1;

        #10 $writememb("pool2_ofmap_tile1.mem",L2_pool_ofmap_bus);

        #10 op_done=1'b0;



/*                                                                                    
LLLLLLLLLLL              222222222222222         PPPPPPPPPPPPPPPPP                                    lllllll 
L:::::::::L             2:::::::::::::::22       P::::::::::::::::P                                   l:::::l 
L:::::::::L             2::::::222222:::::2      P::::::PPPPPP:::::P                                  l:::::l 
LL:::::::LL             2222222     2:::::2      PP:::::P     P:::::P                                 l:::::l 
  L:::::L                           2:::::2        P::::P     P:::::P  ooooooooooo      ooooooooooo    l::::l 
  L:::::L                           2:::::2        P::::P     P:::::Poo:::::::::::oo  oo:::::::::::oo  l::::l 
  L:::::L                        2222::::2         P::::PPPPPP:::::Po:::::::::::::::oo:::::::::::::::o l::::l 
  L:::::L                   22222::::::22          P:::::::::::::PP o:::::ooooo:::::oo:::::ooooo:::::o l::::l 
  L:::::L                 22::::::::222            P::::PPPPPPPPP   o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L                2:::::22222               P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L               2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
  L:::::L         LLLLLL2:::::2                    P::::P           o::::o     o::::oo::::o     o::::o l::::l 
LL:::::::LLLLLLLLL:::::L2:::::2       222222     PP::::::PP         o:::::ooooo:::::oo:::::ooooo:::::ol::::::l
L::::::::::::::::::::::L2::::::2222222:::::2     P::::::::P         o:::::::::::::::oo:::::::::::::::ol::::::l
L::::::::::::::::::::::L2::::::::::::::::::2     P::::::::P          oo:::::::::::oo  oo:::::::::::oo l::::::l
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222     PPPPPPPPPP            ooooooooooo      ooooooooooo   llllllll
                                                                                        
TTTTTTTTTTTTTTTTTTTTTTT  iiii  lllllll                           222222222222222    
T:::::::::::::::::::::T i::::i l:::::l                          2:::::::::::::::22  
T:::::::::::::::::::::T  iiii  l:::::l                          2::::::222222:::::2 
T:::::TT:::::::TT:::::T        l:::::l                          2222222     2:::::2 
TTTTTT  T:::::T  TTTTTTiiiiiii  l::::l     eeeeeeeeeeee                     2:::::2 
        T:::::T        i:::::i  l::::l   ee::::::::::::ee                   2:::::2 
        T:::::T         i::::i  l::::l  e::::::eeeee:::::ee              2222::::2  
        T:::::T         i::::i  l::::l e::::::e     e:::::e         22222::::::22   
        T:::::T         i::::i  l::::l e:::::::eeeee::::::e       22::::::::222     
        T:::::T         i::::i  l::::l e:::::::::::::::::e       2:::::22222        
        T:::::T         i::::i  l::::l e::::::eeeeeeeeeee       2:::::2             
        T:::::T         i::::i  l::::l e:::::::e                2:::::2             
      TT:::::::TT      i::::::il::::::le::::::::e               2:::::2       222222
      T:::::::::T      i::::::il::::::l e::::::::eeeeeeee       2::::::2222222:::::2
      T:::::::::T      i::::::il::::::l  ee:::::::::::::e       2::::::::::::::::::2
      TTTTTTTTTTT      iiiiiiiillllllll    eeeeeeeeeeeeee       22222222222222222222
*/                                                                                    


        $readmemb("pool2_ifmap_tile2.mem",L2_pool_ifmap_bus);

        // load tile config
        #10 config_load=1'b1;
        #10 ;
        #10 config_load=1'b0; config_done=1'b1;

        // ifmap write
        #10 config_done=1'b0; 
        
        for (i = 0; i< 392; i=i+1) 
        begin
            #10 ifmap_en=1'b1; ifmap_wen=8'b11111111; ifmap_addrin=i; ifmap_din=L2_pool_ifmap_bus[i];
        end

        #10 ifmap_ready=1'b1; ifmap_en=1'b0; ifmap_wen=8'd0; ifmap_addrin=10'd0; ifmap_din=64'd0;
        
        while (!dataload_ready) 
        begin
            #10 ;
        end

        #10 ifmap_ready=1'b0;
        #10 op_go=1'b1;
        
        while (!tile_done) 
        begin
            #10 ;
        end

        #10 op_go=1'b0; 

        #10 ofmap_en=1'b1; ofmap_addrin=11'd0;
        #10 ofmap_addrin=11'd1;
        for (i = 2; i< 98; i=i+1)
        begin
            #10 ofmap_addrin=i; L2_pool_ofmap_bus[i-2]=ofmap_dout;
        end
        #10 L2_pool_ofmap_bus[96]=ofmap_dout;
        #10 L2_pool_ofmap_bus[97]=ofmap_dout;
        #10 ofmap_en=1'b0; ofmap_addrin=11'd0;

        #10 op_done=1'b1;

        #10 $writememb("pool2_ofmap_tile2.mem",L2_pool_ofmap_bus);

        #10 op_done=1'b0;


        #100 $finish;






    end

endmodule
