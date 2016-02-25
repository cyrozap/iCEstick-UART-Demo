SYN = yosys
PNR = arachne-pnr
GEN = icepack
PROG = iceprog

TOP = uart_demo.v
PCF = icestick.pcf
DEVICE = 1k
#PCF = 8kboard.pcf
#DEVICE = 8k
PACKAGE = ct256

OUTPUT = $(patsubst %.v,%.bin,$(TOP))

all: $(OUTPUT)

%.bin: %.tiles
	$(GEN) $< $@

%.tiles: %.blif
	$(PNR) -d $(DEVICE) -p $(PCF) -o $@ $<
	#$(PNR) -d $(DEVICE) -P $(PACKAGE) -p $(PCF) -o $@ $<
	
%.blif: %.v
	$(SYN) -p "read_verilog $<; synth_ice40 -flatten -blif $@"

clean:
	rm -f *.bin *.blif *.tiles

flash: $(OUTPUT)
	$(PROG) $<

.PHONY: all clean flash
