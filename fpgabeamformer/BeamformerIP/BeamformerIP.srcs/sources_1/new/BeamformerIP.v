// ***************************************************************************
// ***************************************************************************
//  Copyright (C) 2014-2018  EPFL
//  "BeamformerIP" custom IP
//
//   Permission is hereby granted, free of charge, to any person
//   obtaining a copy of this software and associated documentation
//   files (the "Software"), to deal in the Software without
//   restriction, including without limitation the rights to use,
//   copy, modify, merge, publish, distribute, sublicense, and/or sell
//   copies of the Software, and to permit persons to whom the
//   Software is furnished to do so, subject to the following
//   conditions:
//
//   The above copyright notice and this permission notice shall be
//   included in all copies or substantial portions of the Software.
//
//   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//   OTHER DEALINGS IN THE SOFTWARE.
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************
// ***************************************************************************

`timescale 1 ns / 1 ps

	module BeamformerIP #
	(
		// Users to add parameters here
		parameter integer NAPPE_BUFFER_DEPTH = 3,         // Output nappe buffer depth
		parameter integer FIFO_CHAN_WIDTH = 16,           // Input AXI FIFO parameters
		parameter integer FIFO_WIDTH = 64,
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Axi Slave Bus Interface S00_AXI
		parameter integer C_S00_AXI_ID_WIDTH        = 1,
		parameter integer C_S00_AXI_DATA_WIDTH      = 32,
		parameter integer C_S00_AXI_ADDR_WIDTH      = 6,
		parameter integer C_S00_AXI_AWUSER_WIDTH    = 0,
		parameter integer C_S00_AXI_ARUSER_WIDTH    = 0,
		parameter integer C_S00_AXI_WUSER_WIDTH     = 0,
		parameter integer C_S00_AXI_RUSER_WIDTH     = 0,
		parameter integer C_S00_AXI_BUSER_WIDTH     = 0,
                
		// Parameters of Axi Master Bus Interface M00_AXI
		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR = 32'hC0000000,
		parameter integer C_M00_AXI_BURST_LEN       = 8,
		parameter integer C_M00_AXI_ID_WIDTH        = 1,
		parameter integer C_M00_AXI_DATA_WIDTH      = 32,
		parameter integer C_M00_AXI_ADDR_WIDTH      = 32,
		parameter integer C_M00_AXI_AWUSER_WIDTH    = 0,
		parameter integer C_M00_AXI_ARUSER_WIDTH    = 0,
		parameter integer C_M00_AXI_WUSER_WIDTH     = 0,
		parameter integer C_M00_AXI_RUSER_WIDTH     = 0,
		parameter integer C_M00_AXI_BUSER_WIDTH     = 0
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line
		
		// Ports of AXI Stream interface
		input wire fifo_axis_aresetn,
		input wire fifo_axis_aclk,
		output wire fifo_axis_tready,
		input wire fifo_axis_tvalid,
		input wire [31 : 0] fifo_axis_rd_data_count,
		input wire [FIFO_WIDTH - 1 : 0] fifo_axis_tdata,

		// Ports of Axi Slave Bus Interface S00_AXI
		input wire  s00_axi_aclk,
		input wire  s00_axi_aresetn,
		input wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_awid,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
		input wire [7 : 0] s00_axi_awlen,
		input wire [2 : 0] s00_axi_awsize,
		input wire [1 : 0] s00_axi_awburst,
		input wire  s00_axi_awlock,
		input wire [3 : 0] s00_axi_awcache,
		input wire [2 : 0] s00_axi_awprot,
		input wire [3 : 0] s00_axi_awqos,
		input wire [3 : 0] s00_axi_awregion,
		input wire  s00_axi_awvalid,
		output wire  s00_axi_awready,
		input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
		input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
		input wire  s00_axi_wlast,
		input wire  s00_axi_wvalid,
		output wire  s00_axi_wready,
		output wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_bid,
		output wire [1 : 0] s00_axi_bresp,
		output wire  s00_axi_bvalid,
		input wire  s00_axi_bready,
		input wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_arid,
		input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
		input wire [7 : 0] s00_axi_arlen,
		input wire [2 : 0] s00_axi_arsize,
		input wire [1 : 0] s00_axi_arburst,
		input wire  s00_axi_arlock,
		input wire [3 : 0] s00_axi_arcache,
		input wire [2 : 0] s00_axi_arprot,
		input wire [3 : 0] s00_axi_arqos,
		input wire [3 : 0] s00_axi_arregion,
		input wire  s00_axi_arvalid,
		output wire  s00_axi_arready,
		output wire [C_S00_AXI_ID_WIDTH-1 : 0] s00_axi_rid,
		output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
		output wire [1 : 0] s00_axi_rresp,
		output wire  s00_axi_rlast,
		output wire  s00_axi_rvalid,
		input wire  s00_axi_rready,

		// Ports of Axi Master Bus Interface M00_AXI
		input wire  m00_axi_aclk,
		input wire  m00_axi_aresetn,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [7 : 0] m00_axi_awlen,
		output wire [2 : 0] m00_axi_awsize,
		output wire [1 : 0] m00_axi_awburst,
		output wire  m00_axi_awlock,
		output wire [3 : 0] m00_axi_awcache,
		output wire [2 : 0] m00_axi_awprot,
		output wire [3 : 0] m00_axi_awqos,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wlast,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
		input wire [1 : 0] m00_axi_bresp,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [7 : 0] m00_axi_arlen,
		output wire [2 : 0] m00_axi_arsize,
		output wire [1 : 0] m00_axi_arburst,
		output wire  m00_axi_arlock,
		output wire [3 : 0] m00_axi_arcache,
		output wire [2 : 0] m00_axi_arprot,
		output wire [3 : 0] m00_axi_arqos,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rlast,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready
	);
	
    // Wires between the Axi Slave and Channel Reorder modules
    wire stall_aurora_fifo;
    wire valid_aurora_fifo;
    wire [FIFO_CHAN_WIDTH - 1 : 0] data_aurora_fifo;

    // Wires between the Axi Slave and Master modules
    wire [15 : 0] saved_nappes;
    wire [31 : 0] fifo_data;
    wire fifo_output_valid;
    wire fifo_output_ready;
    wire compound_not_zone_imaging;
    wire [6 : 0] run_cnt;
    wire [6 : 0] zone_width;
    wire [6 : 0] zone_height;
    wire [3 : 0] azimuth_zones;
    wire [3 : 0] elevation_zones;
    
    // Instantiate a reordering block to manage the incoming data from the AXI FIFO (data from the probe)
    // Takes the data in the format sent by the probe and extracts, one channel at a time, the data for the beamformer
    // For compatibility with the beamformer, the data is also extended from 12 bits to FIFO_CHAN_WIDTH bits
    // with sign bit replication
    reorder_chan # (
        .FIFO_WIDTH(FIFO_WIDTH),
        .FIFO_CHAN_WIDTH(FIFO_CHAN_WIDTH)
    ) reorder_chan_inst(.fifo_axis_aresetn(fifo_axis_aresetn),
        .fifo_axis_aclk(fifo_axis_aclk),
        .fifo_axis_tready(fifo_axis_tready),
        .fifo_axis_tvalid(fifo_axis_tvalid),
        .fifo_axis_tdata(fifo_axis_tdata),
        .chan_data(data_aurora_fifo),
        .stall(stall_aurora_fifo),
        .valid(valid_aurora_fifo)
    );

	// Instantiation of Axi Bus Interface S00_AXI (Microblaze interface)
	BeamformerIP_S00_AXI # (
		.C_S_AXI_ID_WIDTH(C_S00_AXI_ID_WIDTH),
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH),
		.C_S00_AXI_AWUSER_WIDTH(C_S00_AXI_AWUSER_WIDTH),
		.C_S00_AXI_ARUSER_WIDTH(C_S00_AXI_ARUSER_WIDTH),
		.C_S00_AXI_WUSER_WIDTH(C_S00_AXI_WUSER_WIDTH),
		.C_S00_AXI_RUSER_WIDTH(C_S00_AXI_RUSER_WIDTH),
		.C_S00_AXI_BUSER_WIDTH(C_S00_AXI_BUSER_WIDTH),
		.FIFO_CHAN_WIDTH(FIFO_CHAN_WIDTH),
		.NAPPE_BUFFER_DEPTH(NAPPE_BUFFER_DEPTH)
	) BeamformerIP_S00_AXI_inst (
		.saved_nappes(saved_nappes),
		.fifo_data(fifo_data),
		.fifo_output_valid(fifo_output_valid),
		.fifo_output_ready(fifo_output_ready),
		.compound_not_zone_imaging(compound_not_zone_imaging),
		.run_cnt(run_cnt),
		.zone_width(zone_width),
		.zone_height(zone_height),
		.azimuth_zones(azimuth_zones),
		.elevation_zones(elevation_zones),

		.S_AXI_ACLK(s00_axi_aclk),
		.S_AXI_ARESETN(s00_axi_aresetn),
		.S_AXI_AWID(s00_axi_awid),
		.S_AXI_AWADDR(s00_axi_awaddr),
		.S_AXI_AWLEN(s00_axi_awlen),
		.S_AXI_AWSIZE(s00_axi_awsize),
		.S_AXI_AWBURST(s00_axi_awburst),
		.S_AXI_AWLOCK(s00_axi_awlock),
		.S_AXI_AWCACHE(s00_axi_awcache),
		.S_AXI_AWPROT(s00_axi_awprot),
		.S_AXI_AWQOS(s00_axi_awqos),
		.S_AXI_AWREGION(s00_axi_awregion),
		.S_AXI_AWVALID(s00_axi_awvalid),
		.S_AXI_AWREADY(s00_axi_awready),
		.S_AXI_WDATA(s00_axi_wdata),
		.S_AXI_WSTRB(s00_axi_wstrb),
		.S_AXI_WLAST(s00_axi_wlast),
		.S_AXI_WVALID(s00_axi_wvalid),
		.S_AXI_WREADY(s00_axi_wready),
		.S_AXI_BID(s00_axi_bid),
		.S_AXI_BRESP(s00_axi_bresp),
		.S_AXI_BVALID(s00_axi_bvalid),
		.S_AXI_BREADY(s00_axi_bready),
		.S_AXI_ARID(s00_axi_arid),
		.S_AXI_ARADDR(s00_axi_araddr),
		.S_AXI_ARLEN(s00_axi_arlen),
		.S_AXI_ARSIZE(s00_axi_arsize),
		.S_AXI_ARBURST(s00_axi_arburst),
		.S_AXI_ARLOCK(s00_axi_arlock),
		.S_AXI_ARCACHE(s00_axi_arcache),
		.S_AXI_ARPROT(s00_axi_arprot),
		.S_AXI_ARQOS(s00_axi_arqos),
		.S_AXI_ARREGION(s00_axi_arregion),
		.S_AXI_ARVALID(s00_axi_arvalid),
		.S_AXI_ARREADY(s00_axi_arready),
		.S_AXI_RID(s00_axi_rid),
		.S_AXI_RDATA(s00_axi_rdata),
		.S_AXI_RRESP(s00_axi_rresp),
		.S_AXI_RLAST(s00_axi_rlast),
		.S_AXI_RVALID(s00_axi_rvalid),
		.S_AXI_RREADY(s00_axi_rready),
		
		.fifo_axis_rd_data_count(fifo_axis_rd_data_count),
		.stall_aurora_fifo(stall_aurora_fifo),
		.valid_aurora_fifo(valid_aurora_fifo),
		.data_aurora_fifo(data_aurora_fifo)
	);

	// Instantiation of Axi Bus Interface M00_AXI
	BeamformerIP_M00_AXI # ( 
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_BURST_LEN(C_M00_AXI_BURST_LEN),
		.C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
		.C_M_AXI_ARUSER_WIDTH(C_M00_AXI_ARUSER_WIDTH),
		.C_M_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
		.C_M_AXI_RUSER_WIDTH(C_M00_AXI_RUSER_WIDTH),
		.C_M_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH)
	) BeamformerIP_M00_AXI_inst (
		.saved_nappes(saved_nappes),
		.fifo_data(fifo_data),
		.fifo_output_valid(fifo_output_valid),
		.fifo_output_ready(fifo_output_ready),
		.azimuth_zones(azimuth_zones),
		.elevation_zones(elevation_zones),
		.compound_not_zone_imaging(compound_not_zone_imaging),
		.run_cnt(run_cnt),
		.zone_width(zone_width),
		.zone_height(zone_height),

		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWID(m00_axi_awid),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWLEN(m00_axi_awlen),
		.M_AXI_AWSIZE(m00_axi_awsize),
		.M_AXI_AWBURST(m00_axi_awburst),
		.M_AXI_AWLOCK(m00_axi_awlock),
		.M_AXI_AWCACHE(m00_axi_awcache),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWQOS(m00_axi_awqos),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WLAST(m00_axi_wlast),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BID(m00_axi_bid),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARID(m00_axi_arid),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARLEN(m00_axi_arlen),
		.M_AXI_ARSIZE(m00_axi_arsize),
		.M_AXI_ARBURST(m00_axi_arburst),
		.M_AXI_ARLOCK(m00_axi_arlock),
		.M_AXI_ARCACHE(m00_axi_arcache),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARQOS(m00_axi_arqos),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RID(m00_axi_rid),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RLAST(m00_axi_rlast),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);
	// Add user logic here
	// User logic ends

endmodule
