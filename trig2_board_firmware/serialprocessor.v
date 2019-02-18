module processor(clk, rxReady, rxData, txBusy, txStart, txData, readdata,
	deadticks, firingticks, enable_outputs);
	
	input clk;
	input[7:0] rxData;
	input rxReady;
	input txBusy;
	output reg txStart;
	output reg[7:0] txData;
	output reg[7:0] readdata;//first byte we got
	output reg enable_outputs=0;//set low to enable outputs
	reg [7:0] extradata[10];//to store command extra data, like arguemnts (up to 10 bytes)
	localparam READ=0, SOLVING=1, WRITE1=3, WRITE2=4, READMORE=9;
	integer state=READ;
	integer bytesread, byteswanted;
	
	integer ioCount, ioCountToSend;
	reg[7:0] data[0:15];//for writing out data in WRITE1,2
	
	output reg[7:0] deadticks=10; // dead for 200 ns
	output reg[7:0] firingticks=9; // 50 ns wide pulse

	always @(posedge clk) begin
	case (state)
	READ: begin		  
		txStart<=0;
		bytesread<=0;
		byteswanted<=0;
      ioCount = 0;
      if (rxReady) begin
			readdata = rxData;
         state = SOLVING;
      end
	end
	READMORE: begin
		if (rxReady) begin
			extradata[bytesread] = rxData;
			bytesread = bytesread+1;
			if (bytesread>=byteswanted) state=SOLVING;
		end
	end
   SOLVING: begin
		if (readdata==0) begin // send the firmware version				
			ioCountToSend = 1;
			data[0]=2; // this is the firmware version
			state=WRITE1;				
		end
		else if (readdata==1) begin //wait for next byte: number of 20ns ticks to remain dead for after firing outputs
			byteswanted=1; if (bytesread<byteswanted) state=READMORE;
			else begin
				deadticks=extradata[0];
				state=READ;
			end
		end
		else if (readdata==2) begin //wait for next byte: number of 5ns ticks to fire outputs for
			byteswanted=1; if (bytesread<byteswanted) state=READMORE;
			else begin
				firingticks=extradata[0];
				state=READ;
			end
		end
		else if (readdata==3) begin //toggle output enable
			enable_outputs = ~enable_outputs;
			state=READ;
		end
		else state=READ; // if we got some other command, just ignore it
	end		
	
	//just writng out some data bytes over serial
	WRITE1: begin
		if (!txBusy) begin
			txData = data[ioCount];
         txStart = 1;
         state = WRITE2;
		end
	end
   WRITE2: begin
		txStart = 0;
      if (ioCount < ioCountToSend-1) begin
			ioCount = ioCount + 1;
         state = WRITE1;
      end
		else state = READ;
	end

	endcase
	end  
	
endmodule
