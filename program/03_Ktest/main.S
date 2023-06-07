# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#

#include "new_instructions.h"
#include "reg_codes.h"

.text

start:      
    li x10, 251
    li x11, 254
    li x12, 357
    hyp rx10, rx11, rx10
    bne x10, x12, fail
    li x10, 0
    li x11, 0
    li x12, 0
    hyp rx10, rx11, rx10
    bne x10, x12, fail
    li x10, 0
    li x11, 42
    li x12, 42
    hyp rx10, rx11, rx10
    bne x10, x12, fail
    li x10, 12
    li x11, 9
    li x12, 15
    hyp rx10, rx11, rx10
    bne x10, x12, fail
    li x10, 14
    li x11, 88
    li x12, 89
    hyp rx10, rx11, rx10
    bne x10, x12, fail

success:
    li a0, 0
    beq zero, zero, end

fail:
    li a0, 1
    beq zero, zero, end

end:
    beq zero, zero, end
