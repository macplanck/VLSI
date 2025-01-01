`include "../05_Sub/Program_Counter.sv"
`include "../05_Sub/Adder.sv"
`include "../05_Sub/Mux.sv"
// `include "../05_Sub/Mux2to1.sv"
// `include "../05_Sub/Mux3to1.sv"
// `include "../05_Sub/Mux4to1.sv"
`include "../05_Sub/Decoder.sv"
`include "../05_Sub/ALU_Ctrl.sv"
`include "../05_Sub/ALU.sv"
`include "../05_Sub/Shifter.sv"

`include "../04_Mem/Instr_Memory.sv"
`include "../04_Mem/Data_Memory.sv"
`include "../04_Mem/Reg_File.sv"

module MIPS(
    clk_i,
    rst_n
);

    // I/O port
    input clk_i;
    input rst_n;


// --------------------------------------------------------------------------------
//   Internal Signals
// --------------------------------------------------------------------------------

    // parameters
    parameter ra_reg = 5'd31;
    parameter zero_reg = 5'd0;

    // instruction decomposition
    wire [32-1:0] instr_o;

    wire [16-1:0] I_immediate;
    wire [26-1:0] J_immediate;

    wire [ 5-1:0] RSaddr;
    wire [ 5-1:0] RTaddr;
    wire [ 5-1:0] RDaddr;

    wire [ 6-1:0] opcode;
    wire [ 6-1:0] funct;

    // Program Counter
    wire [32-1:0] pc_in_i;
    wire [32-1:0] pc_out_o;
    wire [32-1:0] pc_four_o;
    wire [32-1:0] pc_addr_i;

    // Branch
    wire [32-1:0] pc_branch_o;
    wire [32-1:0] branch_mux_0_i;
    wire [32-1:0] branch_mux_1_i;
    wire [32-1:0] branch_mux_o;
    wire branch_mux_sel;

    // branch type
    wire type_0;
    wire type_1;
    wire type_2;
    wire type_3;

    // Jump
    wire [32-1:0] jump_mux_0_i;
    wire [32-1:0] jump_mux_1_i;
    wire [32-1:0] jump_mux_o;

    // Jump Register
    wire [32-1:0] jr_mux_0_i;
    wire [32-1:0] jr_mux_1_i;
    wire [32-1:0] jr_mux_o;


    // Register file 
    wire [32-1:0] RSdata;
    wire [32-1:0] RTdata;
    wire [32-1:0] WBdata;
    wire [ 5-1:0] WBaddr;

    // Decoder
    wire [2-1:0] BranchType;
    wire [2-1:0] MemtoReg;
    wire [2-1:0] ALUOp;
    wire [2-1:0] ALUSrc;
    wire [2-1:0] RegDst;

    wire RegWrite, RegWrite_o;
    wire MemWrite;
    wire MemRead;
    wire Branch;
    wire Jump;


    // ALU control
    wire [4-1:0] ALU_operation;
    wire [2-1:0] ALUop;
    wire shiftType;
    wire leftRight;
    wire jr_jump;
    wire FURslt;


    // Execution State
    wire [32-1:0] ALUsrc_mux_0_i;
    wire [32-1:0] ALUsrc_mux_1_i;
    wire [32-1:0] ALUsrc_mux_2_i;
    wire [32-1:0] ALUsrc_mux_o;
    wire [32-1:0] aluSrc1, aluSrc2;
    wire [32-1:0] ALU_result;
    wire ALU_overflow;
    wire ALU_zero;

    wire [32-1:0] shift_mux_0_i;
    wire [32-1:0] shift_mux_1_i;
    wire [32-1:0] shift_mux_o;
    wire [32-1:0] shift_result;
    wire [32-1:0] shamt;

    wire [32-1:0] ex_mux_0_i;
    wire [32-1:0] ex_mux_1_i;
    wire [32-1:0] ex_mux_o;


    // Data Memory
    wire [32-1:0] DMaddr_i;
    wire [32-1:0] DMdata_i;
    wire [32-1:0] DMdata_o;


    // Write Back
    wire [32-1:0] WBdata_mux_0_i;
    wire [32-1:0] WBdata_mux_1_i;
    wire [32-1:0] WBdata_mux_2_i;
    wire [32-1:0] WBdata_mux_o;

    wire [ 5-1:0] WBaddr_mux_0_i;
    wire [ 5-1:0] WBaddr_mux_1_i;
    wire [ 5-1:0] WBaddr_mux_2_i;
    wire [ 5-1:0] WBaddr_mux_o;


// --------------------------------------------------------------------------------
//   Program Counter / Branch / Jump
// --------------------------------------------------------------------------------

    Program_Counter PC (
        .clk_i              (clk_i),
        .rst_n              (rst_n),
        .pc_in_i            (pc_in_i),
        .pc_out_o           (pc_out_o)
    );


    // PC + 4 
    Adder Adder1 (
        .src1_i             (pc_out_o),
        .src2_i             (32'd4),
        .sum_o              (pc_four_o)
    );

    // branch adder
    Adder Adder2 (
        .src1_i             (pc_four_o),
        .src2_i             ({{14 {I_immediate[15]}}, I_immediate, 2'd0}),
        .sum_o              (pc_branch_o)
    );

    // branch type Mux
    assign type_0 =  ALU_zero;      // beq
    assign type_1 = ~ALU_zero;      // bne
    assign type_2 =  ALU_result;    // blt
    assign type_3 = ~ALU_result;    // bgez

    Mux4to1 #(
        .size(1)
    ) Mux_branchType (
        .data0_i            (type_0),
        .data1_i            (type_1),
        .data2_i            (type_2),
        .data3_i            (type_3),
        .select_i           (BranchType),
        .data_o             (branchType_o)
    );

    // branch mux
    assign branch_mux_0_i = pc_four_o;
    assign branch_mux_1_i = pc_branch_o;
    assign branch_mux_sel = branchType_o & Branch; 

    Mux2to1 #(
        .size(32)
    ) Mux_branch (
        .data0_i            (branch_mux_0_i),
        .data1_i            (branch_mux_1_i),
        .select_i           (branch_mux_sel),
        .data_o             (branch_mux_o)
    );


    // Jump Mux
    assign jump_mux_1_i = {pc_four_o[31:28], J_immediate, 2'd0};
    assign jump_mux_0_i = branch_mux_o;

    Mux2to1 #(
        .size(32)
    ) Mux_jump(
        .data0_i            (jump_mux_0_i),
        .data1_i            (jump_mux_1_i),
        .select_i           (Jump),
        .data_o             (jump_mux_o)
    );


    // Jump Reg Mux
    assign jr_mux_0_i = jump_mux_o;
    assign jr_mux_1_i = RSdata;

    Mux2to1 #(
        .size(32)
    ) Mux_jump_reg (
        .data0_i            (jr_mux_0_i),
        .data1_i            (jr_mux_1_i),
        .select_i           (jr_jump),
        .data_o             (jr_mux_o)
    );

    // back to PC
    assign pc_in_i = jr_mux_o;
    assign pc_addr_i = pc_out_o;

    Instr_Memory IM (
        .pc_addr_i          (pc_addr_i),
        .instr_o            (instr_o)
    );


    // instruction decomposition
    assign I_immediate = instr_o[15:0];
    assign J_immediate = instr_o[25:0];

    assign RSaddr = instr_o[25:21];
    assign RTaddr = instr_o[20:16];
    assign RDaddr = instr_o[15:11];

    assign opcode = instr_o[31:26];
    assign funct  = instr_o[5:0];



// --------------------------------------------------------------------------------
//   Control Signals (Decoder / ALU ctrl)
// --------------------------------------------------------------------------------


    assign RegWrite = RegWrite_o & !jr_jump;

    // Register file 
    Reg_File RF (
        .clk_i              (clk_i),
        .rst_n              (rst_n),
        .RSaddr_i           (RSaddr),
        .RTaddr_i           (RTaddr),
        .RDaddr_i           (WBaddr),
        .RDdata_i           (WBdata),
        .RegWrite_i         (RegWrite),
        .RSdata_o           (RSdata),
        .RTdata_o           (RTdata)
    );

    // Decoder
    Decoder Decoder (
        .instr_op_i         (opcode),
        .RegWrite_o         (RegWrite_o),
        .ALUOp_o            (ALUOp),
        .ALUSrc_o           (ALUSrc),
        .RegDst_o           (RegDst),
        .Jump_o             (Jump),
        .Branch_o           (Branch),
        .BranchType_o       (BranchType),
        .MemRead_o          (MemRead),
        .MemWrite_o         (MemWrite),
        .MemtoReg_o         (MemtoReg)
    );

    // ALU control 
    ALU_Ctrl AC (
        .funct_i            (funct),
        .ALUOp_i            (ALUOp),
        .ALU_operation_o    (ALU_operation),
        .FURslt_o           (FURslt),
        .leftRight_o        (leftRight),
        .shiftType_o        (shiftType),
        .jr_jump_o          (jr_jump)
    );


// --------------------------------------------------------------------------------
//   Execution Stage
// --------------------------------------------------------------------------------

    assign ALUsrc_mux_0_i = RTdata;
    assign ALUsrc_mux_1_i = {{16 {I_immediate[15]}}, I_immediate};
    assign ALUsrc_mux_2_i = 32'd0;

    Mux3to1 #(
        .size(32)
    ) ALU_src2Src (
        .data0_i            (ALUsrc_mux_0_i),
        .data1_i            (ALUsrc_mux_1_i),
        .data2_i            (ALUsrc_mux_2_i),
        .select_i           (ALUSrc),
        .data_o             (ALUsrc_mux_o)
    );

    assign aluSrc1 = RSdata;
    assign aluSrc2 = ALUsrc_mux_o;

    ALU ALU (
        .aluSrc1            (aluSrc1),
        .aluSrc2            (aluSrc2),
        .ALU_operation_i    (ALU_operation),
        .result             (ALU_result),
        .zero               (ALU_zero),
        .overflow           (ALU_overflow)
    );


    assign shift_mux_0_i = {27'd0, instr_o[10:6]};
    assign shift_mux_1_i = RSdata;
    
    Mux2to1 #(
        .size(32)
    ) Mux_Shift (
        .data0_i            (shift_mux_0_i),
        .data1_i            (shift_mux_1_i),
        .select_i           (shiftType),
        .data_o             (shift_mux_o)
    );

    assign shamt = shift_mux_o;

    Shifter shifter (
        .result             (shift_result),
        .leftRight          (leftRight),
        .shamt              (shamt),
        .sftSrc             (RTdata)
    );


    // Execution stage Mux
    assign ex_mux_0_i = ALU_result;
    assign ex_mux_1_i = shift_result;

    Mux2to1 #(
        .size(32)
    ) RDdata_Source (
        .data0_i            (ex_mux_0_i),
        .data1_i            (ex_mux_1_i),
        .select_i           (FURslt),
        .data_o             (ex_mux_o)
    );


// --------------------------------------------------------------------------------
//   Data Memory
// --------------------------------------------------------------------------------

    // Data Memory
    assign DMaddr_i = ex_mux_o;
    assign DMdata_i = RTdata;

    Data_Memory DM (
        .clk_i              (clk_i),
        .addr_i             (DMaddr_i),
        .data_i             (DMdata_i),
        .MemRead_i          (MemRead),
        .MemWrite_i         (MemWrite),
        .data_o             (DMdata_o)
    );


// --------------------------------------------------------------------------------
//   Write Back
// --------------------------------------------------------------------------------

    // reg_data write mux
    assign WBdata_mux_0_i = ex_mux_o;
    assign WBdata_mux_1_i = DMdata_o;
    assign WBdata_mux_2_i = pc_four_o;

    Mux3to1 #(
        .size(32)
    ) Mux_Write (
        .data0_i            (WBdata_mux_0_i),
        .data1_i            (WBdata_mux_1_i),
        .data2_i            (WBdata_mux_2_i),
        .select_i           (MemtoReg),
        .data_o             (WBdata_mux_o)
    );

    // Write back Address Mux
    assign WBaddr_mux_0_i = RTaddr;          // i type
    assign WBaddr_mux_1_i = RDaddr;          // r type 
    assign WBaddr_mux_2_i = ra_reg;          // jal: ra

    Mux3to1 #(
        .size(5)
    ) Mux_Write_Reg (
        .data0_i            (WBaddr_mux_0_i),
        .data1_i            (WBaddr_mux_1_i),
        .data2_i            (WBaddr_mux_2_i),
        .select_i           (RegDst),
        .data_o             (WBaddr_mux_o)
    );

    assign WBaddr = WBaddr_mux_o;
    assign WBdata = WBdata_mux_o;


endmodule



