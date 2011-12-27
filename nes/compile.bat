SET target=../../../Homebrew/nes
ca65 header.asm -o "%target%/header.o"
ca65 vectors.asm -o "%target%/vectors.o"
ca65 "%~n1.asm" -o "%target%/%~n1.o"
ld65 -C linker.asm "%target%/header.o" "%target%/%~n1.o" "%target%/vectors.o" -o "%target%/%~n1.nes"
pause