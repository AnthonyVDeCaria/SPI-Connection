/*
Anthony De Caria - May 17, 2014

This code describes a slave that represents the AD7264 Analog Digital Converter chip.
The AD7264 expects a 33 cycle SS period.
In the first 16 cycles, the AD7264 chip expects to recieve data.
In the 17th and 18th cycles, the AD7264 will be in the three-state.
From the 19th clock cycle to the 32nd, the AD7264 will transmit data.
The 33rd cycle will have the same data as the 32nd.
*/

module FancySlave (resetn, SCLK, MOSI, MISOA, MISOB, SS, Hex0, Hex1, Hex2, Hex3, Hex4, Hex5, Switches, Keys, Lights, Green);
	/*
		I/Os
	*/
	
	//	General I/Os	//
	input resetn;
	input [17:0] Switches;
	input [1:0] Keys;
	
	output [6:0] Hex0, Hex1, Hex2, Hex3, Hex4, Hex5;
	output [17:0] Lights;
	output [2:0] Green;
	
	//	SPI I/Os	//
	input SCLK;
	input MOSI;
	input SS;
	
	output MISOA;
	output MISOB;
	
	//	Additional Wires	//
	wire [5:0] slave_counter_bit;
	wire Des_en, Tri_en, Ser_en;
	wire [15:0]dataOutOfSlave;
	wire dataIntoSlave, LineOutA, LineOutB;
	wire [13:0] qChannelA, qChannelB;
	
	//	Early wire assignments	//
	assign Des_en = ~SS & ~slave_counter_bit[5] & ~slave_counter_bit[4];
	assign Tri_en = ~SS & ~slave_counter_bit[5] & slave_counter_bit[4] & ~slave_counter_bit[3] & ~slave_counter_bit[2] & (slave_counter_bit[1] ^ slave_counter_bit[0]);
	assign Ser_en = ~SS & (~slave_counter_bit[5] & slave_counter_bit[4] & (slave_counter_bit[3] | slave_counter_bit[2] | slave_counter_bit[1] & slave_counter_bit[0] ) ) | (slave_counter_bit[5] & ~slave_counter_bit[4] & ~slave_counter_bit[3] & ~slave_counter_bit[2] & ~slave_counter_bit[1] & ~slave_counter_bit[0]);
	
	assign LineOutA = qChannelA[13];
	assign LineOutB = qChannelB[13];
	
	//	Debug Assignments //
//	assign Lights[16] = SCLK;
//	assign Lights[17] = SS;
	
//	assign Green[0] = Des_en;
//	assign Green[1] = Tri_en;
//	assign Green[2] = Ser_en;
	
//	assign Lights[15] = MISOA;
//	assign Lights[14] = MISOB;
	
	/*
	
	Counter
	
	*/	
	Six_Bit_Counter_Enable_Async HootHoot
	(
		.clk(~SCLK),
		.resetn(resetn & ~SS),
		.enable(~SS & ~(slave_counter_bit[5] & ~slave_counter_bit[4] & ~slave_counter_bit[3] & ~slave_counter_bit[2] & ~slave_counter_bit[1] & slave_counter_bit[0]) ),
		.q(slave_counter_bit)
	);
				
	/*
	
	Deserializer
	
	*/	
	Shift_Register_16_Enable_Async Registeel
	(
		.clk(~SCLK), 
		.resetn(resetn), 
		.enable(Des_en), 
		.d(dataIntoSlave), 
		.q(dataOutOfSlave)
	);
								
	/*
	
	Serializer
	
	*/
	Shift_Register_14_Enable_Async_Muxed OutboxA
	(
		.clk(~SCLK), 
		.resetn(resetn), 
		.enable(Ser_en | ~Keys[0]), 
		.select(~Keys[0]), 
		.d(Switches[13:0]), 
		.q(qChannelA) 
	);
												
	Shift_Register_14_Enable_Async_Muxed OutboxB
	(
		.clk(~SCLK), 
		.resetn(resetn), 
		.enable(Ser_en | ~Keys[1]), 
		.select(~Keys[1]), 
		.d(Switches[13:0]), 
		.q(qChannelB) 
	);
												
	/*
	
	Tri-state
	
	*/
	TriStateBuffer_2_1bit BorderGuard1
	(
		.In(MOSI), 
		.Select(Des_en), 
		.Out(dataIntoSlave)
	);
								
	TriStateBuffer_2_1bit BorderGuardA
	(
		.In(LineOutA), 
		.Select(Ser_en), 
		.Out(MISOA)
	);
								
	TriStateBuffer_2_1bit BorderGuardB
	(
		.In(LineOutB), 
		.Select(Ser_en), 
		.Out(MISOB)
	);
	
	/*
	
	HEXs
	
	*/
	LogicLowSevenSegmentDisplayDecoder One(.Out(Hex0), .In(dataOutOfSlave[3:0]));
	LogicLowSevenSegmentDisplayDecoder Two(.Out(Hex1), .In(dataOutOfSlave[7:4]));
	LogicLowSevenSegmentDisplayDecoder Three(.Out(Hex2), .In(dataOutOfSlave[11:8]));
	LogicLowSevenSegmentDisplayDecoder Four(.Out(Hex3), .In(dataOutOfSlave[15:12]));
	
	LogicLowSevenSegmentDisplayDecoder CounterHigher(.Out(Hex5), .In(slave_counter_bit[5:4]));
	LogicLowSevenSegmentDisplayDecoder CounterLower(.Out(Hex4), .In(slave_counter_bit[3:0]));
	
	/*
	
	Mux
	
	*/
	mux_2_14bit FancySwitch
	(
		.data0(qChannelA),
		.data1(qChannelB),
		.sel(Switches[14]),
		.result(Lights)
	);
	
endmodule

