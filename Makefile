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

bootloader: bootasm.S bootmain.c
	$(CC) $(CFLAGS) -nostdinc $(INCLUDE) -c bootmain.c
	$(CC) $(CFLAGS) -nostdinc $(INCLUDE) -c bootasm.S
	$(LD) $(LDFLAGS) -N -e start -Ttext 0x7C00 bootloader.o bootasm.o bootmain.o
	$(OBJCOPY) -S -O binary -j .text bootloader.o bootloader0
	./sign bootloader0 bootloader

.PHONY:clean
clean:
	$(RM) $(TARGET) *.o sign

.PHONY:qemu
qemu:
	qemu -fda $(TARGET) -boot a

.PHONY:debug
debug:
	qemu -S -s -fda $(TARGET) -boot a &
