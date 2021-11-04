module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [16-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] coincidence_time, input [7:0] histostosend,
	input clk_adc, output reg[31:0] histosout[8], input resethist, 
	input clk_locked,	output ext_trig_out,
	input reg[31:0] randnum, input reg[31:0] prescale, input dorolling,
	input [7:0] dead_time
	);

reg[7:0] i;
reg[7:0] j;
reg[31:0] histos[8][16];
reg [16-1:0] coaxinreg;
reg pass_prescale;
reg[7:0] triedtofire[4];
reg[7:0] ext_trig_out_counter=0;
reg[31:0] autocounter=0; // for a rolling trigger
reg [7:0] histostosend2;//to pass timing, since it's sent from the slow clk
reg [31:0] prescale2;//to pass timing, since it's sent from the slow clk
reg[5:0] Tout[16];
reg[3:0] Nin[4]; // can be up to 4 groups active in each row

always@(posedge clk_adc) begin
	
	pass_prescale <= (randnum<=prescale2);
	histostosend2<=histostosend;
	prescale2<=prescale;
	ext_trig_out <= (ext_trig_out_counter>0);
	
	i=0; while (i<16) begin
		coaxinreg[i] <= ~coax_in[i]; // inputs are inverted (so that unconnected inputs are 0), then read into registers and buffered
		coax_out[i] <= Tout[i]>0; // outputs fire while Tout is high
		if (Tout[i]>0) Tout[i] <= Tout[i]-1; // count down how long the triggers have been active
		//coax_out[i] <= coaxinreg[i]; // passthrough		
		if (i<8) histosout[i]<=histos[i][histostosend2]; // histo output
		if (i<4) begin
			if (triedtofire[i]>0) triedtofire[i] <= triedtofire[i]-1; // count down deadtime for outputs
		end
		i=i+1;
	end
	
	// see how many "groups" (a set of two bars) are active in each "row" of 4 groups (for projective triggers)
	// we ask for them to be >2 so that they will disappear before the calculated "vetos" will be gone
	Nin[0] <= (Tin[0]>2) + (Tin[1]>2) + (Tin[2]>2) + (Tin[3]>2);
	Nin[1] <= (Tin[4]>2) + (Tin[5]>2) + (Tin[6]>2) + (Tin[7]>2);
	Nin[2] <= (Tin[8]>2) + (Tin[9]>2) + (Tin[10]>2) + (Tin[11]>2);
	Nin[3] <= (Tin[12]>2) + (Tin[13]>2) + (Tin[14]>2) + (Tin[15]>2);
	//Note that it's important that we use "<=" here, since these will be updated at the _end_ of this always block and then ready to use in the _next_ clock cycle
	//The "vetos" in each trigger below will be calculated in _this_ clock cycle and so should be present _earlier_
	
	// fire the outputs (0 and 1) if there are >1 input groups active
	if (triedtofire[0]==0 && ((Nin[0]+Nin[1]+Nin[2]+Nin[3])>1) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==0 || i==1) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire[0] <= dead_time; // will stay dead for this many clk ticks
	end
	
	// fire the outputs (2 and 3) if there are >1 input groups active in any row
	if (triedtofire[1]==0 && (Nin[0]>1 || Nin[1]>1 || Nin[2]>1 || Nin[3]>1) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==2 || i==3) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire[1] <= dead_time; // will stay dead for this many clk ticks
	end
	
	// fire the outputs (4 and 5) if there are >2 input groups active in any row
	if (triedtofire[2]==0 && (Nin[0]>2 || Nin[1]>2 || Nin[2]>2 || Nin[3]>2) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==4 || i==5) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire[2] <= dead_time; // will stay dead for this many clk ticks
	end
	
	// fire the outputs (6 and 7) if there are >2 input groups active in any row, and just 1 row with any input groups active
	if (triedtofire[3]==0 && (Nin[0]>2 || Nin[1]>2 || Nin[2]>2 || Nin[3]>2) && ( ((Nin[0]>0)+(Nin[1]>0)+(Nin[2]>0)+(Nin[3]>0)) <2 ) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==6 || i==7) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire[3] <= dead_time; // will stay dead for this many clk ticks
	end
	
	// fire the output (8) if there are >0 input groups active (good for testing inputs)
	if (triedtofire[0]==0 && ((Nin[0]+Nin[1]+Nin[2]+Nin[3])>0) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==8) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
		end
		triedtofire[0] <= dead_time; // will stay dead for this many clk ticks
	end
	
	//rolling trigger (about 119.21 Hz)
	if (autocounter[20]) begin
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
		
		// buffer inputs
		if (coaxinreg[j]) begin
				Tin[j] <= coincidence_time; // set Tin high for this channel for this many clk ticks
				if (!resethist) histos[0][j] <= histos[0][j]+1; // record the trigger for monitoring
		end
		else begin				
			if (Tin[j]>0) Tin[j] <= Tin[j]-1; // count down how long the triggers have been active
		end
		
		// reset histos
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
