# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#

            .text

start:      mv a0, zero              # t0 = 0
            li a1, 3
counter:    addi a0, a0, 1           # t0 = t0 + 1
    .word   0x06A5E06B
            bltu a0, a1, counter
end:
            beq zero, zero, end
