all : bootloader disk.img

bootloader:
	@echo
	@echo ============ Build Boot Loader ============
	@echo
	
	make -C 00.bootloader
	
	@echo
	@echo ============ Build Complete ============
	@echo
	
disk.img: 00.bootloader/bootloader.bin
	@echo
	@echo ============ Disk Image Build Start ============
	@echo
	
	cp 00.bootloader/bootloader.bin disk.img
	
	@echo
	@echo ============ All Build Complete ============
	@echo
	
clean:
	make -C 00.bootLoader clean
	rm -f disk.img
