module Mux2to1 #(
    parameter size = 32
) 
(
    input sel,
    input signed [size-1:0] s0,
    input signed [size-1:0] s1,
    output signed [size-1:0] out
);
    // TODO: implement your 2to1 multiplexer here
    assign out = (sel == 1'b0) ? s0 : s1;
    
endmodule


module Mux4to1 #(
    parameter size = 32
) 
(
    /* verilator lint_off CASEINCOMPLETE */
    input [1:0] sel,
    input signed [size-1:0] s0,
    input signed [size-1:0] s1,
    input signed [size-1:0] s2,
    input signed [size-1:0] s3,
    output reg signed [size-1:0] out
);
    // TODO: implement your 2to1 multiplexer here
    reg [size-1:0] w;
    always @(*) begin
        case (sel)
            2'b00: w = s0;
            2'b01: w = s1;
            2'b10: w = s2;
            2'b11: w = s3;
        endcase
    end
    assign out = w;
    
endmodule

