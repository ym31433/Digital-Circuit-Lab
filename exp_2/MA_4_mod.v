//MA_4
module MA_4_mod(A, B, N, clk, rst_n, V, i);
// inputs //
input [255:0] A, B;
input [255:0] N;
input clk;
input rst_n; 
input [7:0] i;
// outputs //
output [256:0] V; //size of V??!!

// wires //
reg   [256:0] next_V;
reg   [258:0] next_tmp;  //tmp = V_i + 2*a_(i+1)*B + a_i*B   can be four times larger than N(256)
wire  [1:0]   next_q;
wire  [258:0] next_tmpbuf;
reg   [256:0] next_tmp_V;  //tmp_V = (tmp + q*N)>>2
wire  [256:0] next_D;
wire  [256:0] next_tmpVbuf;

// flip flops //
reg   [256:0] V;
reg   [258:0] tmp;
reg   [1:0]   q;
reg   [258:0] tmpbuf;
reg   [256:0] tmp_V;
reg   [256:0] D;
reg   [256:0] tmpVbuf;

//=========combinational circuit===========//

//calculate tmp = V_i + 2*a_(i+1)*B + a_i*B   I don't want * so I separate this into four cases
always@(*) begin
    if(A[i] == 0) begin
        if(A[i+1] == 0) next_tmp = V;  //i>128, What will happen??!!
        else next_tmp = V + (B<<1);
    end
    else begin
        if(A[i+1] == 0) next_tmp = V + B;
        else next_tmp = V + (B<<1) + B;
    end
end

//calculate q  first bit XOR, second bit equivalent
assign next_q[1] = tmp[1]^tmp[0];
assign next_q[0] = tmp[0];
assign next_tmpbuf = tmp;

//calculate tmp_V = (tmp + q*N)>>2   don't want *
always@(*) begin
    case(q)
        2'b00: next_tmp_V = tmpbuf>>2;
        2'b01: next_tmp_V = (tmpbuf+N)>>2;
        2'b10: next_tmp_V = (tmpbuf+(N<<1))>>2;
        2'b11: next_tmp_V = (tmpbuf+N+(N<<1))>>2;
        default: next_tmp_V = tmpbuf;
    endcase
end

//calculate D
assign next_D = tmp-N;
assign next_tmpVbuf = tmp_V;

//calculate V
always@(*) begin
//	if(i == 8'd0 || i == 8'd1 || i == 8'd2 || i == 8'd3 || i == 8'd4) next_V = 0;  //Can this work   |i[7]~i[2] == 0?
	if(D>0) next_V = D;
	else next_V = tmpVbuf;
end

//==========sequential circuit=============//
always@(posedge clk or negedge rst_n or negedge i[7]) begin
	if(rst_n == 0 || i[7] == 0) begin
		V       <= 0;
        tmp     <= 0;
        q       <= 0;
        tmpbuf  <= 0;
        tmp_V   <= 0;
        D       <= 0;
        tmpVbuf <= 0;
	end
	else begin
		V       <= next_V;
        tmp     <= next_tmp;
        q       <= next_q;
        tmpbuf  <= next_tmpbuf;
        tmp_V   <= next_tmp_V;
        D       <= next_D;
        tmpVbuf <= next_tmpVbuf;
	end
end
endmodule