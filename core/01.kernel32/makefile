################################################################################
# 빌드 환경 및 규칙 설정 
################################################################################
# 컴파일러 및 링커 정의
NASM32 = nasm
GCC32 = /usr/cross/bin/x86_64-pc-linux-gcc -c -m32 -ffreestanding
LD32 = /usr/cross/bin/x86_64-pc-linux-ld -melf_i386 -T ../elf_i386.x -nostdlib -e Main -Ttext 0x10200

# 바이너리 이미지 생성을 위한 OBJCOPY 옵션 정의
OBJCOPY32 = /usr/cross/bin/x86_64-pc-linux-objcopy -j .text -j .data -j .rodata -j .bss -S -O binary

# 디렉터리 정의
OBJECTDIRECTORY = temp
SOURCEDIRECTORY	= source

################################################################################
# 빌드 항목 및 빌드 방법 설정
################################################################################
# 기본적으로 빌드를 수행할 목록
all: prepare kernel32.bin

# 오브젝트 파일이 위치할 디렉터리를 생성
prepare:
	mkdir -p $(OBJECTDIRECTORY)

# 커널 엔트리 포인트 빌드
$(OBJECTDIRECTORY)/entry_point.bin: $(SOURCEDIRECTORY)/entry_point.s
	$(NASM32) -o $@ $<

# 커널의 C 소스 파일에 대한 의존성 정보 생성
dep:
	@echo === Make Dependancy File ===
	make -C $(OBJECTDIRECTORY) -f ../makefile InternalDependency
	@echo === Dependancy Search Complete ===

# 디렉터리를 오브젝트 파일 디렉터리로 이동해서 의존성 파일 및 실행 파일을 생성
ExecuteInternalBuild: dep
	make -C $(OBJECTDIRECTORY) -f ../makefile kernel32.elf

# 커널 이미지를 바이너리 파일로 변환
$(OBJECTDIRECTORY)/kernel32.elf.bin: ExecuteInternalBuild
	$(OBJCOPY32) $(OBJECTDIRECTORY)/kernel32.elf $@

# 엔트리 포인트와 커널을 합쳐서 보호 모드 바이너리 생성
kernel32.bin: $(OBJECTDIRECTORY)/entry_point.bin $(OBJECTDIRECTORY)/kernel32.elf.bin
	cat $^ > $@
		
# 소스 파일을 제외한 나머지 파일 정리	
clean:
	rm -f *.bin
	rm -f $(OBJECTDIRECTORY)/*.*

################################################################################
# Make에 의해 다시 호출되는 부분, Temp 디렉터리를 기준으로 수행됨
################################################################################
# 빌드할 C 소스 파일 정의, Temp 디렉터리를 기준으로 설정
CENTRYPOINTOBJECTFILE = main.o
CSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.c)
ASSEMBLYSOURCEFILES = $(wildcard ../$(SOURCEDIRECTORY)/*.asm)
COBJECTFILES = $(subst main.o, , $(notdir $(patsubst %.c,%.o,$(CSOURCEFILES))))
ASSEMBLYOBJECTFILES = $(notdir $(patsubst %.asm,%.o,$(ASSEMBLYSOURCEFILES)))

# .c 파일을 .o 파일로 바꾸는 규칙 정의
%.o: ../$(SOURCEDIRECTORY)/%.c
	$(GCC32) -c $<

# .asm 파일을 .o 파일로 바꾸는 규칙 정의
%.o: ../$(SOURCEDIRECTORY)/%.asm
	$(NASM32) -f elf32 -o $@ $<

# 실제 의존성에 관련된 파일을 생성
InternalDependency:
	$(GCC32) -MM $(CSOURCEFILES) > dependency.dep

# 실제 커널 이미지를 빌드
kernel32.elf: $(CENTRYPOINTOBJECTFILE) $(COBJECTFILES) $(ASSEMBLYOBJECTFILES)
	$(LD32) -o $@ $^

# 현재 디릭토리의 파일 중, dependency 파일이 있으면 make에 포함	
ifeq (dependency.dep, $(wildcard dependency.dep))
include dependency.dep
endif

