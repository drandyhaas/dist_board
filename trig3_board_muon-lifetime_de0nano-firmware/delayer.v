module SyncDelay( clk, input1, output1, 
	counting, sendoutput, sendbusy, output_tot, output2, readdata,
	led1, oe);

input clk;
input sendbusy;
output reg sendoutput;
input wire[2:0] input1;
output reg output1; // O142
output reg output2; // O141
output reg[7:0] output_tot;
reg [1:0] rollover;
output reg counting;
input [7:0] readdata;
output reg led1;
output reg oe=0;//enabled by default

//define signals here
assign signalA = input1[0];
assign signalB = input1[1];
assign signalC = input1[2];

//assign start/stop signals here
assign start =(signalA && signalB) && ~signalC;
assign stop = signalC;

initial begin
    counting<=0;
	 sendoutput<=0;
end

integer counter=0;
always @ (posedge clk)
begin
	
	// O142
	if (readdata[3:0]==0) begin
		output1 = signalA;
	end
	if (readdata[3:0]==1) begin
		output1 = signalB;
	end
	if (readdata[3:0]==2) begin
		output1 = signalC;
	end
	
	// O141
	if (readdata[7:4]==0) begin
		output2 = signalA && signalB;
	end
	if (readdata[7:4]==1) begin
		output2 = signalA && signalB && signalC;
	end
	if (readdata[7:4]==2) begin
		output2 = (signalA && signalB) && ~signalC;
	end
	
	rollover<=rollover+1;
	if (counting) begin //while counting
		if (~stop && output_tot<255) begin // keep counting until the stop signal or an overflow
			if (rollover==0) output_tot = output_tot+1; // only count every 4th clock tick
		end
		else begin
			counting<=0;
			if (~sendbusy && output_tot<255 && output_tot>2) sendoutput=1;//don't bother sending overflows or time differences too small
			if (~sendbusy && counter<1000 && readdata==255) sendoutput=1;//serial test
		end
	end	
	else begin //not counting
		sendoutput=0;
		if (start || readdata==255) begin
			counting<=1;
			output_tot=1;
		end
	end
	
	// for LED test
	counter=counter+1;
	if (counter>50000000) begin
		counter=0;
		if (readdata!=252) led1= ~led1;
	end
	
	// for output test
	if (readdata==254) begin
		output1 = (counter==0);
		output2 = (counter==1);
	end
	
	// output enable / disable
	if (readdata==253) oe=0; // enable
	if (readdata==252) oe=1; // disable

end //always

endmodule
