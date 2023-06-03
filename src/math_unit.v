`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.04.2023 13:07:56
// Design Name: 
// Module Name: math_unit
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


module math_unit(
    input [7:0] a_bi,
    input [7:0] b_bi,
    input start_i,
    input clk_i,
    input rst_i,
    output reg [8:0] y_bo,
    output busy_o
    );
    localparam IDLE = 3'd0;
    localparam START_MUL = 3'd1;
    localparam CALCULATING_SQR = 3'd2;
    localparam WRITE_SQR = 3'd3;
    localparam CALCULATING_SUM = 3'd4;
    localparam START_SQRT = 3'd5;
    localparam CALCULATING_SQRT = 3'd6;
    localparam WRITE_RESULT = 3'd7;
    
    reg [7:0]  a;
    reg [7:0]  b;
    wire start_mul;
    wire start_sqrt;
    wire mul1_busy;
    wire mul2_busy;
    wire rooter_busy;
    wire [16:0] adder_out;
    wire [8:0] res;
    reg [16:0] sum_of_sqr;
    reg [2:0]  state;
    
    wire [15:0] a_sqr;
    wire [15:0] b_sqr;
    
    wire [16:0] adder_inp1;
    wire [16:0] adder_inp2;
    wire [16:0] rooter2adder1;
    wire [16:0] rooter2adder2;
    
    
    
    adder adder(
        .a_bi(adder_inp1),
        .b_bi(adder_inp2),
        .y_bo(adder_out)
    );
    multiplier mul1(
        .a_bi(a),
        .b_bi(a),
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_mul),
        .y_bo(a_sqr),
        .busy_o(mul1_busy)
    );
    multiplier mul2(
        .a_bi(b),
        .b_bi(b),
        .clk_i(clk_i),
        .rst_i(rst_i),
        .start_i(start_mul),
        .y_bo(b_sqr),
        .busy_o(mul2_busy)
    );
    sqrt_calculator rooter(
        .a_bi(sum_of_sqr),
        .start_i(start_sqrt),
        .clk_i(clk_i),
        .rst_i(rst_i),
        .adder_out(adder_out),
        .y_bo(res),
        .adder_inp1_bo(rooter2adder1),
        .adder_inp2_bo(rooter2adder2),
        .busy_o(rooter_busy)
    );
    
    
    assign busy_o = state != IDLE;
    assign start_mul = state == START_MUL;
    assign start_sqrt = state == START_SQRT;
    assign adder_inp1 = ((state == WRITE_SQR | state == CALCULATING_SUM) ? a_sqr : rooter2adder1);
    assign adder_inp2 = ((state == WRITE_SQR | state == CALCULATING_SUM) ? b_sqr : rooter2adder2);
    
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            state <= IDLE;
            a <= 8'b0;
            b <= 8'b0;
            sum_of_sqr <= 16'b0;
            y_bo <= 8'b0;
        end
        else begin
            case (state)
                IDLE:
                    if (start_i) begin
                        a <= a_bi;
                        b <= b_bi;
                        sum_of_sqr <= 16'b0;
                        y_bo <= 8'b0;
                        state <= START_MUL;
                    end
                START_MUL:
                    begin
                        state <= CALCULATING_SQR;
                    end
                CALCULATING_SQR:
                    if ((~mul1_busy)&(~mul2_busy)) begin
                        state <= WRITE_SQR;
                    end
                WRITE_SQR:
                    begin
                        state <= CALCULATING_SUM;
                    end
                CALCULATING_SUM:
                    begin
                        sum_of_sqr <= adder_out;
                        state <= START_SQRT;
                    end
                START_SQRT:
                    begin
                        state <= CALCULATING_SQRT;
                    end
                CALCULATING_SQRT:
                    if (~rooter_busy) begin
                        state <= WRITE_RESULT;
                    end
                WRITE_RESULT:
                    begin
                        state <= IDLE;
                        y_bo <= res;
                    end
            endcase
        end
    end
endmodule
