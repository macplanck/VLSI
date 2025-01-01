module Mux2to1 (
    data0_i,
    data1_i,
    select_i,
    data_o
);

  parameter size = 0;

  //I/O ports
  input [size-1:0] data0_i;
  input [size-1:0] data1_i;
  input select_i;

  output [size-1:0] data_o;

  //Internal Signals
  wire [size-1:0] data_o;

  //Main function
  /*your code here*/

  assign data_o = (select_i) ? data1_i : data0_i; 

endmodule

module Mux3to1 (
    data0_i,
    data1_i,
    data2_i,
    select_i,
    data_o
);

  parameter size = 0;

  //I/O ports
  input [size-1:0] data0_i;
  input [size-1:0] data1_i;
  input [size-1:0] data2_i;
  input [2-1:0] select_i;

  output [size-1:0] data_o;

  //Internal Signals
  wire [size-1:0] data_o;

  //Main function
  /*your code here*/

  assign data_o = (select_i == 0) ? data0_i : 
                  (select_i == 1) ? data1_i : 
                  (select_i == 2) ? data2_i : 0;

endmodule

module Mux4to1 (
    data0_i,
    data1_i,
    data2_i,
    data3_i,
    select_i,
    data_o
);

  parameter size = 0;

  //I/O ports
  input [size-1:0] data0_i;
  input [size-1:0] data1_i;
  input [size-1:0] data2_i;
  input [size-1:0] data3_i;
  
  input [2-1:0] select_i;

  output [size-1:0] data_o;

  //Internal Signals
  wire [size-1:0] data_o;

  //Main function
  /*your code here*/
  assign data_o = (select_i == 0) ? data0_i : 
                  (select_i == 1) ? data1_i : 
                  (select_i == 2) ? data2_i : data3_i;

endmodule

