DIR_INCLUDE= -I.
MODEL = atmega328p
DF_CPU = 16000000UL
OUTPUT_PORT = /dev/ttyACM0
CXX = avr-gcc
CXXARGS = -Os -DF_CPU=$(DF_CPU) -mmcu=$(MODEL) 
#CXXARGS  = -ansi -pedantic -Wall -g
CXXFLAGS = $(DIR_INCLUDE) $(CXXARGS)

TEST_DIFF = diff -b
RM = -rm -f


all: compile 

.PHONY: upload
upload: master
	avr-objcopy -O ihex -R .eeprom master master.hex
	avrdude -F -V -c arduino -p $(MODEL) -P $(OUTPUT_PORT) -U


.PHONY: compile
compile: main.o main.h  
	$(CXX) -mmcu=$(MODEL) -o master main.o 
	


# Declaración de targets de objetos para tp1
main.o: main.c
	$(CXX) $(CXXFLAGS) -c -o main.o main.c
main.c: main.h 


# Cleaning targets

.PHONY: clean
clean:
	$(RM) -v *.o *.exe *.t *.out *.err .*.swp

.PHONY: partial_cleaning
partial_cleaning:
	$(RM) *.o .*.swp	
