module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [16-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] calibticks, input [7:0] histostosend,
	input clk_adc, output integer histosout[8], input resethist, output spareright, output reg [2:0] delaycounter[16],
	input clk_locked
	);

integer i;
integer j;
integer histos[8][16];
reg [16-1:0] coaxinreg;
always@(posedge clk_adc) begin
	i=0; while (i<16) begin
		if (clk_locked) coaxinreg[i]<=coax_in[i];
		else coaxinreg[i]<=0;
		if (i<4) coax_out[i] <= (Tin[i][0]>0); // fire the channel i if board 0 has a trigger that was active on channel i
		else coax_out[i] <= coaxinreg[i]; // passthrough
		if (i<8) begin
			histosout[i]<=histos[i][histostosend];
		end
		i=i+1;
	end
end

integer sparerightcounter=0;
always@(posedge clk_adc) begin
	if (sparerightcounter<655) spareright<=1; // time waiting for sync pulses, including time waiting for normal triggers to cease, 250+200+205 worst case
	else spareright<=0;
	if (sparerightcounter[17+calibticks]) sparerightcounter<=0;
	else sparerightcounter<=sparerightcounter+1;
end

// triggers (from other boards) are synced in
reg[1:0] Pulsecounter=0;
reg[5:0] Trecovery[3:0][16];
reg[3:0] Tin[4][16];
reg[1:0] thebin[16];
always @(posedge clk_adc) begin
	if (spareright) begin
		if (sparerightcounter>200) begin // time to wait for normal triggers to cease
			i=0; while (i<4) begin
				j=0; while (j<16) begin
					if (coaxinreg[j] && Pulsecounter==i) Trecovery[i][j]<=Trecovery[i][j]+1;
					if (Trecovery[i][j]/2==27 && Trecovery[(i+1)%4][j]==0 && Trecovery[(i+2)%4][j]==0 && Trecovery[(i+3)%4][j]==0) delaycounter[j] <= i+1;
					histos[i][j] <= Trecovery[i][j];
					j=j+1;
				end
				i=i+1;
			end
		end
		else begin
			delaycounter[j] <= 0;
		end
	end
	else begin
		i=0; while (i<4) begin
			j=0; while (j<16) begin
				Trecovery[i][j]<=0;
				j=j+1;
			end
			i=i+1;
		end
		
		j=0; while (j<16) begin
				thebin[j] = (Pulsecounter-delaycounter[j]+1)%4;
				if (coaxinreg[j]) begin
				if (delaycounter[j]>0) begin // we have a lock
					Tin[thebin[j]][j] = 3; // set Tin high for this channel for 4 times this many clk ticks
					histos[4+thebin[j]][j] = histos[4+thebin[j]][j]+1; // record the trigger for monitoring
				end
				else begin
					//we have a trigger but no lock on the triggers from the board!
				end
			end
			else begin // every 4 ticks
				// count down how long the triggers have been active
				if (Tin[thebin[j]][j]>0) Tin[thebin[j]][j] = Tin[thebin[j]][j]-1;
			end
			j=j+1;
		end
	
	end
	Pulsecounter = Pulsecounter+1; // for iterating through the trigger bins
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
