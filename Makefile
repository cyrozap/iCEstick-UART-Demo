SYN = yosys
PNR = arachne-pnr
GEN = icepack
PROG = iceprog

TOP = uart_demo.v
PCF = icestick.pcf
DEVICE = 1k

OUTPUT = $(patsubst %.v,%.bin,$(TOP))

all: $(OUTPUT)

%.bin: %.asc
	$(GEN) $< $@

%.asc: %.blif
	$(PNR) -d $(DEVICE) -p $(PCF) -o $@ $<

%.blif: %.v
	$(SYN) -p "read_verilog $<; synth_ice40 -flatten -blif $@"

clean:
	rm -f *.asc *.bin *.blif

flash: $(OUTPUT)
	$(PROG) $<

.PHONY: all clean flash
