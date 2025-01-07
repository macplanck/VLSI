`include "../05_Sub/Adder.sv"
`include "../05_Sub/ALU.sv"
`include "../05_Sub/ALUCtrl.sv"
`include "../05_Sub/Control.sv"
`include "../05_Sub/ImmGen.sv"
`include "../05_Sub/Mux.sv"
`include "../05_Sub/PC.sv"
`include "../05_Sub/ShiftLeftOne.sv"

`include "../04_Mem/Register.sv"
`include "../04_Mem/DataMemory.sv"
`include "../04_Mem/InstructionMemory.sv"


module GPT_MIPS (
    /* verilator lint_off UNUSEDSIGNAL */
    input clk,
    input start,
    output signed [31:0] r [0:31]
);

// When input start is zero, cpu should reset
// When input start is high, cpu start running

// TODO: connect wire to realize SingleCycleCPU
// The following provides simple template,
// you can modify it as you wish except I/O pin and register module

// control signals
reg branch, memRead, memWrite, ALUSrc, regWrite, thepc;
reg [1:0] memtoReg;
reg [2:0] ALUOp;

// pc signals
reg [31:0] PC, PC_4, PC_imm, tempPC, nextPC;

// instructions
reg [31:0] inst;

// register I/O
reg [31:0] MUXchosentoWriteData; // input, the output of MUX_dataMemory
reg [31:0] readData1, readData2; // outputs

// mux between register and ALU
reg [31:0] MUXChosentoALU; // the output of it

// ALU control
reg [3:0] ALUCtl;

// ALU output
reg zero; // has to do with branch

// Imm Gen output
reg signed [31:0] imm, shiftone;

// data memory I/O
reg [31:0] ALUtoAddress; // inputs, also the output of ALU
reg [31:0] readData;  // output

PC m_PC(
    .clk(clk),
    .rst(start),
    .pc_i(nextPC),
    .pc_o(PC)
);

Adder m_Adder_1(
    .a(PC),
    .b(4),
    .sum(PC_4)
);

InstructionMemory m_InstMem(
    .readAddr(PC),
    .inst(inst)
);

Control m_Control(
    .opcode(inst[6:0]),
    .branch(branch),
    .memRead(memRead),
    .memtoReg(memtoReg),
    .ALUOp(ALUOp),
    .memWrite(memWrite),
    .ALUSrc(ALUSrc),
    .regWrite(regWrite),
    .thepc(thepc)
);

// For Student: 
// Do not change the Register instance name!
// Or you will fail validation.

Register m_Register(
    .clk(clk),
    .rst(start),
    .regWrite(regWrite),
    .readReg1(inst[19:15]),
    .readReg2(inst[24:20]),
    .writeReg(inst[11:7]),
    .writeData(MUXchosentoWriteData),
    .readData1(readData1),
    .readData2(readData2)
);

// ======= for validation ======= 
// == Dont change this section ==
// assign r = m_Register.regs;
// ======= for vaildation =======

ImmGen m_ImmGen(
    .inst(inst),
    .imm(imm)
);

ShiftLeftOne m_ShiftLeftOne(
    .i(imm),
    .o(shiftone)
);

Adder m_Adder_2(
    .a(PC),
    .b(imm),
    .sum(PC_imm)
);

Mux2to1 #(.size(32)) m_Mux_PC(
    .sel(branch & zero),
    .s0(PC_4),
    .s1(PC_imm),
    .out(tempPC)
);

Mux2to1 #(.size(32)) m_Mux_ALU(
    .sel(ALUSrc),
    .s0(readData2),
    .s1(imm),
    .out(MUXChosentoALU)
);

ALUCtrl m_ALUCtrl(
    .ALUOp(ALUOp),
    .funct7(inst[30]),
    .funct3(inst[14:12]),
    .ALUCtl(ALUCtl)
);

ALU m_ALU(
    .ALUctl(ALUCtl),
    .A(readData1),
    .B(MUXChosentoALU),
    .ALUOut(ALUtoAddress),
    .zero(zero)
);

assign nextPC = (thepc) ? ALUtoAddress : tempPC;

DataMemory m_DataMemory(
    .rst(start),
    .clk(clk),
    .memWrite(memWrite),
    .memRead(memRead),
    .address(ALUtoAddress),
    .writeData(readData2),
    .readData(readData)
);

Mux4to1 #(.size(32)) m_Mux_WriteData(
    .sel(memtoReg),
    .s0(ALUtoAddress),
    .s1(readData),
    .s2(PC_4),
    .s3(0),
    .out(MUXchosentoWriteData)
);

endmodule
