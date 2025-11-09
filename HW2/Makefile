include ../../../mk/toolchain.mk

ARCH = -march=rv32izicsr
LINKER_SCRIPT = linker.ld

EMU ?= ../../../build/rv32emu

AFLAGS = -g $(ARCH)

CFLAGS = -g -march=rv32i_zicsr

CFLAGS_O0 = -g -march=rv32i_zicsr -O0
CFLAGS_O1 = -g -march=rv32i_zicsr -O1
CFLAGS_O2 = -g -march=rv32i_zicsr -O2
CFLAGS_O3 = -g -march=rv32i_zicsr -O3
#CFLAGS_Os = -g -march=rv32i_zicsr -Os
CFLAGS_Ofast = -g -march=rv32i_zicsr -Ofast

LDFLAGS = -T $(LINKER_SCRIPT) 
LDFLAGS_Os = -T $(LINKER_SCRIPT) -lgcc

EXEC = test.elf 
EXECO0 = test_O0.elf 
EXECO1 = test_O1.elf 
EXECO2 = test_O2.elf 
EXECO3 = test_O3.elf 
EXECOs = test_Os.elf 
EXECOfast = test_Ofast.elf
# test.elf

CC = $(CROSS_COMPILE)gcc
AS = $(CROSS_COMPILE)as
LD = $(CROSS_COMPILE)ld
OBJDUMP = $(CROSS_COMPILE)objdump

OBJS = start.o main.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
OBJS_O0 = start.o main_O0.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
OBJS_O1 = start.o main_O1.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
OBJS_O2 = start.o main_O2.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
OBJS_O3 = start.o main_O3.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
#OBJS_Os = start.o main_Os.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o
OBJS_Ofast = start.o main_Ofast.o perfcounter.o chacha20_asm.o LC3370.o hanoi.o

# start.o main.o perfcounter.o chacha20_asm.o

EXECS = $(EXEC) $(EXECO0) $(EXECO1) $(EXECO2) $(EXECO3) $(EXECOfast)

.PHONY: all run dump clean

all: $(EXEC) $(EXECO0) $(EXECO1) $(EXECO2) $(EXECO3)  $(EXECOfast)

$(EXEC): $(OBJS) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS)
	
$(EXECO0): $(OBJS_O0) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS_O0)

$(EXECO1): $(OBJS_O1) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS_O1)

$(EXECO2): $(OBJS_O2) $(LINKER_SCRIPT) 
	$(LD) $(LDFLAGS) -o $@ $(OBJS_O2)

$(EXECO3): $(OBJS_O3) $(LINKER_SCRIPT) 
	$(LD) $(LDFLAGS) -o $@ $(OBJS_O3)

$(EXECOs): $(OBJS_Os) $(LINKER_SCRIPT) 
	$(LD) $(LDFLAGS_Os) -o $@ $(OBJS_Os)
	
$(EXECOfast): $(OBJS_Ofast) $(LINKER_SCRIPT)
	$(LD) $(LDFLAGS) -o $@ $(OBJS_Ofast)

%.o: %.S
	$(AS) $(AFLAGS) $< -o $@

%.o: %.c
	$(CC) $(CFLAGS) $< -o $@ -c
	
main_O0.o: main_O0.c
	$(CC) $(CFLAGS_O0) $< -o $@ -c

main_O1.o: main_O1.c
	$(CC) $(CFLAGS_O1) $< -o $@ -c
	
main_O2.o: main_O2.c
	$(CC) $(CFLAGS_O2) $< -o $@ -c
	
main_O3.o: main_O3.c
	$(CC) $(CFLAGS_O3) $< -o $@ -c
	
main_Os.o: main_Os.c
	$(CC) $(CFLAGS_Os) $< -o $@ -c
	
main_Ofast.o: main_Ofast.c
	$(CC) $(CFLAGS_Ofast) $< -o $@ -c

run: $(EXECS)
	@test -f $(EMU) || (echo "Error: $(EMU) not found" && exit 1)
	@grep -q "ENABLE_ELF_LOADER=1" ../../../build/.config || (echo "Error: ENABLE_ELF_LOADER=1 not set" && exit 1)
	@grep -q "ENABLE_SYSTEM=1" ../../../build/.config || (echo "Error: ENABLE_SYSTEM=1 not set" && exit 1)
	@for prog in $(EXECS); do \
		echo ">>> $(EMU) $$prog"; \
		$(EMU) $$prog || exit 1; \
		echo ""; \
	done



dump: 
	@read num; \
	case $$num in \
		1) $(OBJDUMP) -Ds $(EXEC) | less ;; \
		2) $(OBJDUMP) -Ds $(EXECO0) | less ;; \
		3) $(OBJDUMP) -Ds $(EXECO1) | less ;; \
		4) $(OBJDUMP) -Ds $(EXECO2) | less ;; \
		5) $(OBJDUMP) -Ds $(EXECO3) | less ;; \
		6) $(OBJDUMP) -Ds $(EXECOs) | less ;; \
		7) $(OBJDUMP) -Ds $(EXECOfast) | less ;; \
		*) echo "無效選擇!" ;; \
	esac

	
clean:
	rm -f $(EXEC) $(EXECO0) $(EXECO1) $(EXECO2) $(EXECO3)  $(EXECOfast) $(OBJS) $(OBJS_O0) $(OBJS_O1) $(OBJS_O2) $(OBJS_O3) $(OBJS_Os) $(OBJS_Ofast)

dump1 :  $(EXEC)
	$(OBJDUMP) -Ds $< | less
