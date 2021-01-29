
`timescale 1 ns / 1 ps

	module axi_lite_wrapper #
	(
		// Users to add parameters here
		parameter integer C_M_AXI_ADDR_WIDTH=32,
		parameter integer C_LENGTH_WIDTH=14,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_DATA_WIDTH	= 64,
		parameter integer C_S00_AXI_ADDR_WIDTH	= 5
	)
	(
		// Users to add ports here
		input dataload_ready,
		input tile_done,
		input op_done,
		input AXI4_cmdack,
		input AXI4_error,
		input [3:0] FSM_comp,
		input [3:0] FSM_data,
		input psum_split_condense_val,
		input padding_val,
		input [1:0] bias_len_val,
		input maxpooling_val,

		output rst,
		output axi_rst,
		output config_load,
		output config_done,
		output op_go,
		
		output psum_split_condense,
		output padding,
		output maxpooling,
		output [5:0] ifmapR,
		output [5:0] ifmapC,
		output [5:0] ofmapR,
		output [5:0] ofmapC,
		output [2:0] kernelR,
		output [2:0] kernelC,
		output [9:0] inchannel,
		output [4:0] outchannel,
		output [1:0] bias_len,

		output wght_load,
		output ifmap_load,
		output ofmap_offload,

		output [C_M_AXI_ADDR_WIDTH-1:0] ctrl_addr,
		output [C_LENGTH_WIDTH-1:3] ctrl_mst_length,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [2 : 0] s00_axi_awprot,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [2 : 0] s00_axi_arprot,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready
	);
// Instantiation of Axi Bus Interface S00_AXI
	axi_light_slv_v1_0_S00_AXI # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) axi_light_slv_v1_0_S00_AXI_inst (
		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),

		.dataload_ready(dataload_ready),
		.tile_done(tile_done),
		.op_done(op_done),
		.AXI4_cmdack(AXI4_cmdack),
		.AXI4_error(AXI4_error),
		.FSM_comp(FSM_comp),
		.FSM_data(FSM_data),
		.psum_split_condense_val(psum_split_condense_val),
		.padding_val(padding_val),
		.bias_len_val(bias_len_val),
		.maxpooling_val(maxpooling_val),
		.rst(rst),
		.axi_rst(axi_rst),
		.config_load(config_load),
		.config_done(config_done),
		.op_go(op_go),
		.psum_split_condense(psum_split_condense),
		.padding(padding),
		.maxpooling(maxpooling),
		.ifmapR(ifmapR),
		.ifmapC(ifmapC),
		.ofmapR(ofmapR),
		.ofmapC(ofmapC),
		.kernelR(kernelR),
		.kernelC(kernelC),
		.inchannel(inchannel),
		.outchannel(outchannel),
		.bias_len(bias_len),
		.wght_load(wght_load),
		.ifmap_load(ifmap_load),
		.ofmap_offload(ofmap_offload),
		.ctrl_addr(ctrl_addr),
		.ctrl_mst_length(ctrl_mst_length)

	);

	// Add user logic here

	// User logic ends

	endmodule
