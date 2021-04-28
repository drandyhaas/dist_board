module LED_4(
	input nrst,
	input clk_lvds,
	output reg [3:0] led,
	input [15:0] coax_in,
	output [15:0] coax_out,	
	input [7:0] deadticks, input [7:0] firingticks,
	input clk_test, input [2:0] phaseoffset,
	input clkin, input usefullwidth, input passthrough,
	output integer histo[4], input resethist, input vetopmtlast,	
	input [NBINS-1:0] lvds_rx
	);
	
	parameter NBINS = 8;
	
	// for testing logic
	reg pmt1test;
	reg [5:0] clk1counter=0;
	always@(posedge clk_test) begin // runs on the fast clock
		clk1counter <= clk1counter+1;		
		if (clk1counter == 1) pmt1test<=1; // make a test pulse
		else pmt1test<=0;
	end
	
	wire pmt1;
	//assign pmt1 = pmt1test; // pmt test input
	assign pmt1 = coax_in[3] ||coax_in[8]; // pmt input (LVDS) || (single-ended)
	
	assign coax_out[0]=pmt1test; //N11 // a test pulse
	assign coax_out[1]=clk_test; // P9 // the 4x input for test pulses
	reg out1;assign coax_out[2]=out1; // A6 // the out1
	reg out2;assign coax_out[3]=out2; // B6 // the out2
	assign coax_out[4]=clkin; // D12 // the input clock that can also have its phase adjusted
	assign coax_out[5]=clk_lvds; // B3 // the clk for lvds that can also have its phase adjusted
	
	assign led[0]=pmt1;
	assign led[1]=out1;
	assign led[2]=out2;
	assign led[3]=1;
		
	reg resethist1=0, resethist2=0;
	reg [NBINS-1:0] lvds_last=0;
	reg [NBINS-1:0] phot=0;
	reg [NBINS-1:0] j;
	always@(posedge clkin) begin
		if (passthrough) begin
			out1 <= pmt1;
			out2 <= 0;
		end
		else begin			
			if (vetopmtlast) begin
				lvds_last[NBINS-1] = lvds_last[0];
				for (j=0; j<NBINS-1; j=j+1) begin
					lvds_last[j] = lvds_rx[j+1];
				end
				phot = lvds_rx & ~lvds_last;
			end
			else begin
				phot = lvds_rx;
			end
			out1 <= phot[0+phaseoffset]||(phot[1+phaseoffset]&&usefullwidth);			
			out2 <= phot[NBINS/2+phaseoffset]||(phot[NBINS/2+1+phaseoffset]&&usefullwidth);
			lvds_last = lvds_rx;

			resethist1<=resethist;
			resethist2<=resethist1;
			if (resethist2) begin
				histo[0]<=0;
				histo[1]<=0;
				histo[2]<=0;
				histo[3]<=0;
			end
			else begin
				if (phot[0+phaseoffset]) histo[0]<=histo[0]+1;
				if (phot[1+phaseoffset]) histo[1]<=histo[1]+1;
				if (phot[2+phaseoffset]) histo[2]<=histo[2]+1;
				if (phot[3+phaseoffset]) histo[3]<=histo[3]+1;
			end
			
		end		
	end
	
	/*
	//for LEDs
	reg [1:0] ledi;
	integer fastcounter=0;
	always@(posedge clkin) begin
		fastcounter<=fastcounter+1;
		if (fastcounter[25]) begin			
			fastcounter<=0;
			ledi<=ledi+2'b01;
			case (ledi)
			0:	begin led <= 4'b0001; end
			1:	begin led <= 4'b0010; end
			2:	begin led <= 4'b0100; end
			3:	begin led <= 4'b1000; end
			endcase
		end
	end
	*/
	
endmodule
