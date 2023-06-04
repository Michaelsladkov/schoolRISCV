/*
 * schoolRISCV - small RISC-V CPU 
 *
 * originally based on Sarah L. Harris MIPS CPU 
 *                   & schoolMIPS project
 * 
 * Copyright(c) 2017-2020 Stanislav Zhelnio 
 *                        Aleksandr Romanov 
 */ 

`include "sr_cpu.vh"

module sr_cpu
(
    input           clk,        // clock
    input           rst_n,      // reset
    input   [ 4:0]  regAddr,    // debug access reg address
    output  [31:0]  regData,    // debug access reg data
    output  [31:0]  imAddr,     // instruction memory address
    input   [31:0]  imData      // instruction memory data
);
    //control wires
    wire        aluZero;
    wire        aluUnsignedOF;
    wire  [1:0] pcSrc;
    wire        regWrite;
    wire        aluSrc;
    wire  [1:0] wdSrc;
    wire  [2:0] aluControl;

    //instruction decode wires
    wire [ 6:0] cmdOp;
    wire [ 4:0] rd;
    wire [ 2:0] cmdF3;
    wire [ 4:0] rs1;
    wire [ 4:0] rs2;
    wire [ 6:0] cmdF7;
    wire [31:0] immI;
    wire [31:0] immB;
    wire [31:0] immU;

    //program counter
    wire [31:0] pc;
    wire [31:0] pcBranch = pc + immB;
    wire [31:0] pcPlus4  = pc + 4;
    wire [31:0] pcNext   = pcSrc[1] ? pc : (pcSrc[0] ? pcBranch : pcPlus4);
    sm_register r_pc(clk ,rst_n, pcNext, pc);

    //program memory access
    assign imAddr = pc >> 2;
    wire [31:0] instr = imData;

    //instruction decode
    sr_decode id (
        .instr      ( instr        ),
        .cmdOp      ( cmdOp        ),
        .rd         ( rd           ),
        .cmdF3      ( cmdF3        ),
        .rs1        ( rs1          ),
        .rs2        ( rs2          ),
        .cmdF7      ( cmdF7        ),
        .immI       ( immI         ),
        .immB       ( immB         ),
        .immU       ( immU         ) 
    );

    //register file
    wire [31:0] rd0;
    wire [31:0] rd1;
    wire [31:0] rd2;
    wire [31:0] wd3;

    sm_register_file rf (
        .clk        ( clk          ),
        .a0         ( regAddr      ),
        .a1         ( rs1          ),
        .a2         ( rs2          ),
        .a3         ( rd           ),
        .rd0        ( rd0          ),
        .rd1        ( rd1          ),
        .rd2        ( rd2          ),
        .wd3        ( wd3          ),
        .we3        ( regWrite     )
    );

    //debug register access
    assign regData = (regAddr != 0) ? rd0 : pc;

    //alu
    wire [31:0] srcB = aluSrc ? immI : rd2;
    wire [31:0] aluResult;

    sr_alu alu (
        .srcA       ( rd1          ),
        .srcB       ( srcB         ),
        .oper       ( aluControl   ),
        .zero       ( aluZero      ),
        .unsigned_of( aluUnsignedOF),
        .result     ( aluResult    ) 
    );

    assign wd3 = wdSrc[1] ? mathUnitResult : (wdSrc[0] ? immU : aluResult);

    //control
    sr_control sm_control (
        .clk            ( clk            ),
        .cmdOp          ( cmdOp          ),
        .cmdF3          ( cmdF3          ),
        .cmdF7          ( cmdF7          ),
        .mathUnitBusy   ( mathUnitBusy   ),
        .aluZero        ( aluZero        ),
        .aluUnsignedOF  ( aluUnsignedOF  ),
        .pcSrc          ( pcSrc          ),
        .regWrite       ( regWrite       ),
        .aluSrc         ( aluSrc         ),
        .wdSrc          ( wdSrc          ),
        .aluControl     ( aluControl     ),
        .start_calc     ( start_calc     )
    );
    wire start_calc;
    wire mathUnitBusy;
    wire [8:0] mathUnitResult;
    
    math_unit math_unit(
        .clk_i      ( clk            ),
        .rst_i      ( ~rst_n         ),
        .start_i    ( start_calc     ),
        .a_bi       ( rd1[7:0]       ),
        .b_bi       ( rd2[7:0]       ),
        .y_bo       ( mathUnitResult ),
        .busy_o     ( mathUnitBusy   )
    );

endmodule

module sr_decode
(
    input      [31:0] instr,
    output     [ 6:0] cmdOp,
    output     [ 4:0] rd,
    output     [ 2:0] cmdF3,
    output     [ 4:0] rs1,
    output     [ 4:0] rs2,
    output     [ 6:0] cmdF7,
    output reg [31:0] immI,
    output reg [31:0] immB,
    output reg [31:0] immU 
);
    assign cmdOp = instr[ 6: 0];
    assign rd    = instr[11: 7];
    assign cmdF3 = instr[14:12];
    assign rs1   = instr[19:15];
    assign rs2   = instr[24:20];
    assign cmdF7 = instr[31:25];

    // I-immediate
    always @ (*) begin
        immI[10: 0] = instr[30:20];
        immI[31:11] = { 21 {instr[31]} };
    end

    // B-immediate
    always @ (*) begin
        immB[    0] = 1'b0;
        immB[ 4: 1] = instr[11:8];
        immB[10: 5] = instr[30:25];
        immB[   11] = instr[7];
        immB[31:12] = { 20 {instr[31]} };
    end

    // U-immediate
    always @ (*) begin
        immU[11: 0] = 12'b0;
        immU[31:12] = instr[31:12];
    end

endmodule

module sr_control
(
    input            clk,
    input     [ 6:0] cmdOp,
    input     [ 2:0] cmdF3,
    input     [ 6:0] cmdF7,
    input            aluZero,
    input            aluUnsignedOF,
    input            mathUnitBusy,
    output    [ 1:0] pcSrc, 
    output reg       regWrite, 
    output reg       aluSrc,
    output reg [1:0]     wdSrc,
    output reg [2:0] aluControl,
    output reg       start_calc
);
    reg          branch;
    reg          condZero;
    reg          condUnsignedOF;
    reg          mathUnitBusyPrev;
    reg          branchByZero;
    reg          branchByOf;
    assign pcSrc[0] = branch & ((branchByZero && aluZero == condZero) || (branchByOf && aluUnsignedOF == condUnsignedOF));
    assign pcSrc[1] = mathUnitBusy || start_calc;

    always @ (*) begin
        branch         = 1'b0;
        condZero       = 1'b0;
        condUnsignedOF = 1'b0;
        branchByZero   = 1'b0;
        branchByOf     = 1'b0;
        regWrite       = 1'b0;
        aluSrc         = 1'b0;
        wdSrc          = mathUnitBusyPrev ? 2'b10 : 2'b0;
        start_calc     = 1'b0;
        aluControl     = `ALU_ADD;

        casez( {cmdF7, cmdF3, cmdOp} )
            { `RVF7_ADD,  `RVF3_ADD,  `RVOP_ADD  } : begin regWrite = 1'b1; aluControl = `ALU_ADD;  end
            { `RVF7_OR,   `RVF3_OR,   `RVOP_OR   } : begin regWrite = 1'b1; aluControl = `ALU_OR;   end
            { `RVF7_SRL,  `RVF3_SRL,  `RVOP_SRL  } : begin regWrite = 1'b1; aluControl = `ALU_SRL;  end
            { `RVF7_SLTU, `RVF3_SLTU, `RVOP_SLTU } : begin regWrite = 1'b1; aluControl = `ALU_SLTU; end
            { `RVF7_SUB,  `RVF3_SUB,  `RVOP_SUB  } : begin regWrite = 1'b1; aluControl = `ALU_SUB;  end
            { `RVF7_HYP,  `RVF3_HYP,  `RVOP_HYP  } : begin regWrite = 1'b1; start_calc = mathUnitBusyPrev ? 1'b0 : 1'b1; wdSrc = 2'b10; end 

            { `RVF7_ANY,  `RVF3_ADDI, `RVOP_ADDI } : begin regWrite = 1'b1; aluSrc = 1'b1; aluControl = `ALU_ADD; end
            { `RVF7_ANY,  `RVF3_ANY,  `RVOP_LUI  } : begin regWrite = 1'b1; wdSrc  = 1'b1; end

            { `RVF7_ANY,  `RVF3_BEQ,  `RVOP_BEQ  } : begin branch = 1'b1; condZero = 1'b1; aluControl = `ALU_SUB; branchByZero = 1'b1; end
            { `RVF7_ANY,  `RVF3_BNE,  `RVOP_BNE  } : begin branch = 1'b1; aluControl = `ALU_SUB; branchByZero = 1'b1; end
            { `RVF7_ANY,  `RVF3_BLTU, `RVOP_BLTU } : begin branch = 1'b1; condUnsignedOF = 1'b1; aluControl = `ALU_SUB; branchByOf = 1'b1; end
        endcase
    end

    always @ (posedge clk) begin
        mathUnitBusyPrev <= mathUnitBusy;
    end

endmodule

module sr_alu
(
    input  [31:0] srcA,
    input  [31:0] srcB,
    input  [ 2:0] oper,
    output        zero,
    output        unsigned_of,
    output reg [31:0] result
);
    always @ (*) begin
        case (oper)
            default   : result = srcA + srcB;
            `ALU_ADD  : result = srcA + srcB;
            `ALU_OR   : result = srcA | srcB;
            `ALU_SRL  : result = srcA >> srcB [4:0];
            `ALU_SLTU : result = (srcA < srcB) ? 1 : 0;
            `ALU_SUB  : result = srcA - srcB;
        endcase
    end
    assign unsigned_of = 
        (oper == `ALU_ADD && (result < srcA && result < srcB)) ||
        (oper == `ALU_SUB && result > srcA);
    assign zero   = (result == 0);
endmodule

module sm_register_file
(
    input         clk,
    input  [ 4:0] a0,
    input  [ 4:0] a1,
    input  [ 4:0] a2,
    input  [ 4:0] a3,
    output [31:0] rd0,
    output [31:0] rd1,
    output [31:0] rd2,
    input  [31:0] wd3,
    input         we3
);
    reg [31:0] rf [31:0];

    assign rd0 = (a0 != 0) ? rf [a0] : 32'b0;
    assign rd1 = (a1 != 0) ? rf [a1] : 32'b0;
    assign rd2 = (a2 != 0) ? rf [a2] : 32'b0;

    always @ (posedge clk)
        if(we3) rf [a3] <= wd3;
endmodule

module delay
(
    input clk,
    input rst,
    input start,
    output busy
);
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    localparam DELAY_SIZE = 4'd10;
    reg [3:0] counter;
    reg state;

    assign busy = state == BUSY;
    always @(posedge clk)
    if (rst) begin
        counter <= 0;
        state <= IDLE;
    end else case(state)
        IDLE:
            if (start) begin
                state <= BUSY;
                counter <= 0;
            end
        BUSY: begin
            counter <= counter + 1;
            if (counter == DELAY_SIZE)
                state <= IDLE;
        end
    endcase
endmodule
