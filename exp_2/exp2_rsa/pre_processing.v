//pre_processing
module pre_processing(M, N, clk, rst_n, start, V, ready);
// inputs //
input [255:0] M;
input [255:0] N;
input clk;
input rst_n;
input start;
// outputs //
output [255:0] V;
output ready;

// wires //
wire  [256:0] D;//check if V<<1 > N
reg   [255:0] next_V;
wire  [8:0]   next_i;
wire  next_ready;

// flip flops //
reg   [255:0] V;
reg   [8:0]   i;
reg   ready;

//==========combinational circuit===========//
assign next_i = (i==9'd511)? i:((i == 9'd256)? 9'd511: i+1);
assign next_ready = (i == 9'd256)? 1: 0;

//calculate D
assign D = (V<<1)-N;
//calculate shiftV

//calculate V
always@(*) begin
    if (i==9'd256 || &i == 1 ) next_V=V;
	else if(  D[256]==0 ) next_V = D;
	else next_V = V<<1;
end

//==========sequential circuit===========//
always@(posedge clk or posedge rst_n or posedge start ) begin
	if(rst_n == 1 || start ==1) begin
		V <= M;
		i <= 0;
        ready <= 0;
	end
	else begin
		V <= next_V;
		i <= next_i;
        ready <= next_ready;
	end
end

endmodule