//==============================================================================
// Global Defines for PUnC LC3 Computer
//==============================================================================

//------------------------------------------------------------------------------
// Control Signals
//------------------------------------------------------------------------------

// Memory Unit
`define MEM_R_ADDR_SEL_PC    2'b00
`define MEM_R_ADDR_SEL_ALU   2'b01
`define MEM_R_ADDR_SEL_IND   2'b10

`define MEM_W_ADDR_SEL_ALU   1'b0
`define MEM_W_ADDR_SEL_IND   1'b1

// Register File
`define RF_R_ADDR_0_SEL_8_6  1'b0
`define RF_R_ADDR_0_SEL_11_9 1'b1

`define RF_R_ADDR_1_SEL_2_0  1'b0
`define RF_R_ADDR_1_SEL_8_6  1'b1

`define RF_W_ADDR_SEL_11_9   1'b0
`define RF_W_ADDR_SEL_7_CN   1'b1

`define RF_W_DATA_SEL_ALU    2'b00
`define RF_W_DATA_SEL_PC     2'b01
`define RF_W_DATA_SEL_MEM    2'b10

// Status Registers
`define STATUS_SRC_SEL_ALU   1'b0
`define STATUS_SRC_SEL_MEM   1'b1

// PC
`define PC_SRC_SEL_REG       2'b00
`define PC_SRC_SEL_INC       2'b01
`define PC_SRC_SEL_ALU       2'b10

// ALU
`define ALU_SRC_0_SEL_REG_0  2'b00
`define ALU_SRC_0_SEL_REG_1  2'b01
`define ALU_SRC_0_SEL_PC     2'b10

`define ALU_SRC_1_SEL_REG_1  3'b000
`define ALU_SRC_1_SEL_SXT_5  3'b001
`define ALU_SRC_1_SEL_SXT_6  3'b010
`define ALU_SRC_1_SEL_SXT_9  3'b011
`define ALU_SRC_1_SEL_SXT_11 3'b100

`define ALU_FN_ADD           2'b00
`define ALU_FN_AND           2'b01
`define ALU_FN_NOT           2'b10

//------------------------------------------------------------------------------
// Opcodes
//------------------------------------------------------------------------------
`define OC 15:12

`define OC_ADD 4'b0001
`define OC_AND 4'b0101
`define OC_BR  4'b0000
`define OC_JMP 4'b1100
`define OC_JSR 4'b0100
`define OC_LD  4'b0010
`define OC_LDI 4'b1010
`define OC_LDR 4'b0110
`define OC_LEA 4'b1110
`define OC_NOT 4'b1001
`define OC_ST  4'b0011
`define OC_STI 4'b1011
`define OC_STR 4'b0111
`define OC_HLT 4'b1111

`define IMM_BIT_NUM 5
`define IS_IMM 1'b1
`define JSR_BIT_NUM 11
`define IS_JSR 1'b1

`define BR_N 11
`define BR_Z 10
`define BR_P 9

`define RET_MATCH 16'b1100000111000000

