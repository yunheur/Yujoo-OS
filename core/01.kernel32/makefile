all: kernel32.bin

#virtual_os.bin: virtual_os.asm
#	nasm -o virtual_os.bin virtual_os.asm

kernel32.bin: source/entry_point.s
	nasm -o kernel32.bin $<

clean:
	rm -f kernel32.bin
