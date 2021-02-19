`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/01/11 18:23:29
// Design Name: 
// Module Name: dnn_accelerate_system_tb
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

module dnn_accelerate_system_tb(

    );

	// Inputs & Outputs
    // AXI Full
    reg m00_axi_aclk;
    reg m00_axi_aresetn;
    // AXI4 Master Read Address Channel
    reg m00_axi_arready;
    wire m00_axi_arvalid;
    wire [`C_M_AXI_ADDR_WIDTH-1:0] m00_axi_araddr;
    wire [7:0] m00_axi_arlen;
    wire [2:0] m00_axi_arsize;
    wire [1:0] m00_axi_arburst;
    wire [2:0] m00_axi_arprot;
    wire [3:0] m00_axi_arcache;
    // AXI4 Master Read Data Channel
    wire m00_axi_rready;
    reg m00_axi_rvalid;
    reg [`C_M_AXI_DATA_WIDTH-1:0] m00_axi_rdata;
    reg [1:0] m00_axi_rresp;
    reg m00_axi_rlast;
    // AXI4 Master Write Address Channel
    reg m00_axi_awready;
    wire m00_axi_awvalid;
    wire [`C_M_AXI_ADDR_WIDTH-1:0] m00_axi_awaddr;
    wire [7:0] m00_axi_awlen;
    wire [2:0] m00_axi_awsize;
    wire [1:0] m00_axi_awburst;
    wire [2:0] m00_axi_awprot;
    wire [3:0] m00_axi_awcache;
    // AXI4 Master Write Data Channel
    reg m00_axi_wready;
    wire m00_axi_wvalid;
    wire [`C_M_AXI_DATA_WIDTH-1:0] m00_axi_wdata;
    wire [(`C_M_AXI_DATA_WIDTH/8)-1:0] m00_axi_wstrb;
    wire m00_axi_wlast;
    // AXI4 Master Write Response Channel 
    reg [1:0] m00_axi_bresp;
    reg m00_axi_bvalid;
    wire m00_axi_bready;
    // AXI Lite
    reg s00_axi_aclk;
    reg s00_axi_aresetn;
    // AXI Lite write address channel
    reg [`C_S_AXI_ADDR_WIDTH-1:0] s00_axi_awaddr;
    reg [2:0] s00_axi_awprot;
    reg s00_axi_awvalid;
    wire s00_axi_awready;
    // AXI Lite write data channel
    reg [`C_S_AXI_DATA_WIDTH-1:0] s00_axi_wdata;
    reg [(`C_S_AXI_DATA_WIDTH/8)-1:0] s00_axi_wstrb;
    reg s00_axi_wvalid;
    wire s00_axi_wready;
    // AXI Lite write respond channel
    wire [1:0] s00_axi_bresp;
    wire s00_axi_bvalid;
    reg s00_axi_bready;
    // AXI Lite read address channel
    reg [`C_S_AXI_ADDR_WIDTH-1:0] s00_axi_araddr;
    reg [2:0] s00_axi_arprot;
    reg s00_axi_arvalid;
    wire s00_axi_arready;
    // AXI Lite read data channel
    wire [`C_S_AXI_DATA_WIDTH-1:0] s00_axi_rdata;
    wire [1:0] s00_axi_rresp;
    wire s00_axi_rvalid;
    reg s00_axi_rready;

	// Memory
    reg [63:0] L1_ifmap_bus[0:1023];
    reg [63:0] L1_wght_bus[0:40];
    reg [63:0] L1_ofmap_bus[0:783];
    reg [63:0] L2_ifmap_bus[0:391];
    reg [63:0] L2_wght_bus[0:801];
    reg [63:0] L2_ofmap_bus[0:391];

    reg [7:0] bst_len_list[0:31];

    // Iterator
    integer i,transtotal,bstlenidxassign,bstlenidxcompare;

    // Instantiate the Unit Under Test (UUT)
    dnn_accelerate_system uut ( 
        .m00_axi_aclk(m00_axi_aclk),
        .m00_axi_aresetn(m00_axi_aresetn),
        .m00_axi_arready(m00_axi_arready),
        .m00_axi_arvalid(m00_axi_arvalid),
        .m00_axi_araddr(m00_axi_araddr),
        .m00_axi_arlen(m00_axi_arlen),
        .m00_axi_arsize(m00_axi_arsize),
        .m00_axi_arburst(m00_axi_arburst),
        .m00_axi_arprot(m00_axi_arprot),
        .m00_axi_arcache(m00_axi_arcache),
        .m00_axi_rready(m00_axi_rready),
        .m00_axi_rvalid(m00_axi_rvalid),
        .m00_axi_rdata(m00_axi_rdata),
        .m00_axi_rresp(m00_axi_rresp),
        .m00_axi_rlast(m00_axi_rlast),
        .m00_axi_awready(m00_axi_awready),
        .m00_axi_awvalid(m00_axi_awvalid),
        .m00_axi_awaddr(m00_axi_awaddr),
        .m00_axi_awlen(m00_axi_awlen),
        .m00_axi_awsize(m00_axi_awsize),
        .m00_axi_awburst(m00_axi_awburst),
        .m00_axi_awprot(m00_axi_awprot),
        .m00_axi_awcache(m00_axi_awcache),
        .m00_axi_wready(m00_axi_wready),
        .m00_axi_wvalid(m00_axi_wvalid),
        .m00_axi_wdata(m00_axi_wdata),
        .m00_axi_wstrb(m00_axi_wstrb),
        .m00_axi_wlast(m00_axi_wlast),
        .m00_axi_bresp(m00_axi_bresp),
        .m00_axi_bvalid(m00_axi_bvalid),
        .m00_axi_bready(m00_axi_bready),
        .s00_axi_aclk(s00_axi_aclk),
        .s00_axi_aresetn(s00_axi_aresetn),
        .s00_axi_awaddr(s00_axi_awaddr),
        .s00_axi_awprot(s00_axi_awprot),
        .s00_axi_awvalid(s00_axi_awvalid),
        .s00_axi_awready(s00_axi_awready),
        .s00_axi_wdata(s00_axi_wdata),
        .s00_axi_wstrb(s00_axi_wstrb),
        .s00_axi_wvalid(s00_axi_wvalid),
        .s00_axi_wready(s00_axi_wready),
        .s00_axi_bresp(s00_axi_bresp),
        .s00_axi_bvalid(s00_axi_bvalid),
        .s00_axi_bready(s00_axi_bready),
        .s00_axi_araddr(s00_axi_araddr),
        .s00_axi_arprot(s00_axi_arprot),
        .s00_axi_arvalid(s00_axi_arvalid),
        .s00_axi_arready(s00_axi_arready),
        .s00_axi_rdata(s00_axi_rdata),
        .s00_axi_rresp(s00_axi_rresp),
        .s00_axi_rvalid(s00_axi_rvalid),
        .s00_axi_rready(s00_axi_rready)
    );


	always@(*)
	begin
		#5 m00_axi_aclk<=~m00_axi_aclk; s00_axi_aclk<=~s00_axi_aclk;
	end

    always @(s00_axi_bresp) begin
        if (s00_axi_bresp!=2'b00) 
            $display("AXI Lite Write Failed: resp %b",s00_axi_bresp);    
    end
    

	initial begin
		// Initialize Inputs
        m00_axi_aclk = 1;
        m00_axi_aresetn = 1;
        m00_axi_arready = 0;
        m00_axi_rvalid = 0;
        m00_axi_rdata = 0;
        m00_axi_rresp = 0;
        m00_axi_rlast = 0;
        m00_axi_awready = 0;
        m00_axi_wready = 0;
        m00_axi_bresp = 0;
        m00_axi_bvalid = 0;
        s00_axi_aclk = 1;
        s00_axi_aresetn = 1;
        s00_axi_awaddr = 0;
        s00_axi_awprot = 0;
        s00_axi_awvalid = 0;
        s00_axi_wdata = 0;
        s00_axi_wstrb = 0;
        s00_axi_wvalid = 0;
        s00_axi_bready = 0;
        s00_axi_araddr = 0;
        s00_axi_arprot = 0;
        s00_axi_arvalid = 0;
        s00_axi_rready = 0;

		// Wait 100 ns for global reset to finish
		#100 m00_axi_aresetn=1'b0; s00_axi_aresetn=1'b0;
      	#10.01
		
		// Add stimulus here

        for ( i=0 ; i<32 ; i=i+1) 
        begin
            bst_len_list[i]=8'd0;
        end

        // reset accelerator, data controller, AMB
		#10 m00_axi_aresetn=1'b1; s00_axi_aresetn=1'b1;
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b1, 1'b1, 1'b0, 1'b0, 1'b0}; // axi_rst, rst
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end


/*                                    
LLLLLLLLLLL               1111111   
L:::::::::L              1::::::1   
L:::::::::L             1:::::::1   
LL:::::::LL             111:::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L         LLLLLL   1::::l   
LL:::::::LLLLLLLLL:::::L111::::::111
L::::::::::::::::::::::L1::::::::::1
L::::::::::::::::::::::L1::::::::::1
LLLLLLLLLLLLLLLLLLLLLLLL111111111111

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


        $readmemb("conv1_ifmap_tile0.mem",L1_ifmap_bus);
        $readmemb("conv1_wght_tile0.mem",L1_wght_bus);

        for ( i=0 ; i<784 ; i=i+1) 
        begin
            L1_ofmap_bus[i]=64'd0;
        end

        //===========================
        // Load Config cmd
        //===========================

        // load tile config
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // config_load
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config assignment
        #10 s00_axi_awaddr={2'd3,3'd0}; s00_axi_awvalid=1'b1; 
                        //{null ,biasl,outch,  inch,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={16'd0, 2'd1, 5'd8, 10'd1, 3'd5, 3'd5, 6'd28, 6'd28, 6'd32, 6'd32, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // config_load=0, config_done=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done = 0
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // config_done=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //===========================
        // AXI Lite read weight cmd
        //===========================

        // load weight
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null, mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd41, 13'd0, 1'b0, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load weight command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end


        //======================
        // AXI MSB read weight
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==41)) 
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10 
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready && m00_axi_rvalid) begin
                m00_axi_rdata=L1_wght_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;


        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd3 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd1024, 13'd0, 1'b0, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load ifmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read ifmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==1024) )
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready) begin
                m00_axi_rdata=L1_ifmap_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;

        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd8 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite operation go cmd
        //===========================
        // op_go
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // op_go=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check tile_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[1]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite write ofmap cmd
        //===========================
        // op_go cmd lift
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // op_go=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // offload ofmap cmd
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd784, 13'd0, 1'b1, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // offload ofmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB write ofmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==784))
        begin
            if (m00_axi_awvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_awlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;                
                    
                m00_axi_awready=1'b0;
                m00_axi_wready=1'b1;
            end else begin
                #10 m00_axi_awready=1'b1;
            end

            if (m00_axi_wvalid) begin
                L1_ofmap_bus[transtotal]=m00_axi_wdata;
                if (m00_axi_wlast) 
                    m00_axi_bvalid=1'b1;
                else
                    m00_axi_bvalid=1'b0;

                transtotal=transtotal+1;
            end else begin
                m00_axi_bvalid=1'b0;
            end
        end
        m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0; m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; 

        // check op_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[2]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;


        #10 $writememb("conv1_ofmap_tile0.mem",L1_ofmap_bus);



/*                                    
LLLLLLLLLLL               1111111   
L:::::::::L              1::::::1   
L:::::::::L             1:::::::1   
LL:::::::LL             111:::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::1   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L                  1::::l   
  L:::::L         LLLLLL   1::::l   
LL:::::::LLLLLLLLL:::::L111::::::111
L::::::::::::::::::::::L1::::::::::1
L::::::::::::::::::::::L1::::::::::1
LLLLLLLLLLLLLLLLLLLLLLLL111111111111

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

        $readmemb("conv1_wght_tile1.mem",L1_wght_bus);

        //===========================
        // Load Config cmd
        //===========================

        // load tile config
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // config_load
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // config_load=0, config_done=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done = 0
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // config_done=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //===========================
        // AXI Lite read weight cmd
        //===========================

        // load weight
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null, mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd41, 13'd0, 1'b0, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load weight command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read weight
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==41)) 
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10 
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready && m00_axi_rvalid) begin
                m00_axi_rdata=L1_wght_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;


        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd3 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;
        
        //===========================
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd1024, 13'd0, 1'b0, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load ifmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read ifmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==1024) )
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready) begin
                m00_axi_rdata=L1_ifmap_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;

        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd8 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite operation go cmd
        //===========================
        // op_go
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // op_go=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check tile_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[1]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;


        //===========================
        // AXI Lite write ofmap cmd
        //===========================
        // op_go cmd lift
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // op_go=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // offload ofmap cmd
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd784, 13'd0, 1'b1, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // offload ofmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB write ofmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==784))
        begin
            if (m00_axi_awvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_awlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;                
                    
                m00_axi_awready=1'b0;
                m00_axi_wready=1'b1;
            end else begin
                #10 m00_axi_awready=1'b1;
            end

            if (m00_axi_wvalid) begin
                L1_ofmap_bus[transtotal]=m00_axi_wdata;
                if (m00_axi_wlast) 
                    m00_axi_bvalid=1'b1;
                else
                    m00_axi_bvalid=1'b0;

                transtotal=transtotal+1;
            end else begin
                m00_axi_bvalid=1'b0;
            end
        end
        m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0; m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; 

        // check op_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[2]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        #10 $writememb("conv1_ofmap_tile1.mem",L1_ofmap_bus);




/*      
LLLLLLLLLLL              222222222222222    
L:::::::::L             2:::::::::::::::22  
L:::::::::L             2::::::222222:::::2 
LL:::::::LL             2222222     2:::::2 
  L:::::L                           2:::::2 
  L:::::L                           2:::::2 
  L:::::L                        2222::::2  
  L:::::L                   22222::::::22   
  L:::::L                 22::::::::222     
  L:::::L                2:::::22222        
  L:::::L               2:::::2             
  L:::::L         LLLLLL2:::::2             
LL:::::::LLLLLLLLL:::::L2:::::2       222222
L::::::::::::::::::::::L2::::::2222222:::::2
L::::::::::::::::::::::L2::::::::::::::::::2
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222
                                                                                        
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


        $readmemb("conv2_ifmap_tile0.mem",L2_ifmap_bus);
        $readmemb("conv2_wght_tile0.mem",L2_wght_bus);

        for ( i=0 ; i<392 ; i=i+1) 
        begin
            L2_ofmap_bus[i]=64'd0;
        end

        //===========================
        // Load Config cmd
        //===========================

        // load tile config
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // config_load
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config assignment
        #10 s00_axi_awaddr={2'd3,3'd0}; s00_axi_awvalid=1'b1; 
                        //{null ,biasl,outchn,inchanl,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={16'd0, 2'd2, 5'd16, 10'd16, 3'd5, 3'd5, 6'd14, 6'd14, 6'd14, 6'd14, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // config_load=0, config_done=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done = 0
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // config_done=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //===========================
        // AXI Lite read weight cmd
        //===========================

        // load weight
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd802, 13'd0, 1'b0, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load weight command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end


        //======================
        // AXI MSB read weight
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==802)) 
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10 
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready && m00_axi_rvalid) begin
                m00_axi_rdata=L2_wght_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;


        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd3 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b0, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load ifmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read ifmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==392) )
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready) begin
                m00_axi_rdata=L2_ifmap_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;

        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd8 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite operation go cmd
        //===========================
        // op_go
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // op_go=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check tile_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[1]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite write ofmap cmd
        //===========================
        // op_go cmd lift
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // op_go=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // offload ofmap cmd
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b1, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // offload ofmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB write ofmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==392))
        begin
            if (m00_axi_awvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_awlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;                
                    
                m00_axi_awready=1'b0;
                m00_axi_wready=1'b1;
            end else begin
                #10 m00_axi_awready=1'b1;
            end

            if (m00_axi_wvalid) begin
                L2_ofmap_bus[transtotal]=m00_axi_wdata;
                if (m00_axi_wlast) 
                    m00_axi_bvalid=1'b1;
                else
                    m00_axi_bvalid=1'b0;

                transtotal=transtotal+1;
            end else begin
                m00_axi_bvalid=1'b0;
            end
        end
        m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0; m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; 

        // check op_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[2]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        #10 $writememb("conv2_ofmap_tile0.mem",L2_ofmap_bus);



/*                                                                            
LLLLLLLLLLL              222222222222222    
L:::::::::L             2:::::::::::::::22  
L:::::::::L             2::::::222222:::::2 
LL:::::::LL             2222222     2:::::2 
  L:::::L                           2:::::2 
  L:::::L                           2:::::2 
  L:::::L                        2222::::2  
  L:::::L                   22222::::::22   
  L:::::L                 22::::::::222     
  L:::::L                2:::::22222        
  L:::::L               2:::::2             
  L:::::L         LLLLLL2:::::2             
LL:::::::LLLLLLLLL:::::L2:::::2       222222
L::::::::::::::::::::::L2::::::2222222:::::2
L::::::::::::::::::::::L2::::::::::::::::::2
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222
                                                                                        
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


        $readmemb("conv2_wght_tile1.mem",L2_wght_bus);

        //===========================
        // Load Config cmd
        //===========================

        // load tile config
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // config_load
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // config_load=0, config_done=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done = 0
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // config_done=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //===========================
        // AXI Lite read weight cmd
        //===========================

        // load weight
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd802, 13'd0, 1'b0, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load weight command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end


        //======================
        // AXI MSB read weight
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==802)) 
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10 
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready && m00_axi_rvalid) begin
                m00_axi_rdata=L2_wght_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;


        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd3 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b0, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load ifmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read ifmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==392) )
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready) begin
                m00_axi_rdata=L2_ifmap_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;

        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd8 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite operation go cmd
        //===========================
        // op_go
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // op_go=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check tile_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[1]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite write ofmap cmd
        //===========================
        // op_go cmd lift
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // op_go=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // offload ofmap cmd
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b1, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // offload ofmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB write ofmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==392))
        begin
            if (m00_axi_awvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_awlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;                
                    
                m00_axi_awready=1'b0;
                m00_axi_wready=1'b1;
            end else begin
                #10 m00_axi_awready=1'b1;
            end

            if (m00_axi_wvalid) begin
                L2_ofmap_bus[transtotal]=m00_axi_wdata;
                if (m00_axi_wlast) 
                    m00_axi_bvalid=1'b1;
                else
                    m00_axi_bvalid=1'b0;

                transtotal=transtotal+1;
            end else begin
                m00_axi_bvalid=1'b0;
            end
        end
        m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0; m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; 

        // check op_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[2]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        #10 $writememb("conv2_ofmap_tile1.mem",L2_ofmap_bus);



/*                                                                                    
LLLLLLLLLLL              222222222222222    
L:::::::::L             2:::::::::::::::22  
L:::::::::L             2::::::222222:::::2 
LL:::::::LL             2222222     2:::::2 
  L:::::L                           2:::::2 
  L:::::L                           2:::::2 
  L:::::L                        2222::::2  
  L:::::L                   22222::::::22   
  L:::::L                 22::::::::222     
  L:::::L                2:::::22222        
  L:::::L               2:::::2             
  L:::::L         LLLLLL2:::::2             
LL:::::::LLLLLLLLL:::::L2:::::2       222222
L::::::::::::::::::::::L2::::::2222222:::::2
L::::::::::::::::::::::L2::::::::::::::::::2
LLLLLLLLLLLLLLLLLLLLLLLL22222222222222222222
                                                                                        
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


        $readmemb("conv2_wght_tile2.mem",L2_wght_bus);

        //===========================
        // Load Config cmd
        //===========================

        // load tile config
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b1}; // config_load
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b1, 1'b0}; // config_load=0, config_done=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // config done = 0
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // config_done=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //===========================
        // AXI Lite read weight cmd
        //===========================

        // load weight
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd802, 13'd0, 1'b0, 1'b0, 1'b1};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load weight command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end


        //======================
        // AXI MSB read weight
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==802)) 
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10 
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready && m00_axi_rvalid) begin
                m00_axi_rdata=L2_wght_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;


        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd3 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b0, 1'b1, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // load ifmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB read ifmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==392) )
        begin
            if (m00_axi_arvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_arlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;

                m00_axi_arready=1'b0;
                m00_axi_rvalid=1'b1;
            end else begin
                #10 m00_axi_arready=1'b1;
            end

            if (m00_axi_rready) begin
                m00_axi_rdata=L2_ifmap_bus[transtotal];
                
                if (i==bst_len_list[bstlenidxcompare]) begin
                    m00_axi_rlast=1'b1;
                    i=0;
                    if (bstlenidxcompare==31) 
                        bstlenidxcompare=0;
                    else 
                        bstlenidxcompare=bstlenidxcompare+1;
                end else begin
                    m00_axi_rlast=1'b0;
                    i=i+1;
                end

                transtotal=transtotal+1;
            end else begin
                m00_axi_rlast=1'b0;
            end
        end
        m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0;

        // check FSM comp and data
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[11:8]==4'd8 && s00_axi_rdata[15:12]==4'd0))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite operation go cmd
        //===========================
        // op_go
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b1, 1'b0, 1'b0}; // op_go=1
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check tile_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[1]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        //===========================
        // AXI Lite write ofmap cmd
        //===========================
        // op_go cmd lift
        #10 s00_axi_awaddr={2'd1,3'd0}; s00_axi_awvalid=1'b1; s00_axi_wdata={59'd0, 1'b0, 1'b0, 1'b0, 1'b0, 1'b0}; // op_go=0
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // offload ofmap cmd
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,  mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd392, 13'd0, 1'b1, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        // check AXI4_cmdack
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[3]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        // offload ofmap command lift
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,mstlen, null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b0, 1'b0, 1'b0};
            s00_axi_wvalid=1'b1; s00_axi_wstrb=8'b11111111; s00_axi_bready=1'b1;
        while (s00_axi_awvalid || s00_axi_wvalid) 
        begin
            if (s00_axi_awready && s00_axi_wready) begin
                #10 s00_axi_awvalid=1'b0; s00_axi_wvalid=1'b0;
            end else begin
                #10;
            end
        end
        s00_axi_awaddr={2'd0,3'd0}; s00_axi_wdata=64'd0; s00_axi_wstrb=8'b00000000;
        while (s00_axi_bready) 
        begin
            if (s00_axi_bvalid) 
                #10 s00_axi_bready=1'b0;
        end

        //======================
        // AXI MSB write ofmap
        //======================
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==392))
        begin
            if (m00_axi_awvalid) begin
                bst_len_list[bstlenidxassign]=m00_axi_awlen;
                #10
                if (bstlenidxassign==31)
                    bstlenidxassign=0;
                else
                    bstlenidxassign=bstlenidxassign+1;                
                    
                m00_axi_awready=1'b0;
                m00_axi_wready=1'b1;
            end else begin
                #10 m00_axi_awready=1'b1;
            end

            if (m00_axi_wvalid) begin
                L2_ofmap_bus[transtotal]=m00_axi_wdata;
                if (m00_axi_wlast) 
                    m00_axi_bvalid=1'b1;
                else
                    m00_axi_bvalid=1'b0;

                transtotal=transtotal+1;
            end else begin
                m00_axi_bvalid=1'b0;
            end
        end
        m00_axi_awready = 1'b0; m00_axi_wready = 1'b0; m00_axi_bvalid = 1'b0; m00_axi_arready = 1'b0; m00_axi_rvalid = 1'b0; m00_axi_rdata = 64'd0; m00_axi_rlast = 1'b0; 

        // check op_done
        #10 s00_axi_araddr={2'd0,3'd0}; s00_axi_arvalid=1'b1; s00_axi_rready=1'b1;
        while (!(s00_axi_rvalid && s00_axi_rdata[2]))
        begin
            #10 ;
        end
        s00_axi_arvalid=1'b0; 
        #10 s00_axi_rready=1'b0;

        #10 $writememb("conv2_ofmap_tile2.mem",L2_ofmap_bus);





        #100 $finish;



    end

    
endmodule