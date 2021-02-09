`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/02/03 13:50:41
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
    reg [63:0] input_pic_bus[0:1023];
    reg [63:0] L1_wght_bus[0:81];
    reg [63:0] L1_ofmap_bus[0:1567];
    reg [63:0] L2_ifmap_bus[0:391];
    reg [63:0] L2_wght_bus[0:2405];
    reg [63:0] L2_ofmap_bus[0:1175];
    reg [63:0] FC1_ifmap_bus[0:293];
    reg [63:0] FC1_wght_bus[0:31376];
    reg [63:0] FC1_ofmap_bus[0:16];
    reg [63:0] FC2_wght_bus[0:257];
    reg [63:0] FC2_ofmap_bus[0:1];

    reg [7:0] bst_len_list[0:31];

    // Iterator
    integer i, transtotal, bstlenidxassign, bstlenidxcompare;
    integer offset, fc1_ochidx;

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


        $readmemh("input_pic.mem",input_pic_bus);
        $readmemh("conv1_wght.mem",L1_wght_bus);

        for ( i=0 ; i<1568 ; i=i+1) 
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
                        //{null ,tlls,tlfr,relu,mpool,biasl,outch,  inch,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={11'd0,1'b1,1'b1,1'b1, 1'b0, 2'd1, 5'd8, 10'd1, 3'd5, 3'd5, 6'd28, 6'd28, 6'd32, 6'd32, 1'b0, 1'b1};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L1_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=input_pic_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                L1_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=41;
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
                m00_axi_rdata=L1_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=input_pic_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=784;
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
                L1_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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

        for ( i=0 ; i<392 ; i=i+1) 
        begin
            L2_ifmap_bus[i]=64'd0;
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
                        //{null ,tlls,tlfr,relu,mpool,biasl,outch,  inch,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={11'd0,1'b1,1'b1,1'b0, 1'b1, 2'd0, 5'd8, 10'd8, 3'd2, 3'd2, 6'd14, 6'd14, 6'd28, 6'd28, 1'b0, 1'b0};
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
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd784, 13'd0, 1'b0, 1'b1, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==784) )
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
                m00_axi_rdata=L1_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
            s00_axi_wdata={32'h00010000, 5'd0, 11'd196, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==196))
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
                L2_ifmap_bus[transtotal+offset]=m00_axi_wdata;
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
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd784, 13'd0, 1'b0, 1'b1, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=784;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==784) )
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
                m00_axi_rdata=L1_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
            s00_axi_wdata={32'h00010000, 5'd0, 11'd196, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=196;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==196))
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
                L2_ifmap_bus[transtotal+offset]=m00_axi_wdata;
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


        $readmemh("conv2_wght.mem",L2_wght_bus);

        for ( i=0 ; i<1176 ; i=i+1) 
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
                        //{null ,tlls,tlfr,relu,mpool,biasl,outchn,inchanl,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={11'd0,1'b1,1'b1,1'b1, 1'b0, 2'd2, 5'd16, 10'd16, 3'd5, 3'd5, 6'd14, 6'd14, 6'd14, 6'd14, 1'b1, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L2_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L2_ifmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                L2_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=802;
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
                m00_axi_rdata=L2_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L2_ifmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=392;
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
                L2_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=1604;
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
                m00_axi_rdata=L2_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L2_ifmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=784;
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
                L2_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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


        for ( i=0 ; i<294 ; i=i+1) 
        begin
            FC1_ifmap_bus[i]=64'd0;
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
                        //{null ,tlls,tlfr,relu,mpool,biasl,outch,  inch,krnlC,krnlR,ofmapC,ofmapR,ifmapC,ifmapR, pad ,psum_split_condense}
            s00_axi_wdata={11'd0,1'b1,1'b1,1'b0, 1'b1, 2'd0,5'd16,10'd16, 3'd2, 3'd2, 6'd7 , 6'd7 , 6'd14, 6'd14, 1'b0, 1'b0};
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
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
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
                m00_axi_rdata=L2_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
                        //{   ctrl_addr, null, mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd98, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==98))
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
                FC1_ifmap_bus[transtotal+offset]=m00_axi_wdata;
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
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=392;
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
                m00_axi_rdata=L2_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
                        //{   ctrl_addr, null, mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd98, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=98;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==98))
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
                FC1_ifmap_bus[transtotal+offset]=m00_axi_wdata;
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
        // AXI Lite read ifmap cmd
        //===========================

        // load ifmap
        #10 s00_axi_awaddr={2'd2,3'd0}; s00_axi_awvalid=1'b1; 
                        //{   ctrl_addr, null,   mstlen,  null,ofmol,ifmld,wgtld}
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=784;
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
                m00_axi_rdata=L2_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
                        //{   ctrl_addr, null, mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd98, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=196;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==98))
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
                FC1_ifmap_bus[transtotal+offset]=m00_axi_wdata;
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

        $writememh("fc1_ifmap.mem",FC1_ifmap_bus);


/*
FFFFFFFFFFFFFFFFFFFFFF       CCCCCCCCCCCCC       1111111               
F::::::::::::::::::::F    CCC::::::::::::C      1::::::1               
F::::::::::::::::::::F  CC:::::::::::::::C     1:::::::1               
FF::::::FFFFFFFFF::::F C:::::CCCCCCCC::::C     111:::::1               
  F:::::F       FFFFFFC:::::C       CCCCCC        1::::1               
  F:::::F            C:::::C                      1::::1               
  F::::::FFFFFFFFFF  C:::::C                      1::::1               
  F:::::::::::::::F  C:::::C                      1::::l               
  F:::::::::::::::F  C:::::C                      1::::l               
  F::::::FFFFFFFFFF  C:::::C                      1::::l               
  F:::::F            C:::::C                      1::::l               
  F:::::F             C:::::C       CCCCCC        1::::l               
FF:::::::FF            C:::::CCCCCCCC::::C     111::::::111            
F::::::::FF             CC:::::::::::::::C     1::::::::::1            
F::::::::FF               CCC::::::::::::C     1::::::::::1            
FFFFFFFFFFF                  CCCCCCCCCCCCC     111111111111            

IIIIIIIIII       tttt                                                  
I::::::::I    ttt:::t                                                  
I::::::::I    t:::::t                                                  
II::::::II    t:::::t                                                  
  I::::Ittttttt:::::ttttttt        eeeeeeeeeeee    rrrrr   rrrrrrrrr   
  I::::It:::::::::::::::::t      ee::::::::::::ee  r::::rrr:::::::::r  
  I::::It:::::::::::::::::t     e::::::eeeee:::::eer:::::::::::::::::r 
  I::::Itttttt:::::::tttttt    e::::::e     e:::::err::::::rrrrr::::::r
  I::::I      t:::::t          e:::::::eeeee::::::e r:::::r     r:::::r
  I::::I      t:::::t          e:::::::::::::::::e  r:::::r     rrrrrrr
  I::::I      t:::::t          e::::::eeeeeeeeeee   r:::::r            
  I::::I      t:::::t    tttttte:::::::e            r:::::r            
II::::::II    t::::::tttt:::::te::::::::e           r:::::r            
I::::::::I    tt::::::::::::::t e::::::::eeeeeeee   r:::::r            
I::::::::I      tt:::::::::::tt  ee:::::::::::::e   r:::::r            
IIIIIIIIII        ttttttttttt      eeeeeeeeeeeeee   rrrrrrr            
*/


        // FC1 file load
        $readmemh("fc1_wght.mem",FC1_wght_bus);

        for ( i=0 ; i<17 ; i=i+1) 
        begin
            FC1_ofmap_bus[i]=64'd0;
        end

        //===================================
        // Iterate Through 16 Output Channel
        //===================================
        for (fc1_ochidx = 0 ; fc1_ochidx<16 ; fc1_ochidx=fc1_ochidx+1) 
        begin
            


/*
FFFFFFFFFFFFFFFFFFFFFF       CCCCCCCCCCCCC       1111111                                               
F::::::::::::::::::::F    CCC::::::::::::C      1::::::1                                               
F::::::::::::::::::::F  CC:::::::::::::::C     1:::::::1                                               
FF::::::FFFFFFFFF::::F C:::::CCCCCCCC::::C     111:::::1                                               
  F:::::F       FFFFFFC:::::C       CCCCCC        1::::1                                               
  F:::::F            C:::::C                      1::::1                                               
  F::::::FFFFFFFFFF  C:::::C                      1::::1                                               
  F:::::::::::::::F  C:::::C                      1::::l                                               
  F:::::::::::::::F  C:::::C                      1::::l                                               
  F::::::FFFFFFFFFF  C:::::C                      1::::l                                               
  F:::::F            C:::::C                      1::::l                                               
  F:::::F             C:::::C       CCCCCC        1::::l                                               
FF:::::::FF            C:::::CCCCCCCC::::C     111::::::111                                            
F::::::::FF             CC:::::::::::::::C     1::::::::::1                                            
F::::::::FF               CCC::::::::::::C     1::::::::::1                                            
FFFFFFFFFFF                  CCCCCCCCCCCCC     111111111111                                            

IIIIIIIIII                                   hhhhhhh                                 AAA               
I::::::::I                                   h:::::h                                A:::A              
I::::::::I                                   h:::::h                               A:::::A             
II::::::II                                   h:::::h                              A:::::::A            
  I::::Innnn  nnnnnnnn        cccccccccccccccch::::h hhhhh                       A:::::::::A           
  I::::In:::nn::::::::nn    cc:::::::::::::::ch::::hh:::::hhh                   A:::::A:::::A          
  I::::In::::::::::::::nn  c:::::::::::::::::ch::::::::::::::hh                A:::::A A:::::A         
  I::::Inn:::::::::::::::nc:::::::cccccc:::::ch:::::::hhh::::::h              A:::::A   A:::::A        
  I::::I  n:::::nnnn:::::nc::::::c     ccccccch::::::h   h::::::h            A:::::A     A:::::A       
  I::::I  n::::n    n::::nc:::::c             h:::::h     h:::::h           A:::::AAAAAAAAA:::::A      
  I::::I  n::::n    n::::nc:::::c             h:::::h     h:::::h          A:::::::::::::::::::::A     
  I::::I  n::::n    n::::nc::::::c     ccccccch:::::h     h:::::h         A:::::AAAAAAAAAAAAA:::::A    
II::::::IIn::::n    n::::nc:::::::cccccc:::::ch:::::h     h:::::h        A:::::A             A:::::A   
I::::::::In::::n    n::::n c:::::::::::::::::ch:::::h     h:::::h       A:::::A               A:::::A  
I::::::::In::::n    n::::n  cc:::::::::::::::ch:::::h     h:::::h      A:::::A                 A:::::A 
IIIIIIIIIInnnnnn    nnnnnn    cccccccccccccccchhhhhhh     hhhhhhh     AAAAAAA                   AAAAAAA
*/


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
                            //{null ,tlls,tlfr,relu,mpool,biasl,outch,inchannl,krnlC,krnlR,ofmpC,ofmpR,ifmpC,ifmpR, pad ,psum_split_condense}
                s00_axi_wdata={11'd0,1'b0,1'b1,1'b0, 1'b0, 2'd1, 5'd8, 10'd984, 3'd1, 3'd1, 6'd1, 6'd1, 6'd1, 6'd1,1'b0, 1'b0};
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
                s00_axi_wdata={32'h00010000, 5'd0,11'd985, 13'd0, 1'b0, 1'b0, 1'b1};
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
            i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=fc1_ochidx*1961;
            m00_axi_arready = 1'b1;
            while (!(!m00_axi_rready && transtotal==985)) 
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
                    m00_axi_rdata=FC1_wght_bus[transtotal+offset];
                    
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
            while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
                s00_axi_wdata={32'h00010000, 5'd0, 11'd123, 13'd0, 1'b0, 1'b1, 1'b0};
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
            i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
            m00_axi_arready = 1'b1;
            while (!(!m00_axi_rready && transtotal==123) )
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
                    m00_axi_rdata=FC1_ifmap_bus[transtotal+offset];
                    
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
            while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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



/*
FFFFFFFFFFFFFFFFFFFFFF       CCCCCCCCCCCCC       1111111                                  
F::::::::::::::::::::F    CCC::::::::::::C      1::::::1                                  
F::::::::::::::::::::F  CC:::::::::::::::C     1:::::::1                                  
FF::::::FFFFFFFFF::::F C:::::CCCCCCCC::::C     111:::::1                                  
  F:::::F       FFFFFFC:::::C       CCCCCC        1::::1                                  
  F:::::F            C:::::C                      1::::1                                  
  F::::::FFFFFFFFFF  C:::::C                      1::::1                                  
  F:::::::::::::::F  C:::::C                      1::::l                                  
  F:::::::::::::::F  C:::::C                      1::::l                                  
  F::::::FFFFFFFFFF  C:::::C                      1::::l                                  
  F:::::F            C:::::C                      1::::l                                  
  F:::::F             C:::::C       CCCCCC        1::::l                                  
FF:::::::FF            C:::::CCCCCCCC::::C     111::::::111                               
F::::::::FF             CC:::::::::::::::C     1::::::::::1                               
F::::::::FF               CCC::::::::::::C     1::::::::::1                               
FFFFFFFFFFF                  CCCCCCCCCCCCC     111111111111                               

IIIIIIIIII                                   hhhhhhh                  BBBBBBBBBBBBBBBBB   
I::::::::I                                   h:::::h                  B::::::::::::::::B  
I::::::::I                                   h:::::h                  B::::::BBBBBB:::::B 
II::::::II                                   h:::::h                  BB:::::B     B:::::B
  I::::Innnn  nnnnnnnn        cccccccccccccccch::::h hhhhh              B::::B     B:::::B
  I::::In:::nn::::::::nn    cc:::::::::::::::ch::::hh:::::hhh           B::::B     B:::::B
  I::::In::::::::::::::nn  c:::::::::::::::::ch::::::::::::::hh         B::::BBBBBB:::::B 
  I::::Inn:::::::::::::::nc:::::::cccccc:::::ch:::::::hhh::::::h        B:::::::::::::BB  
  I::::I  n:::::nnnn:::::nc::::::c     ccccccch::::::h   h::::::h       B::::BBBBBB:::::B 
  I::::I  n::::n    n::::nc:::::c             h:::::h     h:::::h       B::::B     B:::::B
  I::::I  n::::n    n::::nc:::::c             h:::::h     h:::::h       B::::B     B:::::B
  I::::I  n::::n    n::::nc::::::c     ccccccch:::::h     h:::::h       B::::B     B:::::B
II::::::IIn::::n    n::::nc:::::::cccccc:::::ch:::::h     h:::::h     BB:::::BBBBBB::::::B
I::::::::In::::n    n::::n c:::::::::::::::::ch:::::h     h:::::h     B:::::::::::::::::B 
I::::::::In::::n    n::::n  cc:::::::::::::::ch:::::h     h:::::h     B::::::::::::::::B  
IIIIIIIIIInnnnnn    nnnnnn    cccccccccccccccchhhhhhh     hhhhhhh     BBBBBBBBBBBBBBBBB   
*/


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
                            //{null ,tlls,tlfr,relu,mpool,biasl,outch,inchannl,krnlC,krnlR,ofmpC,ofmpR,ifmpC,ifmpR, pad ,psum_split_condense}
                s00_axi_wdata={11'd0,1'b1,1'b0,1'b1, 1'b0, 2'd0, 5'd8, 10'd976, 3'd1, 3'd1, 6'd1, 6'd1, 6'd1, 6'd1,1'b0, 1'b0};
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
                s00_axi_wdata={32'h00010000, 5'd0,11'd976, 13'd0, 1'b0, 1'b0, 1'b1};
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
            i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=fc1_ochidx*1961+985;
            m00_axi_arready = 1'b1;
            while (!(!m00_axi_rready && transtotal==976)) 
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
                    m00_axi_rdata=FC1_wght_bus[transtotal+offset];
                    
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
            while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
                s00_axi_wdata={32'h00010000, 5'd0, 11'd122, 13'd0, 1'b0, 1'b1, 1'b0};
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
            i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=123;
            m00_axi_arready = 1'b1;
            while (!(!m00_axi_rready && transtotal==122) )
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
                    m00_axi_rdata=FC1_ifmap_bus[transtotal+offset];
                    
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
            while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
                            //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
                s00_axi_wdata={32'h00010000, 5'd0, 11'd3, 13'd0, 1'b1, 1'b0, 1'b0};
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
                s00_axi_wdata={32'h00010000, 5'd0, 11'd3, 13'd0, 1'b0, 1'b0, 1'b0};
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
            i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=fc1_ochidx;
            m00_axi_awready=1'b1;
            while (!(!m00_axi_wvalid && transtotal==3))
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
                    FC1_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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



        end // fc1 output channel loop


        #10 $writememh("fc1_ofmap.mem",FC1_ofmap_bus);


/*
FFFFFFFFFFFFFFFFFFFFFF       CCCCCCCCCCCCC      222222222222222    
F::::::::::::::::::::F    CCC::::::::::::C     2:::::::::::::::22  
F::::::::::::::::::::F  CC:::::::::::::::C     2::::::222222:::::2 
FF::::::FFFFFFFFF::::F C:::::CCCCCCCC::::C     2222222     2:::::2 
  F:::::F       FFFFFFC:::::C       CCCCCC                 2:::::2 
  F:::::F            C:::::C                               2:::::2 
  F::::::FFFFFFFFFF  C:::::C                            2222::::2  
  F:::::::::::::::F  C:::::C                       22222::::::22   
  F:::::::::::::::F  C:::::C                     22::::::::222     
  F::::::FFFFFFFFFF  C:::::C                    2:::::22222        
  F:::::F            C:::::C                   2:::::2             
  F:::::F             C:::::C       CCCCCC     2:::::2             
FF:::::::FF            C:::::CCCCCCCC::::C     2:::::2       222222
F::::::::FF             CC:::::::::::::::C     2::::::2222222:::::2
F::::::::FF               CCC::::::::::::C     2::::::::::::::::::2
FFFFFFFFFFF                  CCCCCCCCCCCCC     22222222222222222222
*/


        // FC2 file load
        $readmemh("fc2_wght.mem",FC2_wght_bus);
        FC2_ofmap_bus[0]=64'd0;
        FC2_ofmap_bus[1]=64'd0;

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
                        //{null ,tlls,tlfr,relu,mpool,biasl,outch,inchannl,krnlC,krnlR,ofmpC,ofmpR,ifmpC,ifmpR, pad ,psum_split_condense}
            s00_axi_wdata={11'd0,1'b1,1'b1,1'b0, 1'b0, 2'd2,5'd10, 10'd128, 3'd1, 3'd1, 6'd1, 6'd1, 6'd1, 6'd1,1'b0, 1'b0};
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
            s00_axi_wdata={32'h00010000, 5'd0,11'd258, 13'd0, 1'b0, 1'b0, 1'b1};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==258)) 
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
                m00_axi_rdata=FC2_wght_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd3 && s00_axi_rdata[12:9]==4'd0))
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
            s00_axi_wdata={32'h00010000, 5'd0, 11'd16, 13'd0, 1'b0, 1'b1, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_arready = 1'b1;
        while (!(!m00_axi_rready && transtotal==16) )
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
                m00_axi_rdata=FC1_ofmap_bus[transtotal+offset];
                
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
        while (!(s00_axi_rvalid && s00_axi_rdata[8:5]==4'd8 && s00_axi_rdata[12:9]==4'd0))
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
                        //{   ctrl_addr, null,mstlen,  null,ofmol,ifmld,wgtld}
            s00_axi_wdata={32'h00010000, 5'd0, 11'd2, 13'd0, 1'b1, 1'b0, 1'b0};
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
        i=0; transtotal=0; bstlenidxassign=0; bstlenidxcompare=0; offset=0;
        m00_axi_awready=1'b1;
        while (!(!m00_axi_wvalid && transtotal==2))
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
                FC2_ofmap_bus[transtotal+offset]=m00_axi_wdata;
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


        #10 $writememh("pred.mem",FC2_ofmap_bus);


        #100 $finish;



    end

    
endmodule