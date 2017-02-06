//LSB_ME
module LSB_ME(clk, rst, start, ready, M, N, e, A1); //I don't know the inputs & outputs

//==== parameters ====//
parameter S_PREPROCESS = 2'b00;
parameter S_ME = 2'b01;
parameter S_WAIT = 2'b10;

//==== inputs ====//
input clk;
input rst;
input start;

input [255:0] M;//a1
input [255:0] N;//a3
input [255:0] e;//a2
//==== outputs ====//
output [255:0] A1;//a0
output ready;

//==== wires ====//
reg   [1:0] next_state;

wire  [7:0] next_j;
wire  [7:0] next_i;

//pre_processing
wire  preOut;
wire  preReady;

//MA1
wire  [255:0] next_A1;  //A1 = S
wire  [255:0] ma1Out;

//MA2
wire  [255:0] next_A2;  //A2 = T
wire  [255:0] ma2Out;

//==== flip flops ====//
reg   [1:0] state;

reg   [7:0] j;
reg   [7:0] i;

//MA1
reg   [255:0] A1;

//MA2
reg   [255:0] A2;


//==== combinational ckt ====//

//FSM
always@(*) begin
    next_state = state;
    if(state == S_ME && &j == 1) next_state = S_WAIT; //j = 255 change state
end
//output_ready
assign ready = ( j == 8'd255)? 1:0;
//i
assign next_i = (state == S_ME)? ( (i == 8'd132)? 0: i+1 ): 8'd255;

//j
assign next_j = (state == S_ME)? ( (i == 8'd132)? ( (&j == 1)? 0: j+1 ): j ) : 8'd255;

//pre_processing
pre_processing PRE (.M(M), .N(N), .clk(clk), .rst_n(rst), .start(start), .V(preOut), .ready(preReady));

//MA1
MA_4_mod MA1 (.A(A1), .B(A2), .N(N), .clk(clk), .rst_n(rst), .V(ma1Out), .i(i));
assign next_A1 = (state == S_ME && i == 8'd132)? ( (e[j+1] == 1)? ma1Out: A1 ): A1;

//MA2
MA_4_mod MA2 (.A(A2), .B(A2), .N(N), .clk(clk), .rst_n(rst), .V(ma2Out), .i(i));
assign next_A2 = (state == S_ME && i == 8'd132)? ma2Out: A2;


//==== sequencial ckt ====//
always@(posedge clk or negedge rst or posedge preReady or posedge start) begin
    if(rst == 0) begin
        state <= S_WAIT;
        i     <= 8'd255;
        j     <= 8'd255;
        A1    <= 256'd0;
        A2    <= preOut;
    end
    else if(preReady == 1) begin
        state <= S_ME;
        i     <= 0;
        j     <= 8'd255;
        A1    <= 256'd0;
        A2    <= preOut;
    end
    else if(start == 1) begin
        state <= S_PREPROCESS;
        i     <= 8'd255;
        j     <= 8'd255;
        A1    <= 256'd0;
        A2    <= preOut;
    end
    else begin
        state <= next_state;
        i     <= next_i;
        j     <= next_j;
        A1    <= next_A1;
        A2    <= next_A2;
    end
end

endmodule