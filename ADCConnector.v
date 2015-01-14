/*
Anthony De Caria - June 15, 2014

This module is the structure that interfaces NIOS-II with two AD7264 A-D-Cs.
This is done using SPI protocol.

It takes key signals from NIOS (CPOL, CPHA, ss), and transforms them into SCLK and SS signals.

In addition, it also creates the structures needed to collect and transmit data to and from the AD7264s
A 16-bit serializer for transmitting.
And two 14-bit deserializers for receiving, as the AD7264 is a dual channel device.
*/

module ADCConnector 
(
	SPIClock, resetn, 
		CPOL, CPHA, ss,
			SCLK, SS, MOSI1, MISO1A, MISO1B, MOSI2, MISO2A, MISO2B, 
				dataOutOfMaster1, dataIntoMaster1A, dataIntoMaster1B, dataOutOfMaster2, dataIntoMaster2A, dataIntoMaster2B,
					masterSaysLoad1, masterSaysLoad2, finishedCycling, loadedData1, loadedData2
);
	
	/*
	
	I/Os
	
	*/
	
	//	General I/Os	//
	input SPIClock;
	input resetn;
	
	//	CPU I/Os	//
	input CPOL;
	input CPHA;
	input ss;
	
	input masterSaysLoad1;
	input masterSaysLoad2;
	
	output finishedCycling;
	output loadedData1;
	output loadedData2;
	
	//	Data I/Os	//
	input [15:0]dataOutOfMaster1;
	output [13:0]dataIntoMaster1A;
	output [13:0]dataIntoMaster1B;
	
	input [15:0]dataOutOfMaster2;
	output [13:0]dataIntoMaster2A;
	output [13:0]dataIntoMaster2B;
	
	//	SPI I/Os	//
	output SCLK;
	output SS;
	
	output MOSI1;
	input MISO1A;
	input MISO1B;
	
	output MOSI2;
	input MISO2A;
	input MISO2B;
	
	//	Intra-Connector wires	//
	wire [5:0] master_counter_bit;
	wire Des_en, Ser_en;
	wire inboxLineIn1A, inboxLineIn1B, inboxLineIn2A, inboxLineIn2B, outboxLineOut1, outboxLineOut2;
	wire [15:0] outboxQ1, outboxQ2;
	wire registerSignal;
	
	//	Early assignments	//
	assign SS = ss;
	
	assign Ser_en = ~master_counter_bit[5] & ~master_counter_bit[4];
	assign Des_en = (~master_counter_bit[5] & master_counter_bit[4] & (master_counter_bit[3] | master_counter_bit[2] | master_counter_bit[1] & master_counter_bit[0]) ) | (master_counter_bit[5] & ~master_counter_bit[4] & ~master_counter_bit[3] & ~master_counter_bit[2] & ~master_counter_bit[1] & ~master_counter_bit[0]);
	
	assign finishedCycling = master_counter_bit[5];
	assign loadedData1 = (outboxQ1 == dataOutOfMaster1)? 1'b1: 1'b0;
//	assign loadedData2 = (outboxQ2 == dataOutOfMaster2)? 1'b1: 1'b0;
	assign loadedData2 = 1'b1;
	
	assign outboxLineOut1 = outboxQ1[15];
	assign outboxLineOut2 = outboxQ2[15];
	
	/*
	
	Counter
	This is the counter that will be used to pace out the sending out and receiving parts of the 
	
	*/	
	 Six_Bit_Counter_Enable_Async PocketWatch
	(
		.clk(SPIClock), 
		.resetn(resetn & ~SS), 
		.enable(~SS & ~(master_counter_bit[5] & ~master_counter_bit[4] & ~master_counter_bit[3] & ~master_counter_bit[2] & ~master_counter_bit[1] & master_counter_bit[0]) ),
		.q(master_counter_bit)
	);
										
	/*
	
	Signal Makers
	
	*/
	SCLKMaker TimeLord
	(
		.Clk(SPIClock), 
		.S(ss), 
		.CPOL(CPOL), 
		.SCLK(SCLK)
	);
	
	SPIRSMaker Level
	(
		.CPHA(CPHA), 
		.CPOL(CPOL), 
		.RS(registerSignal)
	);
										
	/*
	
	Serializers
	
	*/
	Shift_Register_16_Enable_Async_Muxed OutBox1
	(
		.clk(~(SPIClock ^ registerSignal)),
		.resetn(resetn), 
		.enable(Ser_en), 
		.select(masterSaysLoad1), 
		.d(dataOutOfMaster1), 
		.q(outboxQ1)
	);
	
	/*
	
	Deserializers
	
	*/
	Shift_Register_14_Enable_Async InBox1A
	(
		.clk(~(SPIClock ^ registerSignal)), 
		.resetn(resetn), 
		.enable(Des_en), 
		.d(inboxLineIn1A), 
		.q(dataIntoMaster1A)
	);
													
	Shift_Register_14_Enable_Async InBox1B
	(
		.clk(~(SPIClock ^ registerSignal)), 
		.resetn(resetn), 
		.enable(Des_en), 
		.d(inboxLineIn1B), 
		.q(dataIntoMaster1B)
	);
	
	/*
	
	Tri-state buffers
	
	*/
	TriStateBuffer_2_1bit BorderGuardOut1
	(
		.In(outboxLineOut1), 
		.Select(Ser_en), 
		.Out(MOSI1)
	);
											
	TriStateBuffer_2_1bit BorderGuardIn1A
	(
		.In(MISO1A), 
		.Select(Des_en), 
		.Out(inboxLineIn1A)
	);
											
	TriStateBuffer_2_1bit BorderGuardIn1B
	(
		.In(MISO1B), 
		.Select(Des_en), 
		.Out(inboxLineIn1B)
	);

endmodule

