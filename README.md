# iCEstick-UART-Demo

[![Build Status](https://jenkins.cyrozap.com/job/iCEstick-UART-Demo/badge/icon)](https://jenkins.cyrozap.com/job/iCEstick-UART-Demo/)
[![License](http://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://www.apache.org/licenses/LICENSE-2.0.html)

The iCEstick is a low-cost FPGA by Lattice Semiconductors. It
directly attaches to a computer's USB port and is ideal for smallish
(sub-)projects or to just learn about the technology. The community
provides a free pipeline to program the device. A major beginner's
hurdle remains to interact with the device. A common approach is to
implement a serial interface. This project provides such an UART with
a very clear terminology. It chose a straight-forward implementation
that is easily followed by starters, with two examples to lay out
how to embedd this functionality in applications.


## Prerequisites

- [Yosys][1]
- [arachne-pnr][2]
- [IceStorm][3]

For a quick setup, the Debian Linux distribution provides respective
[packages][4]. The iCEstick can be used in virtual environments like
VirtualBox.

## Building

    git clone https://github.com/cyrozap/iCEstick-UART-Demo.git
    cd iCEstick-UART-Demo
    git submodule update --init
    make

## Flashing

Plug in your iCEstick, then run `make flash`. Depending on your
permissions, you may need to run it with `sudo`.

## Running

This project provides two applications. These share the exact same UART
implementation, but have other differences for whwhich the iCEstick
needs to be reflashed when changinging between the two.

### uart\_demo

This implements an "echo": The character sent to the FPGA is immediately
returned.  To investigate, start a terminal program like minicom or
teraterm, under Linux the tool screen is exceptionally handy. Check the
respective documentation to learn how to specify the device (/dev/ttyUSB0
or /dev/ttyUSB1) and the BAUD rate (9600).

### uart\_adder

After two bytes have been sent to the FPGA, the FPGA adds the two values
together and returns the input values and the sum. The communication
could still be performed with a terminal tool, but only a subset of
all byte values is displayed as ASCII.  A small programm written in C,
uart\_adder\_host, performs the communication with the FPGA, instead. It
takes the path to the device, the first byte and the second as arguments
on the command line. It shows what is sent and what is received, byte
per byte.

It should be noted that all input data (the two bytes) are stored in a
single C struct and that data structure is copied bytewise under complete
neglect of the underlying data structure. This can be as easily decomposed
on the FPGA side, which would work for arbitrary data structures

On the FPGA-side, uart\_adder implements two layers of
finite-state-machines (FSM).  The upper layer circles between the
receive-compute-send states. The reading and sending have substates for
each byte and the interim time it needs to receive/send it.

To run, do
```
make TOP=uart_adder.v flash
sudo ./uart_adder_host /dev/ttyUSB1 4 5
```


[1]: http://www.clifford.at/yosys/
[2]: https://github.com/cseed/arachne-pnr
[3]: http://www.clifford.at/icestorm/
[4]: http://wiki.debian.org/FPGA/Lattice
