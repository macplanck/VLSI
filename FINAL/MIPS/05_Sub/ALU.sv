module ALU (
    aluSrc1,
    aluSrc2,
    ALU_operation_i,
    result,
    zero,
    overflow
);

  //I/O ports
  input [32-1:0] aluSrc1;
  input [32-1:0] aluSrc2;
  input [4-1:0] ALU_operation_i;

  output [32-1:0] result;
  output zero;
  output overflow;

  //Internal Signals
  wire [32-1:0] result;
  wire zero;
  wire overflow;

  wire carry_1, carry_2;
  wire [32-1:0] in_A, in_B, add_1;

  //Main function
  assign in_A = (ALU_operation_i[3]) ? ~aluSrc1 : aluSrc1;
  assign in_B = (ALU_operation_i[2]) ? ~aluSrc2 : aluSrc2;

  assign {carry_1, add_1[30:0]} = in_A[30:0] + in_B[30:0] + ALU_operation_i[2];
  assign {carry_2, add_1[31  ]} = in_A[31  ] + in_B[31  ] + carry_1;
  assign overflow = carry_1 ^ carry_2; 

  assign result = (ALU_operation_i[1:0] == 0) ? in_A & in_B : 
                  (ALU_operation_i[1:0] == 1) ? in_A | in_B : 
                  (ALU_operation_i[1:0] == 2) ? add_1  :  add_1[31] & !overflow | carry_2 & overflow;
                  // (ALU_operation_i[1:0] == 2) ? add_1  :  (overflow) ? {31'd0, ~add_1[31]} : {31'd0, add_1[31]};


  assign zero = result == 0;

endmodule
