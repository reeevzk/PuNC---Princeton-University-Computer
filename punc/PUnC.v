//==============================================================================
// Module for PUnC LC3 Processor
// This top-level module connects the Control Unit and the Datapath.
//==============================================================================

module PUnC(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset

	// Debug Signals
	input  wire [15:0] mem_debug_addr,
	input  wire [2:0]  rf_debug_addr,
	output wire [15:0] mem_debug_data,
	output wire [15:0] rf_debug_data,
	output wire [15:0] pc_debug_data
);


	//----------------------------------------------------------------------
	// Interconnect Wires (Control Signals and Status Feedback)
	//----------------------------------------------------------------------

	// Control Signals (Controller -> Datapath)
	wire ir_w_en;
	wire [1:0] pc_src_sel;
	wire pc_ld;
	
	wire [2:0] mem_r_addr_sel;
	wire mem_w_addr_sel;
	wire mem_w_en;
	wire indirect_en; 		// LDI/STI IREG Load Enable

	wire rf_w_en;
	wire rf_r_addr_0_sel;
	wire rf_r_addr_1_sel;
	wire rf_w_addr_sel;
	wire [1:0] rf_w_data_sel;

	wire status_src_sel;
	wire status_ld;
	wire [1:0] alu_op;
	wire [1:0] alu_A_sel;
	wire [2:0] alu_B_sel;
	
	// Status Signals (Datapath -> Controller)
	wire N, Z, P;
	wire [15:0] ir; // Instruction Register contents

	//----------------------------------------------------------------------
	// Control Module Instantiation
	//----------------------------------------------------------------------
	PUnCControl ctrl(
		.clk             (clk),
		.rst             (rst),

		// Datapath Inputs (Status Feedback)
		.ir 			(ir),
		.N 				(N),
		.Z 				(Z),
		.P 				(P),

		// Functional Unit Controls (Outputs to Datapath)
		.status_src_sel (status_src_sel),
		.status_ld 		(status_ld),
		.alu_op 		(alu_op),
		.alu_A_sel 		(alu_A_sel),
		.alu_B_sel 		(alu_B_sel),
		
		// Memory Controls
		.mem_r_addr_sel (mem_r_addr_sel),
		.mem_w_addr_sel (mem_w_addr_sel),
		.mem_w_en 		(mem_w_en),
		.indirect_en 	(indirect_en),

		// Register File Controls
		.rf_r_addr_0_sel (rf_r_addr_0_sel),
		.rf_r_addr_1_sel (rf_r_addr_1_sel),
		.rf_w_addr_sel 	(rf_w_addr_sel),
		.rf_w_data_sel 	(rf_w_data_sel),
		.rf_w_en 		(rf_w_en),

		// Instruction Register Controls
		.ir_w_en 		(ir_w_en),

		// Program Counter Controls
		.pc_src_sel 	(pc_src_sel),
		.pc_ld          (pc_ld)
	);

	//----------------------------------------------------------------------
	// Datapath Module Instantiation
	//----------------------------------------------------------------------
	PUnCDatapath dpath(
		.clk             (clk),
		.rst             (rst),

		// Debug Ports
		.mem_debug_addr   (mem_debug_addr),
		.rf_debug_addr    (rf_debug_addr),
		.mem_debug_data   (mem_debug_data),
		.rf_debug_data    (rf_debug_data),
		.pc_debug_data    (pc_debug_data),

		// Control Signals (Inputs from Control Unit)
		.ir_w_en        (ir_w_en),
		.pc_src_sel     (pc_src_sel),
		.pc_ld          (pc_ld),
		.mem_r_addr_sel (mem_r_addr_sel),
		.mem_w_addr_sel (mem_w_addr_sel),
		.mem_w_en       (mem_w_en),
		.indirect_en    (indirect_en),
		.rf_w_en        (rf_w_en),
		.rf_r_addr_0_sel(rf_r_addr_0_sel),
		.rf_r_addr_1_sel(rf_r_addr_1_sel),
		.rf_w_addr_sel  (rf_w_addr_sel),
		.rf_w_data_sel  (rf_w_data_sel),
		.status_src_sel (status_src_sel),
		.status_ld      (status_ld),
		.alu_op         (alu_op),
		.alu_A_sel      (alu_A_sel),
		.alu_B_sel      (alu_B_sel),
		
		// Status Signals (Outputs to Control Unit)
		.N 	(N),
		.Z 	(Z),
		.P 	(P),
		.ir (ir) // IR output to Control
	);

endmodule

