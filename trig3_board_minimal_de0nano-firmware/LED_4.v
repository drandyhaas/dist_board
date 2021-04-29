module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [15:0] coax_in,
	output [15:0] coax_out,	
	input [7:0] deadticks, input [7:0] firingticks,
	input clk_adc, output integer histos[4], input resethist
	);
	
	integer i;
	always@(posedge clk_adc) begin
		i=0; while (i<16) begin
			coax_out[i] <= coax_in[i];
			if (resethist) begin
				if (i<4) histos[i] <= 0;
			end
			else begin
				if (i<4) histos[i] <= histos[i]+1;
			end
			i=i+1;
		end
	end
	
	//for LEDs
	reg [1:0] ledi;
	integer counter=0;
	always@(posedge clk) begin
		counter<=counter+1;
		if (counter[25]) begin			
			counter<=0;
			ledi<=ledi+2'b01;
			case (ledi)
			0:	begin led <= 4'b0001; end
			1:	begin led <= 4'b0010; end
			2:	begin led <= 4'b0100; end
			3:	begin led <= 4'b1000; end
			endcase
		end
	end
	
endmodule
