`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2023 03:06:59
// Design Name: 
// Module Name: adder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module adder(
    input [16:0] a_bi,
    input [16:0] b_bi,
    output [16:0] y_bo,
    output c_o
    );
    
    assign y_bo = a_bi + b_bi;
    assign c_o = a_bi[16] & b_bi[16];
    
endmodule
