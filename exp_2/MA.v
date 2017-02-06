//pre-processing
module pre_processing(M, N, clk, rst_n, start, S, ready);
// inputs //
input [255:0] M;
input [255:0] N;
input clk;
input rst_n; 
input start;
// outputs //
output [256:0] S;
output ready;

// wires //
wire  [255:0] D;//check if S<<1 > N

reg   [256:0] next_S;
wire  [7:0]   next_i;

// flip flops //
reg   [256:0] S;
wire  ready;
reg   [7:0]   i;

//==========combinational circuit===========//
assign D = (S<<1)-N;
assign next_i = (start == 1)? 0: (&i == 1)? 8'd255 : i+1; //wait for BOB
assign ready = (&i == 1)? 1: 0;

always@(*) begin
	if(ready == 1) next_S = S;
	else if(|i == 0) next_S = M;
	else if(D>0) next_S = D; // better method for D>0?????!!!!!
	else next_S = S<<1;
end

//==========sequential circuit===========//
always@(posedge clk or negedge rst_n) begin
	if(rst_n == 0) begin
		S <= 0;
		i <= 0;
	end
	else begin
		S <= next_S;
		i <= next_i;
	end
end

endmodule


//MA
module MA(A, B, N, clk, rst_n, start, V, ready);
// inputs //
input [255:0] A, B;
input [255:0] N;
input clk;
input rst_n; 
input start;

// outputs //
output [256:0] V; //size of V??!!
output ready;

// wires //
reg   [256:0] next_V;
wire  [256:0] D;
wire  tmp;
reg   [7:0]   i;

// flip flops //
reg   [256:0] V;
wire  [7:0]   next_i;

//=========combinational circuit===========//
assign tmp = (V+A[i]*B+((V+A[i]*B)&257'd1)*N)>>1;
assign D = tmp-N;
assign next_i = (start == 1)? 0: (&i == 1)? 8'd255: i+1; //wait for BOB
assign ready = (&i == 1)? 1: 0;

always@(*) begin
	if(ready == 1) next_V = V;
	else if(|i == 0) next_V = 0;
	else if(D>0) next_V = D;
	else next_V = tmp;
end

//==========sequential circuit=============//
always@(posedge clk or negedge rst_n) begin
	if(rst_n == 0) begin
		V = 0;
		i = 0;
	end
	else begin
		V = next_V;
		i = next_i;
	end
end
endmodule