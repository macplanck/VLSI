module ALU_Ctrl (
    funct_i,
    ALUOp_i,
    ALU_operation_o,
    FURslt_o,
    leftRight_o,
    shiftType_o,
    jr_jump_o
);

  //I/O ports
  input [6-1:0] funct_i;
  input [2-1:0] ALUOp_i;

  output [4-1:0] ALU_operation_o;
  output FURslt_o;
  output leftRight_o;
  output shiftType_o;
  output jr_jump_o;

  //Internal Signals
  wire [4-1:0] ALU_operation_o;
  wire FURslt_o;
  wire leftRight_o;
  wire shiftType_o;
  wire jr_jump_o;

  //Main function
  /*your code here*/

  assign ALU_operation_o = (ALUOp_i == 'b10 & funct_i == 6'b011111) ? 4'b0000 :         // and    operation
                           (ALUOp_i == 'b10 & funct_i == 6'b101111) ? 4'b0001 :         // or     operation
                           (ALUOp_i == 'b10 & funct_i == 6'b010000) ? 4'b1100 :         // nor    operation
                           (ALUOp_i == 'b10 & funct_i == 6'b100011) ? 4'b0010 :         // add    operation
                           (ALUOp_i == 'b10 & funct_i == 6'b010011) ? 4'b0110 :         // sub    operation
                           (ALUOp_i == 'b00) ? 4'b0010 :
                           (ALUOp_i == 'b01) ? 4'b0110 : 4'b0111;

  assign FURslt_o = (ALUOp_i == 'b10 & funct_i == 6'b010010) |
                    (ALUOp_i == 'b10 & funct_i == 6'b100010) |
                    (ALUOp_i == 'b10 & funct_i == 6'b011000) |
                    (ALUOp_i == 'b10 & funct_i == 6'b101000) ;

  assign leftRight_o = (ALUOp_i == 'b10 & funct_i == 6'b010010) | (ALUOp_i == 'b10 & funct_i == 6'b011000);
  assign shiftType_o = (ALUOp_i == 'b10 & funct_i == 6'b011000) | (ALUOp_i == 'b10 & funct_i == 6'b101000);
  assign jr_jump_o   = (ALUOp_i == 'b10 & funct_i == 6'b000001);

endmodule
