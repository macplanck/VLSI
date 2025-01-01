module Decoder (
    instr_op_i,
    RegWrite_o,
    ALUOp_o,
    ALUSrc_o,
    RegDst_o,
    Jump_o,
    Branch_o,
    BranchType_o,
    MemRead_o,
    MemWrite_o,
    MemtoReg_o
);

  //I/O ports
  input [6-1:0] instr_op_i;

  output RegWrite_o;
  output [2-1:0] ALUOp_o;
  output [2-1:0] ALUSrc_o;
  output [2-1:0] RegDst_o;
  output Jump_o;
  output Branch_o;
  output [2-1:0] BranchType_o;
  output MemRead_o;
  output MemWrite_o;
  output [2-1:0] MemtoReg_o;

  //Internal Signals
  wire RegWrite_o;
  wire [2-1:0] ALUOp_o;
  wire [2-1:0] ALUSrc_o;
  wire [2-1:0] RegDst_o;
  wire Jump_o;
  wire Branch_o;
  wire [2-1:0] BranchType_o;
  wire MemRead_o;
  wire MemWrite_o;
  wire [2-1:0] MemtoReg_o;

  //Main function
  /*your code here*/


  // Q1: Why there's 3 bit of ALU op
  // Q2: jr mux has gone ?

  assign RegWrite_o = (instr_op_i == 6'b000000) |                                       // R type
                      (instr_op_i == 6'b010011) |                                       // addi 
                      (instr_op_i == 6'b011000) |                                       // lw
                      (instr_op_i == 6'b001111) ;                                       // jal

  // assign ALUSrc_o = (instr_op_i == 6'b011000 | instr_op_i == 6'b101000 | instr_op_i == 6'b010011) ? 2'b00 :
  //                   (instr_op_i == 6'b000000) ? 2'b10 : 2'b01;

  assign ALUOp_o  = (instr_op_i == 6'b011000 | instr_op_i == 6'b101000 | instr_op_i == 6'b010011) ? 2'b00 :               // lw sw addi
                    (instr_op_i == 6'b011100 | instr_op_i == 6'b011110)                           ? 2'b11 :               // blt bgez
                    (instr_op_i == 6'b000000)                                                     ? 2'b10 : 2'b01 ;       // Arithmetic 


  // assign ALUSrc_o = (instr_op_i == 6'b000000) |     // R-type
  //                   (instr_op_i == 6'b011001) |     // beq
  //                   (instr_op_i == 6'b011010) ;     // bne

  assign ALUSrc_o = (instr_op_i == 6'b011000 | instr_op_i == 6'b101000 | instr_op_i == 6'b010011) ? 2'b01 :
                    (instr_op_i == 6'b011101 | instr_op_i == 6'b011110) ? 2'b10 : 2'b00;

  // assign RegDst_o = (instr_op_i == 6'b011000) ? 0 :
  //                   (instr_op_i == 6'b011000) ? 2 : 1;

  assign RegDst_o = (instr_op_i == 6'b000000) ? 1 :
                    (instr_op_i == 6'b001111) ? 2 : 0;

  assign Jump_o = (instr_op_i == 6'b001111) | 
                  (instr_op_i == 6'b001100) ;

  assign Branch_o = (instr_op_i == 6'b011001) | (instr_op_i == 6'b011010) | (instr_op_i == 6'b011100) | (instr_op_i == 6'b011101) | (instr_op_i == 6'b011110);     // beq

  assign BranchType_o = (instr_op_i == 6'b011001) ? 0 :
                        (instr_op_i == 6'b011100) ? 2 :
                        (instr_op_i == 6'b011110) ? 3 : 1;

  assign MemRead_o = (instr_op_i == 6'b011000);

  assign MemWrite_o = (instr_op_i == 6'b101000);

  assign MemtoReg_o = (instr_op_i == 6'b011000) ? 1 :
                      (instr_op_i == 6'b001111) ? 2 : 0;


endmodule
