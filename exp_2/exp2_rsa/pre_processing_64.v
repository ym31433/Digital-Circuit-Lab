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
wire  [258:0] D0, D1, D2, D3, D4, D5, D6, D7;
wire  [258:0] N2, N3, N4, N5, N6, N7;
wire  [256:0] D;
reg   [255:0] next_V;
wire  [6:0]   next_i;
wire  next_ready;

// flip flops //
reg   [255:0] V;
reg   [6:0]   i;
reg   ready;

//==========combinational circuit===========//
assign next_i = (&i)? i:((i == 7'd86)? 7'd127: i+1);
assign next_ready = (i == 7'd86)? 1: 0;

//calculate N
assign N2 = N<<1;
assign N3 = N2+N;
assign N4 = N<<2;
assign N5 = N4+N;
assign N6 = N4+N2;
assign N7 = N4+N2+N;
//calculate D
assign D0 = V<<3;
assign D1 = D0-N;
assign D2 = D0-N2;
assign D3 = D0-N3;
assign D4 = D0-N4;
assign D5 = D0-N5;
assign D6 = D0-N6;
assign D7 = D0-N7;

assign D = (V<<1)-N;

//calculate V
always@(*) begin
    if (i==7'd86 || &i) next_V=V;
	else if(i == 7'd85) begin
		if(!D[256]) next_V = D;  //D>0
		else next_V = V<<1;
	end
	else begin
		if(!D4[258]) begin  //D4>=0
			if(!D6[258]) begin //D6>=0
				if(!D7[258]) next_V = D7;  //D7>=0
				else next_V = D6;
			end
			else begin  //D6<0
				if(!D5[258]) next_V = D5;  //D5>=0
				else next_V = D4;
			end
		end
		else begin  //D4<0
			if(!D2[258]) begin  //D2>=0
				if(!D3[258]) next_V = D3;  //D3>=0
				else next_V = D2;
			end
			else begin  //D2<0
				if(!D1[258]) next_V = D1;  //D1>=0
				else next_V = D0;
			end
		end
	end
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