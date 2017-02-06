//MA_4
module MA_4_mod(A, B, N, clk, rst_n, V, i);
// inputs //
input [255:0] A, B;
input [255:0] N;
input clk;
input rst_n; 
input [7:0] i;
// outputs //
output [255:0] V; //size of V??!!

// wires //
wire  [7:0]   i_2      ;
wire  [7:0]   i_2_p1   ;
reg   [255:0] next_V;
wire  [258:0] B_2;
wire  [258:0] B_3;
                       
wire  [258:0] N_2;
wire  [258:0] N_3;
wire  [258:0] N_4;
                       
wire  [258:0] V_B;
wire  [258:0] V_2B;
wire  [258:0] V_3B;
                      
wire  [258:0] tmp_d4;
wire  [258:0] tmp_N_d4;
wire  [258:0] tmp_2N_d4;
wire  [258:0] tmp_3N_d4;
                      
wire  [258:0] tmp_m4N_d4;
wire  [258:0] tmp_m3N_d4;
wire  [258:0] tmp_m2N_d4;
wire  [258:0] tmp_mN_d4;
         

// flip flops //
reg   [255:0] V;
reg   [258:0] tmp;
wire  [1:0]   q;
//=========combinational circuit===========//

//calculate tmp = V_i + 2*a_(i+1)*B + a_i*B   I don't want * so I separate this into four cases


//calculate q  first bit XOR, second bit equivalent
assign i_2       = i<<1;
assign i_2_p1    = i_2+1;

assign B_2       = B<<1;
assign B_3       = B_2+B;

assign N_2       = N<<1;
assign N_3       = N_2+N;
assign N_4       = N<<2;

assign V_B       = V+B;
assign V_2B      = V+B_2;
assign V_3B      = V+B_3;

assign tmp_d4    = (tmp)>>2;
assign tmp_N_d4  = (tmp+N)>>2;
assign tmp_2N_d4 = (tmp+N_2)>>2;
assign tmp_3N_d4 = (tmp+N_3)>>2;
                       
assign tmp_m4N_d4= (tmp-N_4)>>2;
assign tmp_m3N_d4= (tmp-N_3)>>2;
assign tmp_m2N_d4= (tmp-N_2)>>2;
assign tmp_mN_d4 = (tmp-N  )>>2;


always@(*) begin
    if(A[i_2] == 0) begin
        if(A[i_2_p1] == 0) tmp = V;  //i>128, What will happen??!!
        else tmp = V_2B;
    end
    else begin
        if(A[i_2_p1] == 0) tmp = V_B;
        else tmp = V_3B;
    end
end

assign q[1] = tmp[1]^tmp[0];
assign q[0] = tmp[0];



//calculate tmp_V = (tmp + q*N)>>2   don't want *
always@(*) begin
    if(i==8'd128) next_V=0;
    else begin
      case(q)
        2'b00: next_V = (tmp_m4N_d4[256]==0)? tmp_m4N_d4 : tmp_d4;
        2'b01: next_V = (tmp_m3N_d4[256]==0)? tmp_m3N_d4 : tmp_N_d4;
        2'b10: next_V = (tmp_m2N_d4[256]==0)? tmp_m2N_d4 : tmp_2N_d4;
        2'b11: next_V = (tmp_mN_d4 [256]==0)?  tmp_mN_d4: tmp_3N_d4;
      endcase 
    end
end


//==========sequential circuit=============//
always@( posedge clk or posedge rst_n ) begin
	if(rst_n == 1 ) begin  
		V    <= 0;
    end
	else begin
		V    <= next_V;
    end
end
endmodule