module MIPS_CPU (
    input clk,
    input reset,
    output [31:0] PC_out
);

    // Program Counter (PC)
    reg [31:0] PC;
    assign PC_out = PC;

    // Instruction Memory
    wire [31:0] instruction;
    reg [31:0] instruction_memory [0:255];

    // Register File
    reg [31:0] register_file [0:31];
    wire [31:0] read_data1, read_data2;
    reg [31:0] write_data;
    wire [4:0] read_register1, read_register2, write_register;

    // Control Signals
    wire RegDst, Branch, MemRead, MemtoReg, MemWrite, ALUSrc, RegWrite, Jump, shiftType, jr_jump;
    wire [1:0] ALUOp;
    wire [3:0] FURslt;

    // ALU Control
    wire [3:0] ALU_control;

    // Data Memory
    reg [31:0] data_memory [0:255];
    wire [31:0] memory_read_data;

    // Sign Extension
    wire [31:0] sign_extended_immediate;

    // ALU Inputs and Outputs
    wire [31:0] ALU_input2;
    wire [31:0] ALU_result;
    wire ALU_zero;

    // PC Adder
    wire [31:0] PC_next, PC_branch;
    wire branch_taken;

    // Instruction Fetch
    assign instruction = instruction_memory[PC >> 2];

    // Decode
    assign read_register1 = instruction[25:21];
    assign read_register2 = instruction[20:16];
    assign write_register = RegDst ? instruction[15:11] : instruction[20:16];

    // Register File Read
    assign read_data1 = register_file[read_register1];
    assign read_data2 = register_file[read_register2];

    // Sign Extend Immediate
    assign sign_extended_immediate = {{16{instruction[15]}}, instruction[15:0]};

    // ALU Input Selection
    assign ALU_input2 = ALUSrc ? sign_extended_immediate : read_data2;

    // Branch Taken
    assign branch_taken = Branch & ALU_zero;

    // PC Branch
    assign PC_branch = PC + 4 + (sign_extended_immediate << 2);

    // PC Next
    assign PC_next = jr_jump ? read_data1 : (branch_taken ? PC_branch : (Jump ? {PC[31:28], instruction[25:0], 2'b00} : PC + 4));

    // Data Memory Read
    assign memory_read_data = data_memory[ALU_result >> 2];

    // Control Unit
    Control_Unit CU (
        .opcode(instruction[31:26]),
        .func(instruction[5:0]),
        .RegDst(RegDst),
        .Branch(Branch),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .ALUOp(ALUOp),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .Jump(Jump),
        .shiftType(shiftType),
        .jr_jump(jr_jump),
        .FURslt(FURslt)
    );

    // ALU Control Logic
    ALU_Control ALUControl (
        .ALUOp(ALUOp),
        .FuncCode(instruction[5:0]),
        .ALUControl(ALU_control)
    );

    // ALU Module
    ALU ALU (
        .input1(read_data1),
        .input2(ALU_input2),
        .control(ALU_control),
        .result(ALU_result),
        .zero(ALU_zero)
    );

    // Write Back
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            PC <= 0;
        end else begin
            PC <= PC_next;
            if (RegWrite) begin
                register_file[write_register] <= MemtoReg ? memory_read_data : ALU_result;
            end
            if (MemWrite) begin
                data_memory[ALU_result >> 2] <= read_data2;
            end
        end
    end

endmodule

module ALU (
    input [31:0] input1,
    input [31:0] input2,
    input [3:0] control,
    output reg [31:0] result,
    output zero
);
    always @(*) begin
        case (control)
            4'b0010: result = input1 + input2;  // ADD
            4'b0110: result = input1 - input2;  // SUB
            4'b0000: result = input1 & input2;  // AND
            4'b0001: result = input1 | input2;  // OR
            4'b0111: result = (input1 < input2) ? 1 : 0;  // SLT
            default: result = 0;
        endcase
    end
    assign zero = (result == 0);
endmodule

module ALU_Control (
    input [1:0] ALUOp,
    input [5:0] FuncCode,
    output reg [3:0] ALUControl
);
    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0010;  // LW/SW (ADD)
            2'b01: ALUControl = 4'b0110;  // BEQ (SUB)
            2'b10: begin
                case (FuncCode)
                    6'b100000: ALUControl = 4'b0010;  // ADD
                    6'b100010: ALUControl = 4'b0110;  // SUB
                    6'b100100: ALUControl = 4'b0000;  // AND
                    6'b100101: ALUControl = 4'b0001;  // OR
                    6'b101010: ALUControl = 4'b0111;  // SLT
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule

module Control_Unit (
    input [5:0] opcode,
    input [5:0] func,
    output reg RegDst,
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg [1:0] ALUOp,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,
    output reg Jump,
    output reg shiftType,
    output reg jr_jump,
    output reg [3:0] FURslt
);
    always @(*) begin
        case (opcode)
            6'b000000: begin  // R-type
                RegDst = 1; Branch = 0; MemRead = 0; MemtoReg = 0;
                ALUOp = 2'b10; MemWrite = 0; ALUSrc = 0; RegWrite = 1;
                Jump = 0; shiftType = 0; jr_jump = (func == 6'b001000) ? 1 : 0;
                FURslt = 4'b0000;
            end
            6'b100011: begin  // lw
                RegDst = 0; Branch = 0; MemRead = 1; MemtoReg = 1;
                ALUOp = 2'b00; MemWrite = 0; ALUSrc = 1; RegWrite = 1;
                Jump = 0; shiftType = 0; jr_jump = 0;
                FURslt = 4'b0010;
            end
            6'b101011: begin  // sw
                RegDst = 0; Branch = 0; MemRead = 0; MemtoReg = 0;
                ALUOp = 2'b00; MemWrite = 1; ALUSrc = 1; RegWrite = 0;
                Jump = 0; shiftType = 0; jr_jump = 0;
                FURslt = 4'b0010;
            end
            6'b000100: begin  // beq
                RegDst = 0; Branch = 1; MemRead = 0; MemtoReg = 0;
                ALUOp = 2'b01; MemWrite = 0; ALUSrc = 0; RegWrite = 0;
                Jump = 0; shiftType = 0; jr_jump = 0;
                FURslt = 4'b0000;
            end
            6'b000010: begin  // jump
                RegDst = 0; Branch = 0; MemRead = 0; MemtoReg = 0;
                ALUOp = 2'b00; MemWrite = 0; ALUSrc = 0; RegWrite = 0;
                Jump = 1; shiftType = 0; jr_jump = 0;
                FURslt = 4'b0000;
            end
            default: begin
                RegDst = 0; Branch = 0; MemRead = 0; MemtoReg = 0;
                ALUOp = 2'b00; MemWrite = 0; ALUSrc = 0; RegWrite = 0;
                Jump = 0; shiftType = 0; jr_jump = 0;
                FURslt = 4'b0000;
            end
        endcase
    end
endmodule
