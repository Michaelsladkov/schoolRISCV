`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2023 18:37:35
// Design Name: 
// Module Name: sqrt_calculator
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


module sqrt_calculator(
    input [16:0] a_bi,
    input start_i,
    input clk_i,
    input rst_i,
    input [16:0] adder_out,
    output reg [8:0] y_bo,
    output reg [16:0] adder_inp1_bo,
    output reg [16:0] adder_inp2_bo,
    output busy_o
    );
    localparam IDLE = 2'b0;
    localparam WORK = 2'b1;
    localparam WAIT = 2'd2;
    localparam INITIAL_M = 1 << (18 - 2); 
    reg  [17:0] a;
    reg  [17:0]  m;
    reg  [17:0]  res;
    reg  [1:0] state;
    wire [17:0]  b;
    
    assign busy_o = state != IDLE;
    assign b = res | m;
    
    always @(posedge clk_i)
        if (rst_i) begin
            state <= IDLE;
            m <= INITIAL_M;
            res <= 0;
        end
        else begin
            case (state)
                IDLE:
                    if (start_i) begin
                        a <= {1'b0, a_bi};
                        m <= INITIAL_M;
                        res <= 0;
                        state <= WORK;
                        adder_inp1_bo <= 17'bz;
                        adder_inp2_bo <= 17'bz;
                    end
                WAIT:
                    begin
                        a <= adder_out;
                        state <= WORK;
                    end
                WORK:
                    begin
                        if (m == 18'b0) begin
                            y_bo <= res;
                            adder_inp1_bo <= 17'bz;
                            adder_inp2_bo <= 17'bz;
                            state <= IDLE;
                        end
                        else begin
                            res <= res >> 1;
                            if (a >= b[17:0]) begin
                                res <= (res >> 1) | m;
                                adder_inp1_bo <= a;
                                adder_inp2_bo <= ~b + 1;
                                state <= WAIT;
                            end
                            m <= m >> 2;
                        end
                    end
            endcase
        end
    
endmodule
