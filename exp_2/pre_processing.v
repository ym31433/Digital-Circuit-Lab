//pre_processing
module pre_processing(M, N, clk, rst_n, start, V, ready);
// inputs //
input [255:0] M;
input [255:0] N;
input clk;
input rst_n;
input start;
// outputs //
output [256:0] V;
output ready;

// wires //
wire  [255:0] next_D;//check if V<<1 > N
reg   [256:0] next_V;
wire  [256:0] next_shiftV;
wire  [8:0]   next_i;
wire  next_ready;

// flip flops //
reg   [256:0] D;
reg   [256:0] V;
reg   [256:0] shiftV;
reg   [8:0]   i;
reg   ready;

//==========combinational circuit===========//
assign next_i = (i == 9'd257)? i: i+1;
assign next_ready = (i == 9'd257)? 1: 0;

//calculate D
assign next_D = (V<<1)-N;
//calculate shiftV
assign next_shiftV = V<<1;

//calculate V
always@(*) begin
	if(i == 9'd0 || i == 9'd1) next_V = M;
	else if(D>0) next_V = D; // better method for D>0?????!!!!!
	else next_V = shiftV;
end

//==========sequential circuit===========//
always@(posedge clk or negedge rst_n or posedge start) begin
	if(rst_n == 0 || start == 1) begin
        D <= 0;
		V <= M;
        shiftV <= 0;
		i <= 0;
        ready <= 0;
	end
	else begin
        D <= next_D;
		V <= next_V;
        shiftV <= next_shiftV;
		i <= next_i;
        ready <= next_ready;
	end
end

endmodule