all: virtual_os.bin

virtual_os.bin: virtual_os.asm
	nasm -o virtual_os.bin virtual_os.asm

clean:
	rm -f virtual_os.bin
