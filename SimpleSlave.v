module SimpleSlave (SCLK, SS, MISOA, MISOB, MOSI, switches, lights);
	
	//	Define the I/Os	//
	input SCLK;
	input SS;
	input MOSI;
	
	input [1:0]switches;
	
	output MISOA;
	output MISOB;
	
	output [2:0]lights;
	
	//	Assignments	//
	assign MISOA = switches[0];
	assign MISOB = switches[1];
	
	assign lights[0] = SCLK;
	assign lights[1] = SS;
	assign lights[2] = MOSI;
	
endmodule
