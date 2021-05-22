module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [16-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] calibticks, input [7:0] histostosend,
	input clk_adc, output reg[31:0] histosout[8], input resethist, output spareleft, output reg [2:0] delaycounter[16],
	input clk_locked,
	output ext_trig_out,
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
reg [7:0] calibticks2;//to pass timing, since it's sent from the slow clk
reg [31:0] prescale2;//to pass timing, since it's sent from the slow clk
always@(posedge clk_adc) begin
	pass_prescale <= (randnum<=prescale2);
	histostosend2<=histostosend;
	calibticks2<=calibticks;
	prescale2<=prescale;
	i=0; while (i<16) begin
		if (clk_locked) coaxinreg[i]<=coax_in[i];
		else coaxinreg[i]<=0;
		if (i<4) coax_out[i] <= (Tin[i][0]>0); // fire the channel i if board 0 has a trigger that was active on channel i
		else coax_out[i] <= coaxinreg[i]; // passthrough
		if (i<8) histosout[i]<=histos[i][histostosend2];
		//debuging
		//histosout[0]<=pass_prescale;
		//histosout[1]<=randnum;
		//histosout[2]<=prescale;
		//histosout[2]<=triedtofire;
		i=i+1;
	end
	if (triedtofire==0 && (Tin[1][0]>0 && Tin[1][6]>0)) begin // fire the ext_trig output if boards 0,6 has a trigger that was active on channel 1
		if (pass_prescale) begin
			ext_trig_out_counter <= 4;//clk ticks to fire ext_trig for
			autocounter <= 0;
		end
		else begin
			if (ext_trig_out_counter>0) ext_trig_out_counter <= ext_trig_out_counter - 1;
		end
		triedtofire <= 20; // will stay dead for this many clk ticks
	end
	else begin
		if (autocounter[26]) begin
			if (dorolling) ext_trig_out_counter <= 4;//rolling trigger
			autocounter <= 0;
		end
		else begin
			if (ext_trig_out_counter>0) ext_trig_out_counter <= ext_trig_out_counter - 1;
			autocounter <= autocounter+1;
		end
		if (triedtofire>0) triedtofire <= triedtofire-1;
	end
	ext_trig_out <= (ext_trig_out_counter>0);
end

reg[31:0] spareleftcounter=0;
always@(posedge clk_adc) begin
	if (spareleftcounter<655) spareleft<=1; // time waiting for sync pulses, including time waiting for normal triggers to cease, 250+200+205 worst case
	else spareleft<=0;
	if (spareleftcounter[17+calibticks2]) spareleftcounter<=0;
	else spareleftcounter<=spareleftcounter+1;
end

// triggers (from other boards) are synced in
reg[1:0] Pulsecounter=0;
reg[5:0] Trecovery[3:0][16];
reg[3:0] Tin[4][16];
reg[1:0] thebin[16];
always @(posedge clk_adc) begin
	if (spareleft) begin
		if (spareleftcounter>200) begin // time to wait for normal triggers to cease
			i=0; while (i<4) begin
				j=0; while (j<16) begin
					if (coaxinreg[j] && Pulsecounter==i) Trecovery[i][j] <= Trecovery[i][j]+1;
					if (Trecovery[i][j]/2==27 && Trecovery[(i+1)%4][j]==0 && Trecovery[(i+2)%4][j]==0 && Trecovery[(i+3)%4][j]==0) delaycounter[j] <= i+1;
					histos[i][j] <= Trecovery[i][j];
					j=j+1;
				end
				i=i+1;
			end
		end
		else begin
			j=0; while (j<16) begin
				delaycounter[j] <= 0;
				j=j+1;
			end
		end
	end
	else begin
		i=0; while (i<4) begin
			j=0; while (j<16) begin
				Trecovery[i][j] <= 0;
				j=j+1;
			end
			i=i+1;
		end
		
		j=0; while (j<16) begin
			thebin[j] <= (Pulsecounter-delaycounter[j]+2)%4; // funky math - should be +1, but need an extra bin because this is not actually updated until after it is used below (gotta love FPGAs!)
			if (coaxinreg[j]) begin
				if (delaycounter[j]>0) begin // we have a lock
					Tin[thebin[j]][j] <= 3; // set Tin high for this channel for 4 times this many clk ticks
					histos[4+thebin[j]][j] <= histos[4+thebin[j]][j]+1; // record the trigger for monitoring
				end
				else begin
					//we have a trigger but no lock on the triggers from the board!
				end
			end
			else begin // every 4 ticks
				// count down how long the triggers have been active
				if (Tin[thebin[j]][j]>0) Tin[thebin[j]][j] <= Tin[thebin[j]][j]-1;
			end
			if (resethist) begin
				i=0; while (i<4) begin
					histos[4+i][j] <= 0;
					i=i+1;
				end
			end
			j=j+1;
		end
	
	end
	Pulsecounter <= Pulsecounter+1; // for iterating through the trigger bins
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
