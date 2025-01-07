module ALUCtrl (
    /* verilator lint_off CASEINCOMPLETE */
    input [2:0] ALUOp,
    input funct7,
    input [2:0] funct3,
    output reg [3:0] ALUCtl
);
    // TODO: implement your ALU control here
    // For testbench verifying, Do not modify input and output pin
    // Hint: using ALUOp, funct7, funct3 to select exact operation
    always @(*) begin
        case (ALUOp)
            // lw, sw
            3'b000: ALUCtl = 4'b0010;
            // beq
            3'b001: begin
                case (funct3)
                    // beq
                    3'b000: ALUCtl = 4'b0110;
                    // bne
                    3'b001: ALUCtl = 4'b1011;
                    // blt
                    3'b100: ALUCtl = 4'b1100;
                    // bge 
                    3'b101: ALUCtl = 4'b1101;
                    // invalid funct3
                    default: ALUCtl = 4'b1111;
                endcase
            end
            // R-type & addi, andi, ori, slti
            3'b010: begin
                case (funct3)
                    // add / sub
                    3'b000: ALUCtl = (funct7 == 1'b0) ? 4'b0010 : 4'b0110;
                    // less than
                    3'b010: ALUCtl = 4'b0111;
                    // OR
                    3'b110: ALUCtl = 4'b0001;
                    // AND
                    3'b111: ALUCtl = 4'b0000;
                    // invalid funct3
                    default: ALUCtl = 4'b1111;
                endcase
            end
            3'b011: begin
                case (funct3)
                    // add
                    3'b000: ALUCtl = 4'b0010;
                    // less than
                    3'b010: ALUCtl = 4'b0111;
                    // OR
                    3'b110: ALUCtl = 4'b0001;
                    // AND
                    3'b111: ALUCtl = 4'b0000;
                    // invalid funct3
                    default: ALUCtl = 4'b1111;
                endcase
            end
            // jal, jalr
            3'b100: ALUCtl = 4'b1110; // add
        endcase
    end

endmodule
