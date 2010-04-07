# This is an adaptation of the Arduino 0017 Makefile

TARGET = trackuino
INSTALL_DIR = /Applications/Arduino.app/Contents/Resources/Java
PORT = /dev/tty.usb*
UPLOAD_RATE = 57600
AVRDUDE_PROGRAMMER = stk500v1
MCU = atmega328p
F_CPU = 16000000

############################################################################
# Below here nothing should be changed...

AVR_TOOLS_PATH = $(INSTALL_DIR)/hardware/tools/avr/bin
SRC = $(wildcard lib/Core/*.c) \
			$(wildcard src/*.c) \
		  $(wildcard lib/Ethernet/utility/*.c) \
			$(wildcard lib/Wire/utility/*.c)
CXXSRC = $(wildcard lib/Core/*.cpp) \
				 $(wildcard src/*.cpp) \
				 $(wildcard lib/Wire/*.cpp) \
				 $(wildcard lib/SoftwareSerial/*.cpp) \
				 $(wildcard lib/EEPROM/*.cpp) \
				 $(wildcard lib/Ethernet/*.cpp) 
FORMAT = ihex


# Debugging format.
# Native formats for AVR-GCC's -g are stabs [default], or dwarf-2.
# AVR (extended) COFF requires stabs, plus an avr-objcopy run.
DEBUG = stabs

# Optimization
OPT = s

# Place -D or -U options here
CDEFS = -DF_CPU=$(F_CPU)
CXXDEFS = -DF_CPU=$(F_CPU)

# Place -I options here
CINCS = -Iinclude
CXXINCS = -Iinclude

# Debugging options
CDEBUG = -g$(DEBUG)
CWARN = -Wall -Wstrict-prototypes

# Extra options
CEXTRA = -ffunction-sections -fdata-sections
CXXEXTRA = -fno-exceptions -ffunction-sections -fdata-sections

CFLAGS = $(CDEFS) $(CINCS) -O$(OPT) $(CWARN) $(CSTANDARD) $(CEXTRA)
CXXFLAGS = $(CDEFS) $(CINCS) -O$(OPT) $(CXXEXTRA)
#ASFLAGS = -Wa,-adhlns=$(<:.S=.lst),-gstabs 
LDFLAGS = -lm


# Programming support using avrdude. Settings and variables.
AVRDUDE_PORT = $(PORT)
AVRDUDE_WRITE_FLASH = -U flash:w:build/$(TARGET).hex
AVRDUDE_FLAGS = -C $(INSTALL_DIR)/hardware/tools/avr/etc/avrdude.conf \
-p $(MCU) -P $(AVRDUDE_PORT) -c $(AVRDUDE_PROGRAMMER) \
-b $(UPLOAD_RATE)

# Program settings
CC = $(AVR_TOOLS_PATH)/avr-gcc
CXX = $(AVR_TOOLS_PATH)/avr-g++
OBJCOPY = $(AVR_TOOLS_PATH)/avr-objcopy
OBJDUMP = $(AVR_TOOLS_PATH)/avr-objdump
AR  = $(AVR_TOOLS_PATH)/avr-ar
SIZE = $(AVR_TOOLS_PATH)/avr-size
NM = $(AVR_TOOLS_PATH)/avr-nm
AVRDUDE = $(AVR_TOOLS_PATH)/avrdude
REMOVE = rm -f
MV = mv -f

# Define all object files.
OBJ = $(SRC:.c=.o) $(CXXSRC:.cpp=.o) $(ASRC:.S=.o) 

# Define all listing files.
LST = $(ASRC:.S=.lst) $(CXXSRC:.cpp=.lst) $(SRC:.c=.lst)

# Combine all necessary flags and optional flags.
# Add target processor to flags.
ALL_CFLAGS = -mmcu=$(MCU) -I. $(CFLAGS)
ALL_CXXFLAGS = -mmcu=$(MCU) -I. $(CXXFLAGS)
ALL_ASFLAGS = -mmcu=$(MCU) -I. -x assembler-with-cpp $(ASFLAGS)


# Default target.
all: make_build_dir build sizeafter

make_build_dir:
	test -d build || mkdir build

build: elf hex 

elf: build/$(TARGET).elf
hex: build/$(TARGET).hex
eep: build/$(TARGET).eep
lss: build/$(TARGET).lss 
sym: build/$(TARGET).sym

# Program the device.  
upload: build/$(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) $(AVRDUDE_WRITE_FLASH)


# Display size of file.
HEXSIZE = $(SIZE) --target=$(FORMAT) build/$(TARGET).hex
ELFSIZE = $(SIZE)  build/$(TARGET).elf

sizebefore:
	@if [ -f build/$(TARGET).elf ]; then echo; echo $(MSG_SIZE_BEFORE); $(HEXSIZE); echo; fi

sizeafter:
	@if [ -f build/$(TARGET).elf ]; then echo; echo $(MSG_SIZE_AFTER); $(HEXSIZE); echo; fi


# Convert ELF to COFF for use in debugging / simulating in AVR Studio or VMLAB.
COFFCONVERT=$(OBJCOPY) --debugging \
--change-section-address .data-0x800000 \
--change-section-address .bss-0x800000 \
--change-section-address .noinit-0x800000 \
--change-section-address .eeprom-0x810000 


coff: build/$(TARGET).elf
	$(COFFCONVERT) -O coff-avr build/$(TARGET).elf $(TARGET).cof


extcoff: $(TARGET).elf
	$(COFFCONVERT) -O coff-ext-avr build/$(TARGET).elf $(TARGET).cof


.SUFFIXES: .elf .hex .eep .lss .sym

.elf.hex:
	$(OBJCOPY) -O $(FORMAT) -R .eeprom $< $@

.elf.eep:
	-$(OBJCOPY) -j .eeprom --set-section-flags=.eeprom="alloc,load" \
	--change-section-lma .eeprom=0 -O $(FORMAT) $< $@

# Create extended listing file from ELF output file.
.elf.lss:
	$(OBJDUMP) -h -S $< > $@

# Create a symbol table from ELF output file.
.elf.sym:
	$(NM) -n $< > $@

# Link: create ELF output file from library.
build/$(TARGET).elf: $(OBJ) 
	$(CXX) -Os -Wl,--gc-sections -mmcu=$(MCU) -o $@ $(OBJ) $(LDFLAGS)


# Compile: create object files from C++ source files.
.cpp.o:
	$(CXX) -c $(ALL_CXXFLAGS) $< -o $@ 

# Compile: create object files from C source files.
.c.o:
	$(CC) -c $(ALL_CFLAGS) $< -o $@ 


# Compile: create assembler files from C source files.
.c.s:
	$(CC) -S $(ALL_CFLAGS) $< -o $@


# Assemble: create object files from assembler source files.
.S.o:
	$(CC) -c $(ALL_ASFLAGS) $< -o $@


# Automatic dependencies
%.d: %.c
	$(CC) -M $(ALL_CFLAGS) $< | sed "s;$(notdir $*).o:;$*.o $*.d:;" > $@

%.d: %.cpp
	$(CXX) -M $(ALL_CXXFLAGS) $< | sed "s;$(notdir $*).o:;$*.o $*.d:;" > $@


# Target: clean project.
clean:
	$(REMOVE) build/$(TARGET).hex build/$(TARGET).eep build/$(TARGET).cof build/$(TARGET).elf \
	build/$(TARGET).map build/$(TARGET).sym build/$(TARGET).lss build/core.a \
	$(OBJ) $(LST) $(SRC:.c=.s) $(SRC:.c=.d) $(CXXSRC:.cpp=.s) $(CXXSRC:.cpp=.d)

.PHONY:	all build elf hex eep lss sym program coff extcoff clean make_build_dir sizebefore sizeafter

DEPENDS = $(CXXSRC:.cpp=.d) $(SRC:.c=.d)

include $(DEPENDS)