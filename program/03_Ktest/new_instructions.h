#ifndef _HYP
#define _HYP

.macro hyp rd, rs1, rs2, f7=0b0000011, f3=110, opcode=1101011
    .word   \f7\rs1\rs2\f3\rd\opcode
.endm

#endif
