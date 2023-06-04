# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#

#include "new_instructions.h"
#include "reg_codes.h"

#define OP1 251
#define OP2 254
#define EXPECTED 357

            .text

start:      
            li x10, OP1
            li x11, OP2
            hyp rx10, rx11, rx10
            li x12, EXPECTED
            bne x10, x12, fail

success:
    li a0, 0
    beq zero, zero, end

fail:
    li a0, 1
    beq zero, zero, end

end:
            beq zero, zero, end
