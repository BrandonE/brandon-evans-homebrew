MEMORY {
    ZP: start = $00, size = $100, type = rw, file = "";
    RAM: start = $200, size = $600, type = rw, file = "";
    HEADER: start = $7FF0, size = $10, type = ro, file = %O;
    PRG: start = $8000, size = $8000, type = rw, file = %O;
    CHR: start = $10000, size = $2000, type = rw, file = %O;
}

SEGMENTS {
    ZEROPAGE: load = ZP, type = zp;
    BSS: load = RAM, type = bss, define = yes;
    NESHEADER: load = HEADER, type = ro;
    CODE: load = PRG, type = rw, align = $100;
    VECTORS: load = PRG, type = rw, start = $FFFA;
    CHR: load = CHR, type = rw;
}