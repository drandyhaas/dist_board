module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [15:0] coax_in,
	output [15:0] coax_out,	
	input [7:0] deadticks, input [7:0] firingticks,
	input clk_adc, output integer histos[8], input resethist, output spareright, output reg[7:0] delaycounter
	);
	
integer i;
always@(posedge clk_adc) begin
	i=0; while (i<16) begin
		coax_out[i] <= coax_in[i];
		//if (resethist) begin
		//	if (i<4) histos[i] <= 0;
		//end
		//else begin
		//	if (i<4) histos[i] <= histos[i]+1;
		//end
		i=i+1;
	end
end

integer sparerightcounter=0;
always@(posedge clk_adc) begin
	if (sparerightcounter<655) spareright<=1; // time waiting for sync pulses, including time waiting for normal triggers to cease, 250+200+205 worst case
	else spareright<=0;
	if (sparerightcounter[27]) sparerightcounter<=0;
	else sparerightcounter<=sparerightcounter+1;
end

// triggers (from other boards) are synced in
reg[1:0] Pulsecounter=0;
reg[7:0] Trecovery[3:0];
always @(posedge clk_adc) begin
	if (spareright) begin
		if (sparerightcounter>200) begin // time to wait for normal triggers to cease
			if (coax_in[0] && Pulsecounter==0) Trecovery[0]<=Trecovery[0]+1;
			if (coax_in[0] && Pulsecounter==1) Trecovery[1]<=Trecovery[1]+1;
			if (coax_in[0] && Pulsecounter==2) Trecovery[2]<=Trecovery[2]+1;
			if (coax_in[0] && Pulsecounter==3) Trecovery[3]<=Trecovery[3]+1;
			delaycounter[0] <= (Trecovery[0]/2==27 && Trecovery[1]==0 && Trecovery[2]==0 && Trecovery[3]==0);
			delaycounter[1] <= (Trecovery[1]/2==27 && Trecovery[0]==0 && Trecovery[2]==0 && Trecovery[3]==0);
			delaycounter[2] <= (Trecovery[2]/2==27 && Trecovery[0]==0 && Trecovery[1]==0 && Trecovery[3]==0);
			delaycounter[3] <= (Trecovery[3]/2==27 && Trecovery[0]==0 && Trecovery[1]==0 && Trecovery[2]==0);
			histos[0] <= Trecovery[0];
			histos[1] <= Trecovery[1];
			histos[2] <= Trecovery[2];
			histos[3] <= Trecovery[3];
		end
	end
	else begin
		Trecovery[0]=0; Trecovery[1]=0; Trecovery[2]=0; Trecovery[3]=0;
	end
	Pulsecounter<=Pulsecounter+1; // for iterating through the trigger bins
end
reg[1:0] Pulsecounter2=0;
reg[7:0] Trecovery2[3:0];
always @(negedge clk_adc) begin // do the same on the negative edge, to see which edge syncs the triggers in better
	if (spareright) begin
		if (sparerightcounter>200) begin // time to wait for normal triggers to cease
			if (coax_in[0] && Pulsecounter2==0) Trecovery2[0]<=Trecovery2[0]+1;
			if (coax_in[0] && Pulsecounter2==1) Trecovery2[1]<=Trecovery2[1]+1;
			if (coax_in[0] && Pulsecounter2==2) Trecovery2[2]<=Trecovery2[2]+1;
			if (coax_in[0] && Pulsecounter2==3) Trecovery2[3]<=Trecovery2[3]+1;
			delaycounter[4] <= (Trecovery2[0]/2==27 && Trecovery2[1]==0 && Trecovery2[2]==0 && Trecovery2[3]==0);
			delaycounter[5] <= (Trecovery2[1]/2==27 && Trecovery2[0]==0 && Trecovery2[2]==0 && Trecovery2[3]==0);
			delaycounter[6] <= (Trecovery2[2]/2==27 && Trecovery2[0]==0 && Trecovery2[1]==0 && Trecovery2[3]==0);
			delaycounter[7] <= (Trecovery2[3]/2==27 && Trecovery2[0]==0 && Trecovery2[1]==0 && Trecovery2[2]==0);
			histos[4] <= Trecovery2[0];
			histos[5] <= Trecovery2[1];
			histos[6] <= Trecovery2[2];
			histos[7] <= Trecovery2[3];
		end
	end
	else begin
		Trecovery2[0]=0; Trecovery2[1]=0; Trecovery2[2]=0; Trecovery2[3]=0;
	end
	Pulsecounter2<=Pulsecounter2+1;
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
