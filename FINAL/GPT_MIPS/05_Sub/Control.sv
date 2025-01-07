module Control (
    input [6:0] opcode,
    output reg branch,
    output reg memRead,
    output reg [1:0] memtoReg,
    output reg [2:0] ALUOp,
    output reg memWrite,
    output reg ALUSrc,
    output reg regWrite,
    output reg thepc
);
    // TODO: implement your Control here
    // Hint: follow the Architecture (figure in spec) to set output signal
    always @(opcode) begin
        case (opcode)
            // B-Type: beq
            7'b1100011: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b10000010000;
            // I-Type: lw
            7'b0000011: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b01010000110;
            // S-Type: sw
            7'b0100011: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b00000001100; 
            // I-Type: addi, slti, ori, andi
            7'b0010011: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b00000110110;
            // R-Type: add, sub, and, or, slt
            7'b0110011: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b00000100010;
            // jal
            7'b1101111: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b10101000110;
            // jalr
            7'b1100111: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b00101000111;
            // invalid opcode
            default: { branch, memRead, memtoReg, ALUOp, memWrite, ALUSrc, regWrite, thepc } = 11'b0;   
        endcase
    end

endmodule
