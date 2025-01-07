module ALU (
    input [3:0] ALUctl,
    input signed [31:0] A,B,
    output reg signed [31:0] ALUOut,
    output reg zero
);
    // ALU has two operand, it execute different operator based on ALUctl wire 
    // output zero is for determining taking branch or not (or you can change the design as you wish)

    // TODO: implement your ALU here
    // Hint: you can use operator to implement
    // assign zero = (A == B);
    always @(*) begin
        case (ALUctl)
            // AND
            4'b0000: begin
                ALUOut = A & B;
                zero = (A == B);
            end
            // OR
            4'b0001: begin
                ALUOut = A | B;
                zero = (A == B);
            end 
            // add
            4'b0010: begin
                ALUOut = A + B;
                zero = (A == B);
            end 
            // sub
            4'b0110: begin
                ALUOut = A - B;
                zero = (A == B);
            end
            // less than
            4'b0111: begin
                ALUOut = (A < B) ? 32'b1 : 32'b0;
                zero = (A == B);
            end 
            // bne
            4'b1011: begin
                ALUOut = A + B;
                zero = (A != B);
            end
            // blt
            4'b1100: begin
                ALUOut = A + B;
                zero = (A < B);
            end
            // bge
            4'b1101: begin
                ALUOut = A + B;
                zero = (A >= B);
            end 
            // jal
            4'b1110: begin
                ALUOut = A + B;
                zero = 1;
            end
            // invalid ALUctl
            default: begin
                ALUOut = 32'b0;
                zero = 0;
            end
        endcase
    end

endmodule
