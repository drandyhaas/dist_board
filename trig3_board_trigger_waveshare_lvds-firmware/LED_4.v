module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [64-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] coincidence_time, input [7:0] histostosend,
	input clk_adc, output reg[31:0] histosout[8], input resethist, 
	input clk_locked,	output ext_trig_out,
	input reg[31:0] randnum, input reg[31:0] prescale, input dorolling,
	input [7:0] dead_time,
	input [16-1:0] coax_in_extra, output [16-1:0] coax_out_extra, input [14-1:0] io_extra, output [28-1:0] ep4ce10_io_extra
	);

reg[7:0] i;
reg[7:0] j;
reg[31:0] histos[8][64]; // for monitoring, 8 ints for each channel
reg [64-1:0] coaxinreg; // for buffering input triggers
reg pass_prescale;
reg[7:0] triedtofire[16]; // for output trigger deadtime
reg[7:0] ext_trig_out_counter=0;
reg[31:0] autocounter=0; // for a rolling trigger
reg [7:0] histostosend2;//to pass timing, since it's sent from the slow clk
reg [31:0] prescale2;//to pass timing, since it's sent from the slow clk
reg[5:0] Tout[16]; // for output triggers
reg[3:0] Nin[64/4]; // number of groups active in each row of 4 groups

always@(posedge clk_adc) begin
	
	pass_prescale <= (randnum<=prescale2);
	histostosend2<=histostosend;
	prescale2<=prescale;
	ext_trig_out <= (ext_trig_out_counter>0);	
	i=0; while (i<64) begin
		coaxinreg[i] <= ~coax_in[i]; // inputs are inverted (so that unconnected inputs are 0), then read into registers and buffered
		if (i<8) histosout[i]<=histos[i][histostosend2]; // histo output		
		if (i<16) begin // for output stuff
			coax_out[i] <= Tout[i]>0; // outputs fire while Tout is high
			//coax_out[i] <= coaxinreg[i]; // passthrough		
			if (Tout[i]>0) Tout[i] <= Tout[i]-1; // count down how long the triggers have been active
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
			triedtofire[0] <= dead_time; // will stay dead for this many clk ticks
		end
	end
	
	// fire the outputs (2 and 3) if there are >1 input groups active in any row
	if (triedtofire[1]==0 && (Nin[0]>1 || Nin[1]>1 || Nin[2]>1 || Nin[3]>1) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==2 || i==3) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
			triedtofire[1] <= dead_time; // will stay dead for this many clk ticks
		end
	end
	
	// fire the outputs (4 and 5) if there are >2 input groups active in any row
	if (triedtofire[2]==0 && (Nin[0]>2 || Nin[1]>2 || Nin[2]>2 || Nin[3]>2) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==4 || i==5) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
			triedtofire[2] <= dead_time; // will stay dead for this many clk ticks
		end
	end
	
	// fire the outputs (6 and 7) if there are >2 input groups active in any row, and just 1 row with any input groups active
	if (triedtofire[3]==0 && (Nin[0]>2 || Nin[1]>2 || Nin[2]>2 || Nin[3]>2) && ( ((Nin[0]>0)+(Nin[1]>0)+(Nin[2]>0)+(Nin[3]>0)) <2 ) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==6 || i==7) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
			triedtofire[3] <= dead_time; // will stay dead for this many clk ticks
		end
	end
	
	// fire the output (8) if there are >0 input groups active (good for testing inputs)
	if (triedtofire[4]==0 && ((Nin[0]+Nin[1]+Nin[2]+Nin[3])>0) ) begin
		if (pass_prescale) begin
			i=0; while (i<16) begin
				if (i==8) Tout[i] <= 16; // fire outputs for this long
				i=i+1;
			end
			triedtofire[4] <= dead_time; // will stay dead for this many clk ticks
			led[1] <= 1'b0; // turn on the LED
		end
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
	
	if (led[0]==1'b1) led[1]<=1'b1; // turn it off when the other led toggles, so we can see it turn back on
	
end

// triggers (from other boards) are read in and monitored
reg[5:0] Tin[64];
always @(posedge clk_adc) begin		
	j=0; while (j<64) begin
		
		// buffer inputs
		if (coaxinreg[j]) begin
				Tin[j] <= coincidence_time; // set Tin high for this channel for this many clk ticks
				if (!resethist) histos[0][j] <= histos[0][j]+1; // record the trigger for monitoring in histo 0 for each input channel
		end
		else begin				
			if (Tin[j]>0) Tin[j] <= Tin[j]-1; // count down how long the triggers have been active
		end		
		
		j=j+1;
	end
	
	// reset histos
	if (resethist) begin
		i=0; while (i<8) begin
			histos[i][histostosend2] <= 0;
			i=i+1;
		end
	end
	
end


//for LEDs
reg[31:0] counter=0;
always@(posedge clk) begin
	counter<=counter+1;
	led[0]<=counter[26]; // flashing
	led[2]<=dorolling;
	led[3]<=clk_locked;
end
	
endmodule
