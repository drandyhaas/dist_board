module pong(clk, vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B);
input clk;
output vga_h_sync, vga_v_sync, vga_R, vga_G, vga_B;

wire inDisplayArea;
wire [9:0] CounterX;
wire [8:0] CounterY;

hvsync_generator syncgen(.clk(clk), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), 
                            .inDisplayArea(inDisplayArea), .CounterX(CounterX), .CounterY(CounterY));

// Draw a border around the screen
wire border = (CounterX[9:3]==0) || (CounterX[9:3]==79) || (CounterY[8:3]==0) || (CounterY[8:3]==59);
wire R = border;
wire G = border;
wire B = border;

reg vga_R, vga_G, vga_B;
always @(posedge clk)
begin
  vga_R <= R & inDisplayArea;
  vga_G <= G & inDisplayArea;
  vga_B <= B & inDisplayArea;
end

endmodule
