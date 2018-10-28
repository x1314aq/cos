#!Makefile

TARGET = cos
IMG = floppy.img
CC = gcc
LD = ld
AS = gas
OBJCOPY = objcopy
OBJDUMP = objdump
RM = rm -f

CFLAGS = -fno-pic -static -fno-builtin -fno-strict-aliasing -O2 -Wall -MD -ggdb3 -m32 -Werror -fno-omit-frame-pointer -fno-stack-protector
ASFLAGS = -m32 -gdwarf-2 -Wa,-divide
LDFLAGS = -T scripts/kernel.ld -m elf_i386 -nostdlib

C_SOURCES = $(shell find . -name "*.c")
C_OBJECTS = $(patsubst %.c, %.o, $(C_SOURCES))
S_SOURCES = $(shell find . -name "*.S")
S_OBJECTS = $(patsubst %.S, %.o, $(S_SOURCES))

all: $(S_OBJECTS) $(C_OBJECTS) $(TARGET) update_image

.c.o:
	@echo compiling C sources $< ...
	$(CC) $(CFLAGS) $< -o $@

.S.o:
	@echo compiling AS sources $< ...
	$(AS) $(ASFLAGS) $<

$(TARGET):
	@echo linking...
	$(LD) $(LDFLAGS) $(S_OBJECTS) $(C_OBJECTS) -o $@

.PHONY:clean
clean:
	$(RM) $(S_OBJECTS) $(C_OBJECTS) $(TARGET) $(IMG)

.PHONY:update_image
update_image:
	@echo updating image...
	dd if=$(TARGET) of=$(IMG) bs=512 count=1 conv=notrun

.PHONY:create_image
create_image:
	@echo creating empty image: $(IMG)
	dd if=/dev/zero of=$(IMG) bs=512 count=2880
	mkfs.msdos $(IMG)

.PHONY:qemu
qemu:
	qemu -fda $(IMG) -boot a

.PHONY:debug
debug:
	qemu -S -s -fda $(IMG) -boot a &
	cgdb -x tools/gdbinit
