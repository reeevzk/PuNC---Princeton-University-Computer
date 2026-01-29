`include "Defines.v"

module PUnCControl(
	// External Inputs
	input  wire        clk,            // Clock
	input  wire        rst,            // Reset
	
    // Datapath Inputs
    input wire [15:0] ir,         // Instruction Register contents
    input wire N, input wire Z, input wire P, // Condition Codes (Negative, Zero, Positive)

    // Functional Unit Controls
    output reg status_src_sel ,              // Condition Code select
    output reg status_ld, 		//condition codes enable
    output reg [1:0] alu_op,         // ALU operation select
    output reg [1:0] alu_A_sel,      // ALU Input A select
    output reg [2:0] alu_B_sel,      // ALU Input B select
	
	// Memory Controls 
	output reg  [2:0]  mem_r_addr_sel, // Mux select for Mem Read Address
	output reg mem_w_addr_sel, // Mux select for Mem Write Address
    output reg mem_w_en,             // Memory Write Enable (1 bit)
	output reg indirect_en,

	// Register File Controls
	output reg rf_r_addr_0_sel, // NEW: Mux select for R_addr_0 (0=8:6, 1=11:9)
	output reg rf_r_addr_1_sel, // NEW: Mux select for R_addr_1 (0=0:2, 1=8:6)
	output reg rf_w_addr_sel,   // Mux select for Write Address (DR/R7)
	output reg [1:0] rf_w_data_sel,   // Mux select for Write Data (ALU/MEM/PC+1)
	output reg rf_w_en,               // Register File Write Enable (1 bit)

	// Instruction Register Controls
	output reg ir_w_en,               // IR Write Enable (1 bit)

	// Program Counter Controls
	output reg [1:0] pc_src_sel,        // PC Load Select (selects next PC source AND acts as enable)
	output reg pc_ld
);

	// FSM States
	localparam STATE_FETCH     = 3'd0;
	localparam STATE_DECODE    = 3'd1;
	localparam STATE_EXEC      = 3'd2; 
	localparam STATE_EXEC1 = 3'd3;
	localparam STATE_HALT = 3'd4;


	// State, Next State
	reg [3:0] state, next_state;

    // Instruction Field Extraction
    wire [3:0] opcode;
    assign opcode = ir[15:12];
    //wire is_jsr_abs = (ir[`JSR_BIT_NUM] == `IS_JSR);
    wire [2:0] is_br_cond = ir[11:9]; 
    wire take_branch = (N && ir[`BR_N]) | (Z && ir[`BR_Z]) | (P && ir[`BR_P]);
	
    // --- State Update Sequential Logic ---
	always @(posedge clk) begin
		if (rst) begin
			state <= STATE_FETCH;
		end
		else begin
			state <= next_state;
		end
	end

    // --- Next State Combinational Logic ---
	always @( * ) begin
		next_state = state; 

		case (state)
			
			STATE_FETCH:  begin
			
			next_state = STATE_DECODE;
			
			end
			STATE_DECODE: begin
			      if (ir[`OC] == `OC_HLT) begin
                       next_state = STATE_HALT;
                       end
	               else begin
		          next_state = STATE_EXEC;
            end
            end
            		
            STATE_EXEC: begin
                if (opcode == `OC_LDI) begin
                    next_state = STATE_EXEC1;
              
                end else begin
                    next_state = STATE_FETCH;
                    end
		
        end
             STATE_EXEC1: begin
				next_state = STATE_FETCH;
				end
			STATE_HALT: begin
				next_state = STATE_HALT;
				end
	   endcase
	end
    
    // --- Output Combinational Logic (Control Signal Generation) ---
	always @( * ) begin
		// Set default values (inactive state)
		mem_r_addr_sel = 3'b000;
		mem_w_addr_sel = 1'b0; 
		mem_w_en = 1'b0;
		indirect_en = 1'b0;

		rf_r_addr_0_sel = 1'b0; 
		rf_r_addr_1_sel = 1'b0; 
		rf_w_addr_sel = 1'b0;
		rf_w_data_sel = 2'b00;
		rf_w_en = 1'b0;

		ir_w_en = 1'b0;

		
        pc_ld = 1'b0;
        pc_src_sel = 2'b00;
        status_src_sel = 1'b0;
        status_ld = 1'b0;
        alu_op = 2'b00;
        alu_A_sel = 2'b00;
        alu_B_sel = 3'b000; 
        

		case (state)
            // ----------------------------------------------------------------
            // 0. FETCH STAGE
            // ----------------------------------------------------------------
			STATE_FETCH: begin
				ir_w_en = 1'b1;  
			end
            // ----------------------------------------------------------------
            // 1. DECODE STAGE
            // ----------------------------------------------------------------
			STATE_DECODE: begin
                pc_src_sel = `PC_SRC_SEL_INC; 
                pc_ld = 1'd1;
			end
	// ----------------------------------------------------------------
            // 2. EXEC STAGE
            // ----------------------------------------------------------------

            STATE_EXEC: begin
                
                case (opcode)
                    `OC_ADD: begin
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_8_6;
                        rf_r_addr_1_sel = `RF_R_ADDR_1_SEL_2_0;
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_ALU;
                        rf_w_en = 1'b1; 
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        alu_A_sel = `ALU_SRC_0_SEL_REG_0;
                        alu_op = `ALU_FN_ADD;
                        if(ir[`IMM_BIT_NUM] == `IS_IMM) begin
                            alu_B_sel = `ALU_SRC_1_SEL_SXT_5;
                        end
                        else begin
                            alu_B_sel = `ALU_SRC_1_SEL_REG_1;
                        end 
                       end
        
                    `OC_AND: begin 
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_8_6;
                        rf_r_addr_1_sel = `RF_R_ADDR_1_SEL_2_0;
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_ALU;
                        rf_w_en = 1'b1; 
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        alu_A_sel = `ALU_SRC_0_SEL_REG_0;
                        alu_op = `ALU_FN_AND;
                        if(ir[`IMM_BIT_NUM] == `IS_IMM) begin
                            alu_B_sel = `ALU_SRC_1_SEL_SXT_5;
                        end
                        else begin
                            alu_B_sel = `ALU_SRC_1_SEL_REG_1;
                        end 
                        end 

                    `OC_NOT: begin 
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        alu_op = `ALU_FN_NOT;
                        alu_A_sel = `ALU_SRC_0_SEL_REG_0; 
		                rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_8_6;
                        rf_w_en = 1'b1; 
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_ALU;
                        end
                                     
                    
                    `OC_LD: begin 
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        rf_w_en = 1'b1; 
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_MEM;
                        alu_op = `ALU_FN_ADD;
                                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        end
		

                    `OC_LDR: begin
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_8_6;
                        rf_w_en = 1'b1; 
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_MEM;
                        alu_op = `ALU_FN_ADD;
                                        alu_A_sel = `ALU_SRC_0_SEL_REG_0;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_6;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        end 


                   `OC_ST: begin //
                        alu_op = `ALU_FN_ADD;
                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_11_9;
                        mem_w_en  = 1'b1;
                        end

                   `OC_STR: begin // 
                        alu_op = `ALU_FN_ADD;
                        alu_A_sel = `ALU_SRC_0_SEL_REG_1;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_6;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_11_9;
                        rf_r_addr_1_sel = `RF_R_ADDR_1_SEL_8_6;
                        mem_w_en  = 1'b1;
                        end 
                        
                    `OC_STI: begin
                        alu_op = `ALU_FN_ADD;
                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        indirect_en = 1'b1;
                        mem_w_addr_sel = `MEM_W_ADDR_SEL_IND;
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_11_9;                        
                        mem_w_en  = 1'b1;	
                        end
                        
                      `OC_LDI: begin 
                        rf_w_data_sel = `RF_W_DATA_SEL_MEM;
                        alu_op = `ALU_FN_ADD;
                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_ALU;
                        indirect_en = 1'b1;
                     end 
    
                  
                    `OC_LEA: begin 
                        status_src_sel = `STATUS_SRC_SEL_ALU;
                        status_ld = 1'b1;
                        alu_op = `ALU_FN_ADD;
                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_ALU;
                        rf_w_en = 1'b1;
                        end 


                    `OC_BR: begin // BR (Branch)
                        pc_src_sel = `PC_SRC_SEL_ALU;
                        alu_A_sel = `ALU_SRC_0_SEL_PC;
                        alu_B_sel = `ALU_SRC_1_SEL_SXT_9;
                        alu_op = `ALU_FN_ADD;
		
                        if (take_branch) begin
                            pc_ld = 1'd1; 
                            end
                        
                        end


                    `OC_JMP: begin // JMP / RET 
                        rf_r_addr_0_sel = `RF_R_ADDR_0_SEL_8_6;
                        pc_src_sel = `PC_SRC_SEL_REG;
                        pc_ld = 1'b1;

                    end

                    `OC_JSR: begin // JSR / JSRR
                        rf_w_addr_sel = `RF_W_ADDR_SEL_7_CN;
                        rf_w_data_sel = `RF_W_DATA_SEL_PC;
                        rf_w_en = 1'b1;
                        pc_ld = 1'b1;
                        if (ir[`JSR_BIT_NUM] == `IS_JSR) begin
                            pc_src_sel = `PC_SRC_SEL_ALU;
                            alu_A_sel = `ALU_SRC_0_SEL_PC;
                            alu_B_sel = `ALU_SRC_1_SEL_SXT_11;
                            alu_op = `ALU_FN_ADD;
                            end

                        else begin  
                       	    pc_src_sel = `PC_SRC_SEL_REG; 
                		
                 end                   
            end
                  
                 
 	endcase
end
            
            // ----------------------------------------------------------------
            // 3. EXEC1 STAGE
            // ----------------------------------------------------------------
            STATE_EXEC1: begin 
                 case (opcode)
                    `OC_LDI: begin
                        rf_w_addr_sel = `RF_W_ADDR_SEL_11_9;
                        rf_w_data_sel = `RF_W_DATA_SEL_MEM;
                        mem_r_addr_sel = `MEM_R_ADDR_SEL_IND;
                        rf_w_en = 1'b1; 
                        end
endcase
end
            
            // ----------------------------------------------------------------
            // 5. HALT STAGE
            // ----------------------------------------------------------------
            STATE_HALT: begin
                // All enables are kept low, processor freezes
            end
        endcase
    end
endmodule




