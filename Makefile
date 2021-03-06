#!Makefile

TARGET = cos
CC = gcc
LD = ld
OBJCOPY = objcopy
OBJDUMP = objdump
RM = rm -f

CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -g -ggdb3 -m32 -Werror -fno-omit-frame-pointer -fno-stack-protector
LDFLAGS = -m elf_i386 -nostdlib
INCLUDE = -Iinclude

$(TARGET): sign bootloader
	dd if=/dev/zero of=$(TARGET) count=10000
	dd if=bootloader of=$(TARGET) conv=notrunc

sign: tools/sign.c
	$(CC) -Wall -Werror -O2 $^ -o $@

bootloader: boot/bootasm.S boot/bootmain.c
	$(CC) $(CFLAGS) -nostdinc $(INCLUDE) -c boot/bootmain.c -o boot/bootmain.o
	$(CC) $(CFLAGS) -nostdinc $(INCLUDE) -c boot/bootasm.S -o boot/bootasm.o
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 -o boot/bootloader.o boot/bootasm.o boot/bootmain.o
	$(OBJCOPY) -S -O binary -j .text boot/bootloader.o bootloader
	./sign bootloader

.PHONY:clean
clean:
	$(RM) $(TARGET) boot/*.o sign bootloader

# try to generate a unique GDB port
GDBPORT = $(shell expr `id -u` % 5000 + 25000)
# QEMU's gdb stub command line changed in 0.11
QEMUGDB = $(shell if $(QEMU) -help | grep -q '^-gdb'; \
	then echo "-gdb tcp::$(GDBPORT)"; \
	else echo "-s -p $(GDBPORT)"; fi)

#QEMUOPTS = -drive file=fs.img,index=1,media=disk,format=raw -drive file=${TARGET},index=0,media=disk,format=raw -smp 1 -m 512 $(QEMUEXTRA)
QEMUOPTS = -drive file=${TARGET},index=0,media=disk,format=raw -smp 1 -m 512 $(QEMUEXTRA)

.PHONY:qemu
qemu: ${TARGET}
	qemu -nographic ${QEMUOPTS}

.PHONY:debug
debug: ${TARGET}
	qemu -nographic ${QEMUOPTS} -S ${QEMUGDB}
