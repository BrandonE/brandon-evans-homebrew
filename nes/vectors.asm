    .import RESET, NMI, IRQ
    .segment "VECTORS"
    .word NMI
    .word RESET
    .word IRQ