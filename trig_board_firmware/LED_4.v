module LED_4(
	input nrst,
	input clk,
	inout reg [3:0]led,
	input coax1,
	input coax2,
	output reg coax_out_1
	);
	
	// for LEDs and other little sutff
	integer counter;
	reg clk2;
	always@(posedge clk) begin
		if(!nrst) begin
			counter <= 0;
			clk2 <= 0;
		end
		else if (counter == 100000000) begin
			counter <= 0;
			clk2 = ~clk2; // posedge once per sec for input of 200 MHz from PLL
		end
		else counter <= counter + 32'd1;
	end
	reg [1:0] ledi;	
	always@(posedge clk2) begin
		case (ledi)
		0:	begin led <= 4'b1110;ledi<=ledi+2'b01; end
		1:	begin led <= 4'b1101;ledi<=ledi+2'b01; end
		2:	begin led <= 4'b1011;ledi<=ledi+2'b01; end
		3:	begin led <= 4'b0111;ledi<=ledi+2'b01; end
		endcase			
	end
	
	
	// main trigger code using simple method
	/*
	always@(posedge clk) begin		
		if (coax1 || coax2) begin
		//if (coax1 ) begin
			coax_out_1 = 1;
		end
		else begin
			coax_out_1 = 0;
		end
	end
	*/
	
	// main trigger code using firing
	integer state=READY;
	localparam READY=0, FIRING=1, DEAD=2;
	integer firingcounter=0;
	always@(posedge clk) begin		
	case (state)
		READY: begin // start off waiting for a trigger condition
			firingcounter<=0;
			coax_out_1 <= 0; // not sending the trigger output
			if (coax1 || coax2) begin // trigger on the OR of input 1,2
				state = FIRING; // fire the trigger
			end
		end
		FIRING: begin
			firingcounter <= firingcounter+1; // each clk tick is 5 ns
			coax_out_1 <= 1; // sending the trigger output
			if (firingcounter >= 4) begin // after ~20 ns, go back to waiting
				state = DEAD;
			end
		end
		DEAD: begin
			firingcounter <= firingcounter+1; // continue counting
			coax_out_1 <= 0; // not sending the trigger output
			if (firingcounter >= 24) begin // after another ~100 ns, go back to waiting
				state = READY;
			end
		end
	endcase
	end
	
endmodule
