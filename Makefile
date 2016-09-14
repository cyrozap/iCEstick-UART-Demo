SYN = yosys
PNR = arachne-pnr
GEN = icepack
PROG = iceprog

TOP = uart_demo.v
PCF = icestick.pcf
DEVICE = 1k
PATHTODEVICE = /dev/ttyUSB1

BITSTREAM = $(patsubst %.v,%.bin,$(TOP))
HOST      = $(patsubst %.v,%_host,$(TOP))

ifeq (uart_adder.v,$(TOP))
all: $(BITSTREAM) $(HOST)
else
all: $(BITSTREAM)
endif


%.bin: %.tiles
	$(GEN) $< $@

%.tiles: %.blif
	$(PNR) -d $(DEVICE) -p $(PCF) -o $@ $<

%.blif: %.v
	$(SYN) -p "read_verilog $<; synth_ice40 -flatten -blif $@"

clean:
	rm -f *.bin *.blif *.tiles uart_adder_host

flash: $(BITSTREAM)
	$(PROG) $<

run:
	for i in $$(seq 0 3); do \
	   for j in $$(seq 0 3); do \
	      sudo ./uart_adder_host $(PATHTODEVICE) $$i $$j ; \
	   done ; \
	done

iverilog:
	iverilog $(TOP)

uart_demo_host:
	# No action

uart_adder_host: uart_adder_host.c
	$(CC) $(CFLAGS) -o $@ $<


.PHONY: all clean flash uart_demo_host
