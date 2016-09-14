/*
 * Copyright 2015 Forest Crossman
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

`include "cores/osdvu/uart.v"

module top(
	input iCE_CLK,
	input RS232_Rx_TTL,
	output RS232_Tx_TTL,
	output LED0,
	output LED1,
	output LED2,
	output LED3,
	output LED4
	);

	wire reset = 0;
	reg transmit;
	reg [7:0] tx_byte;
	wire received;
	wire [7:0] rx_byte;
	wire is_receiving;
	wire is_transmitting;
	wire recv_error;

	assign LED4 = recv_error;
	//assign {LED3, LED2, LED1, LED0} = rx_byte[7:4];
	assign {LED3, LED2, LED1, LED0} = rx_byte[3:0];

	uart #(
		.baud_rate(9600),                 // The baud rate in kilobits/s
		.sys_clk_freq(12000000)           // The master clock frequency
	)
	uart0(
		.clk(iCE_CLK),                    // The master clock for this module
		.rst(reset),                      // Synchronous reset
		.rx(RS232_Rx_TTL),                // Incoming serial line
		.tx(RS232_Tx_TTL),                // Outgoing serial line
		.transmit(transmit),              // Signal to transmit
		.tx_byte(tx_byte),                // Byte to transmit
		.received(received),              // Indicated that a byte has been received
		.rx_byte(rx_byte),                // Byte received
		.is_receiving(is_receiving),      // Low when receive line is idle
		.is_transmitting(is_transmitting),// Low when transmit line is idle
		.recv_error(recv_error)           // Indicates error in receiving packet.
	);

    // input and output to be communicated
    reg [15:0] vinput=16'b0;  // input and output are reserved keywords
    reg [23:0] voutput=24'b0;


    reg [2:0] writecount=write_A;
    reg [1:0] readcount =read_A;

    parameter STATE_RECEIVING   = 2'd0;
    parameter STATE_CALCULATING = 2'd1;
    parameter STATE_SENDING     = 2'd2;
    //parameter STATE_SEND_COMPLETED = 2'b11;

    parameter read_A                 = 2'd0;
    parameter read_A_transition_B    = 2'd1;
    parameter read_B                 = 2'd2;

    parameter write_A                = 3'd0;
    parameter write_A_transit_B      = 3'd1;
    parameter write_B                = 3'd2;
    parameter write_B_transit_AplusB = 3'd3;
    parameter write_AplusB           = 3'd4;
    parameter write_done             = 3'd5;

    reg ready=1;

    reg [1:0] state=STATE_RECEIVING;



    always @(posedge iCE_CLK) begin

        case (state) 

        STATE_RECEIVING: begin
           transmit <= 0;
           case (readcount)
              read_A:  begin
                  if(received) begin
		      vinput[7:0]<=8'b0;
                      vinput[15:8]<=rx_byte;
                      readcount <= read_A_transition_B;
                  end
              end

              read_A_transition_B:  begin
                  if(~received) begin
                      readcount <= read_B;
                  end
              end

              read_B: begin
                  if(received) begin
                      vinput[7:0]<=rx_byte;
                      state<=STATE_CALCULATING;
                      readcount <= read_A;
                  end
              end

              default: begin
                      // should not be reached
                      state<=STATE_CALCULATING;
              end
           endcase
        end

        STATE_CALCULATING: begin
           writecount   <= write_A;
           voutput[7:0] <= vinput[15:8]+vinput[7:0];
           voutput[23:8] <= vinput[15:0];
           state <= STATE_SENDING;
        end

        STATE_SENDING: begin


            case (writecount)

            write_A: begin
               if (~ is_transmitting) begin
                   writecount  <= write_A_transit_B;
                   tx_byte <= voutput[23:16];
                   //tx_byte <= vinput[15:8];
                   transmit <= 1;
                   state     <= STATE_SENDING;
               end
            end

            write_A_transit_B: begin
               if ( is_transmitting) begin
                   writecount  <= write_B;
                   transmit    <= 0;
               end
            end

            write_B: begin
               if (~ is_transmitting) begin
                   writecount   <= write_B_transit_AplusB;
                   tx_byte <= voutput[15:8];
                   //tx_byte <= vinput[7:0];
                   transmit <= 1;
                   state     <= STATE_SENDING;
               end
            end

            write_B_transit_AplusB: begin
               if ( is_transmitting) begin
                   transmit    <= 0;
                   writecount  <= write_AplusB;
               end
            end

            write_AplusB: begin
               if (~ is_transmitting) begin
                  tx_byte = voutput[7:0];
                  transmit <= 1;
                  writecount   <= write_done;
                  state     <= STATE_SENDING;
               end
            end

            write_done: begin
               if (~ is_transmitting) begin
                  writecount <= write_A; 
                  state     <= STATE_RECEIVING;
                  transmit <= 0;
               end
            end

            endcase

        end

        default: begin
            // should not be reached
            state     <= STATE_RECEIVING;
            readcount <= read_A;
        end

        endcase

    end



endmodule
