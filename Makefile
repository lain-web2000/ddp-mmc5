AS = ca65
CC = cc65
LD = ld65

.PHONY: clean
build: main.nes

integritycheck: main.nes
	radiff2 -x main.nes original.fds | head -n 100

%.o: %.asm
	$(AS) --create-dep "$@.dep" -g --debug-info $< -o $@

main.nes: layout fdsbios.o main.o
	$(LD) --dbgfile $@.dbg -C layout fdsbios.o main.o -o $@

clean:
	rm -f main*.nes *.o *.o.bin

include $(wildcard ./*.dep)
