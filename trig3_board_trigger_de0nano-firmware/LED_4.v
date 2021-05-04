module LED_4(
	input nrst,
	input clk,
	output reg [3:0] led,
	input [16-1:0] coax_in,
	output [16-1:0] coax_out,	
	input [7:0] deadticks, input [7:0] histotosend,
	input clk_adc, output integer histosout[8], input resethist, output spareright, output reg [7:0] delaycounter[16]
	);

integer histos[8][16];
integer i;
integer j;
always@(posedge clk_adc) begin
	i=0; while (i<16) begin
		coax_out[i] <= coax_in[i];
		if (i<8) histosout[i] <= histos[i][histotosend];//have to select channel for histo to send to serial
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
reg[7:0] Trecovery[3:0][16];
always @(posedge clk_adc) begin
	if (spareright) begin
		if (sparerightcounter>200) begin // time to wait for normal triggers to cease
			i=0; while (i<4) begin
				j=0; while (j<16) begin
					if (coax_in[j] && Pulsecounter==i) Trecovery[i][j]<=Trecovery[i][j]+1;
					delaycounter[j][i] <= (Trecovery[i][j]/2==27 && Trecovery[(i+1)%4][j]==0 && Trecovery[(i+2)%4][j]==0 && Trecovery[(i+3)%4][j]==0);
					histos[i][j] <= Trecovery[i][j];
					j=j+1;
				end
				i=i+1;
			end
		end
	end
	else begin
		i=0; while (i<4) begin
			j=0; while (j<16) begin
				Trecovery[i][j]=0;
				j=j+1;
			end
			i=i+1;
		end
	end
	Pulsecounter<=Pulsecounter+1; // for iterating through the trigger bins
end
reg[1:0] Pulsecounter2=0;
reg[7:0] Trecovery2[3:0][16];
always @(negedge clk_adc) begin // do the same on the negative edge, to see which edge syncs the triggers in better
	if (spareright) begin
		if (sparerightcounter>200) begin // time to wait for normal triggers to cease
			i=0; while (i<4) begin
				j=0; while (j<16) begin
					if (coax_in[j] && Pulsecounter2==i) Trecovery2[i][j]<=Trecovery2[i][j]+1;
					delaycounter[j][4+i] <= (Trecovery2[i][j]/2==27 && Trecovery2[(i+1)%4][j]==0 && Trecovery2[(i+2)%4][j]==0 && Trecovery2[(i+3)%4][j]==0);
					histos[4+i][j] <= Trecovery2[i][j];
					j=j+1;
				end
				i=i+1;
			end
		end
	end
	else begin
		i=0; while (i<4) begin
			j=0; while (j<16) begin
				Trecovery2[i][j]=0;
				j=j+1;
			end
			i=i+1;
		end
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
