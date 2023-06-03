`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.03.2023 12:42:11
// Design Name: 
// Module Name: multiplier
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


module multiplier(
    input [7:0] a_bi,
    input [7:0] b_bi,
    input rst_i,
    input clk_i,
    input start_i,
    output reg [15:0] y_bo,
    output busy_o
    );
    localparam IDLE = 1'b0;
    localparam WORK = 1'b1;
    reg  [7:0]  a, b;
    reg         state;
    reg  [15:0] part_res;
    reg  [3:0]  ctr;
    
    wire        end_step;
    wire [15:0] part_sum;
    wire [15:0] shifted_part_sum;
    
    assign busy_o           = state;
    assign end_step         = (ctr == 4'h8);
    
    assign part_sum         = {8'b0, a} & {16{b[ctr]}};
    assign shifted_part_sum = part_sum << ctr;
    
    always @(posedge clk_i)
        if (rst_i) begin
            ctr      <= 3'b0;
            part_res <= 16'b0;
            state    <= IDLE;
            y_bo     <= 16'h0;
        end else begin
            case (state)
                IDLE:
                    if (start_i) begin
                        state    <= WORK;
                        a        <= a_bi;
                        b        <= b_bi;
                        ctr      <= 8'b0;
                        part_res <= 16'b0;
                    end
                WORK:
                    begin
                       
                        if (end_step) begin
                            y_bo  <= part_res;
                            state <= IDLE;
                        end else begin
                            part_res <= part_res + shifted_part_sum;
                            ctr      <= ctr + 1;
                        end
                    end
            endcase
        end     
endmodule
