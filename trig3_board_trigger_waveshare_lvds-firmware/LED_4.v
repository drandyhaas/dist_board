module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [16-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] calibticks, input [7:0] histostosend,
	input clk_adc, output reg[31:0] histosout[8], input resethist, 
	input clk_locked,	output ext_trig_out,
	input reg[31:0] randnum, input reg[31:0] prescale, input dorolling
	);

reg[7:0] i;
reg[7:0] j;
reg[31:0] histos[8][16];
reg [16-1:0] coaxinreg;
reg pass_prescale;
reg[7:0] triedtofire=0;
reg[7:0] ext_trig_out_counter=0;
reg[31:0] autocounter=0; // for a rolling trigger
reg [7:0] histostosend2;//to pass timing, since it's sent from the slow clk
reg [31:0] prescale2;//to pass timing, since it's sent from the slow clk
reg[5:0] Tout[16];

always@(posedge clk_adc) begin
	
	pass_prescale <= (randnum<=prescale2);
	histostosend2<=histostosend;
	prescale2<=prescale;
	ext_trig_out <= (ext_trig_out_counter>0);
	if (triedtofire>0) triedtofire <= triedtofire-1; // count down deadtime for outputs
	
	i=0; while (i<16) begin
		coaxinreg[i] <= coax_in[i]; // inputs are read into registers and buffered
		coax_out[i] <= Tout[i]>0; // outputs fire while Tout is high
		if (Tout[i]>0) Tout[i] <= Tout[i]-1; // count down how long the triggers have been active
		//coax_out[i] <= coaxinreg[i]; // passthrough		
		if (i<8) histosout[i]<=histos[i][histostosend2]; // histo output
		i=i+1;
	end
	
	// these are the actual triggers
	if (triedtofire==0 && (Tin[0]>0 || Tin[1]>0)) begin // fire the outputs if input 0 or 1 has a trigger that was active
		if (pass_prescale) begin
			i=0; while (i<16) begin
				Tout[i] <= 4; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire <= 20; // will stay dead for this many clk ticks
	end
	else begin // fire the output i if a trigger was active on channel i (for i>1)
		i=0; while (i<16) begin 
			if (i>1) if (Tin[i]>0) Tout[i]<=4; // fire outputs for this long
			i=i+1;
		end
	end
	
	//rolling trigger
	if (autocounter[25]) begin
		if (dorolling) ext_trig_out_counter <= 4;
		autocounter <= 0;
	end
	else begin
		if (ext_trig_out_counter>0) ext_trig_out_counter <= ext_trig_out_counter - 1;
		autocounter <= autocounter+1;
	end	
	
end

// triggers (from other boards) are read in and monitored
reg[5:0] Tin[16];
always @(posedge clk_adc) begin
		
		j=0; while (j<16) begin
			if (coaxinreg[j]) begin
					Tin[j] <= 20; // set Tin high for this channel for this many clk ticks
					if (!resethist) histos[4][j] <= histos[4][j]+1; // record the trigger for monitoring
			end
			else begin				
				if (Tin[j]>0) Tin[j] <= Tin[j]-1; // count down how long the triggers have been active
			end
			if (resethist) begin
				i=0; while (i<8) begin
					histos[i][j] <= 0;
					i=i+1;
				end
			end
			j=j+1;
		end
		
end


//for LEDs
reg [1:0] ledi=0;
reg[31:0] counter=0;
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
