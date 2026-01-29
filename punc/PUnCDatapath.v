//==============================================================================
// Datapath for PUnC LC3 Processor
//==============================================================================

`include "Defines.v"

module PUnCDatapath(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset

	// DEBUG Signals (Required by assignment)
	input  wire [15:0] mem_debug_addr,
	input  wire [2:0]  rf_debug_addr,
	output wire [15:0] mem_debug_data,
	output wire [15:0] rf_debug_data,
	output wire [15:0] pc_debug_data,

    // --- Control Signals from Controller ---
    input wire ir_w_en,
	input wire [1:0] pc_src_sel,          // PC Load Select (also acts as load enable)
    input wire pc_ld,
    input wire [2:0] mem_r_addr_sel,
    input wire mem_w_addr_sel,
    input wire mem_w_en,

	input wire rf_w_en,
	input wire rf_r_addr_0_sel, // New Mux Select: 0=IR[8:6], 1=IR[11:9]
    input wire rf_r_addr_1_sel, // New Mux Select: 0=IR[0:2], 1=IR[8:6]
	input wire rf_w_addr_sel,
	input wire [1:0] rf_w_data_sel,
	input wire indirect_en,
    
    input wire status_src_sel,
    input wire status_ld,
    input wire [1:0] alu_op,
    input wire [1:0] alu_A_sel,
    input wire [2:0] alu_B_sel,
    
    // --- Status Signals to Controller ---
    output reg N,
    output reg Z,
    output reg P,
    output wire [15:0] ir
);

	// --- Local Registers (Sequential Logic) ---
	reg  [15:0] pc;
	reg [15:0] ir_reg;
    reg  [15:0] ireg; // Indirect Register (for LDI/STI intermediate address)
    assign ir = ir_reg;
    //reg N_reg, Z_reg, P_reg; // Condition Codes

	// Assign PC debug net
	assign pc_debug_data = pc;
    
    // Assign Condition Code status outputs
    

	// --- Wire Declarations (Combinational Logic) ---

    // PC wires
    wire [15:0] pc_plus_1 = pc + 16'd1;
    wire [15:0] pc_next_val;

    // IR/Instruction field wires
    //wire [2:0] ir_DR = ir[11:9];
    //wire [2:0] ir_SR1_BaseR = ir[8:6];
    //wire [2:0] ir_SR2 = ir[2:0];
    wire [2:0] rf_w_addr_out; // Mux output for RF write address

    // Register File wires
    // --- Wire Declarations (Instruction Fields) ---
    wire [2:0] ir_DR_SR = ir[11:9];    // Destination Register (DR) or Source Register (SR) for ST/NOT
    wire [2:0] ir_SR1_BaseR = ir[8:6]; // Source Register 1 (SR1) or Base Register (BaseR)
    wire [2:0] ir_SR2_BaseR = ir[2:0]; // Source Register 2 (SR2) or Base Register (BaseR)
    wire [2:0] R7_ADDR = 3'b111;       // Register 7 address (0x7)
    wire [15:0] rf_data_A; // r_data_0 (Source R1, BaseR)
    wire [15:0] rf_data_B; // r_data_1 (Source R2)
    wire [15:0] rf_w_data; // Mux output for RF write data

    // Memory wires
    wire [15:0] mem_r_data; // r_data_0
    wire [15:0] mem_r_addr; // r_addr_0 (Mux output for read address)
    wire [15:0] mem_w_addr; // w_addr (Mux output for write address)
    
    // Sign-Extended Immediate wires (SEXT)
    wire [15:0] ir_isxt_5     = {{11{ir_reg[4]}}, ir_reg[4:0]};
    wire [15:0] ir_isxt_6   = {{10{ir_reg[5]}}, ir_reg[5:0]};
    wire [15:0] ir_isxt_9  = {{7{ir_reg[8]}}, ir_reg[8:0]};
    wire [15:0] ir_isxt_11 = {{5{ir_reg[10]}}, ir_reg[10:0]};

    // ALU wires
    wire [15:0] alu_A_in;
    wire [15:0] alu_B_in;
    wire [15:0] alu_result;

    // Data constant/special wires
    wire [2:0] R7_ADDR = 3'b111; // Register 7 address
    
    wire [15:0] status_data;
    
    wire [2:0] rf_r_addr_0_in;
    
    wire [2:0] rf_r_addr_1_in;


	//----------------------------------------------------------------------
	// 1. Program Counter (PC) and Instruction Register (IR) Logic
	//----------------------------------------------------------------------



    // PC Update Logic (Synchronous)
    always @(posedge clk) begin
        if (rst) begin
            pc <= 16'd0; 
        end else if (pc_ld) begin
            pc <= pc_next_val;
    
        end
        end
        
   assign pc_next_val = (pc_src_sel == `PC_SRC_SEL_REG) ? rf_data_A :
                       (pc_src_sel == `PC_SRC_SEL_INC)  ? pc_plus_1 :
                       (pc_src_sel == `PC_SRC_SEL_ALU) ? alu_result : 
                                                      pc_plus_1; // default
    
    
    // indirect register Update Logic (Synchronous)
    always @(posedge clk) begin
        if (rst) ir_reg <= 16'b0;
        else if (ir_w_en) ir_reg <= mem_r_data; 
    end

    // IREG Update Logic (Synchronous)
    // The IReg/Indirect Register stores the intermediate address for LDI/STI.
    always @(posedge clk) begin
        if (rst) ireg <= 16'b0;
        // Capture the result of the first memory read (which is the final address)
        else if (indirect_en) begin
            ireg <= mem_r_data;
        end
    end
    

	//----------------------------------------------------------------------
	// 2. Register File Logic
	//----------------------------------------------------------------------
    
    // RF Read Address Wiring (Directly from IR fields)
   // RF Read Address 0 Mux (Reads SR1/BaseR OR DR/SR)
    // 8:6 bits or 11:9 bits
    assign rf_r_addr_0_in = (rf_r_addr_0_sel == `RF_R_ADDR_0_SEL_11_9) ? ir_DR_SR : // 8:6 bits (SR1/BaseR)
                            /* 1'b1 */                 ir_SR1_BaseR;     // 11:9 bits (DR/SR)
    
    // RF Read Address 1 Mux (Reads SR2 OR SR1/BaseR)
    // 0:2 bits or 8:6 bits
    assign rf_r_addr_1_in = (rf_r_addr_1_sel == `RF_R_ADDR_1_SEL_8_6) ? ir_SR1_BaseR : // 2:0 bits (SR2)
                            /* 1'b1 */                 ir_SR2_BaseR; // 8:6 bits (SR1/BaseR)
    
    // RF Write Address Mux (Combinational)
    // 11:9 bits (DR/SR) or 7 (R7)
    assign rf_w_addr_out = (rf_w_addr_sel == `RF_W_ADDR_SEL_7_CN) ? R7_ADDR :
                           ir_DR_SR ;
                                                            
    // RF Write Data Mux (No change)
    assign rf_w_data = (rf_w_data_sel == `RF_W_DATA_SEL_ALU) ? alu_result :
                       (rf_w_data_sel == `RF_W_DATA_SEL_PC)  ? pc :
                       (rf_w_data_sel == `RF_W_DATA_SEL_MEM) ? mem_r_data : 
                                                      alu_result; // default

	//----------------------------------------------------------------------
	// 3. Memory Address Logic
	//----------------------------------------------------------------------
    
    // Memory Read Address Mux (Combinational)
    assign mem_r_addr = (mem_r_addr_sel == `MEM_R_ADDR_SEL_PC)  ? pc :        
                        (mem_r_addr_sel == `MEM_R_ADDR_SEL_ALU) ? alu_result : 
		(mem_r_addr_sel == `MEM_R_ADDR_SEL_IND) ? ireg:
                        16'b0;
                        
    // Memory Write Address Mux (Combinational)
    assign mem_w_addr = (mem_w_addr_sel == `MEM_W_ADDR_SEL_ALU)  ? alu_result :
                        (mem_w_addr_sel == `MEM_W_ADDR_SEL_IND) ? ireg : // ST, STR, STI address
                        16'b0;


	//----------------------------------------------------------------------
	// 4. ALU and Comparator (Condition Code) Logic
	//----------------------------------------------------------------------
    

    // ALU input A MUX (Combinational)
assign alu_A_in = (alu_A_sel == `ALU_SRC_0_SEL_REG_0) ? rf_data_A :
	(alu_A_sel == `ALU_SRC_0_SEL_REG_1 ) ? rf_data_B:
	(alu_A_sel == `ALU_SRC_0_SEL_PC) ? pc : 
	16'b0;

    // ALU Input B Mux (Combinational)

    assign alu_B_in = (alu_B_sel == `ALU_SRC_1_SEL_REG_1)    ? rf_data_B :
                     (alu_B_sel == `ALU_SRC_1_SEL_SXT_5)    ? ir_isxt_5  :
                     (alu_B_sel == `ALU_SRC_1_SEL_SXT_6)      ? ir_isxt_6 : // Use PC+1 for address calculations
		(alu_B_sel == `ALU_SRC_1_SEL_SXT_9) ? ir_isxt_9 : 
		(alu_B_sel == `ALU_SRC_1_SEL_SXT_11) ? ir_isxt_11 :
                                                    16'b0; // Default

assign alu_result = (alu_op == `ALU_FN_ADD) ? (alu_A_in + alu_B_in) : 
	(alu_op == `ALU_FN_AND) ? alu_A_in & alu_B_in : 
	(alu_op == `ALU_FN_NOT) ? ~alu_A_in : 
		16'b0;
                                                      
assign status_data = (status_src_sel == `STATUS_SRC_SEL_MEM) ? mem_r_data : alu_result;
 
always @(posedge clk) begin
	if (rst) begin
		N <= 0;
		Z <= 0;
		P <= 0;
	end
	else if (status_ld) begin
		N <= (status_data[15] == 1) ? 1'd1 : 1'd0;
		Z <= (status_data == 16'd0) ? 1'd1 : 1'd0;
		P <= (status_data[15] == 0 && status_data != 16'd0) ? 1'd1 : 1'd0;
	end
    end
    
// Condition Codes

//----------------------------------------------------------------------
	// Module Instantiations
	//----------------------------------------------------------------------

	// Memory Module (r_data_0 is the primary datapath read port)
	Memory mem(
		.clk      (clk),
		.rst      (rst),
		.r_addr_0 (mem_r_addr),
		.r_addr_1 (mem_debug_addr),
		.w_addr   (mem_w_addr),
		.w_data   (rf_data_A), // Data from Register File (rf_data_A)
		.w_en     (mem_w_en),
		.r_data_0 (mem_r_data),
		.r_data_1 (mem_debug_data)
	);

	// Register File Module (r_data_0/r_data_1 are primary datapath read ports)
	RegisterFile rfile(
		.clk      (clk),
		.rst      (rst),
		.r_addr_0 (rf_r_addr_0_in), // Reads SR1/BaseR address
		.r_addr_1 (rf_r_addr_1_in),       // Reads SR2 address
		.r_addr_2 (rf_debug_addr),
		.w_addr   (rf_w_addr_out),
		.w_data   (rf_w_data),
		.w_en     (rf_w_en),
		.r_data_0 (rf_data_A),
		.r_data_1 (rf_data_B),
		.r_data_2 (rf_debug_data)
	);



	//----------------------------------------------------------------------
	// Add all other datapath logic here
	//----------------------------------------------------------------------

endmodule
