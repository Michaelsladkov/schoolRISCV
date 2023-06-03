# RISC-V simple counter program
#
# Stanislav Zhelnio, 2020
#

            .text

start:      mv a0, zero              # t0 = 0
            li a1, 0x37
counter:    addi a0, a0, 1           # t0 = t0 + 1
            bltu a0, a1, counter
end:
            beq zero, zero, end
