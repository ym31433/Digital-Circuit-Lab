module LSB_ME(clk, rst, start, ready, M, N, e, A1);

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

reg  [7:0] fst_e_bit;
wire [7:0] next_fst_e_bit;

reg  [8:0] next_j;
reg  [7:0] next_i;
reg   ready;

//pre_processing
wire  [255:0]preOut;
wire  preReady;

//MA1
reg  [255:0] next_A1;  //A1 = S
wire  [255:0] ma1Out;

//MA2
reg  [255:0] next_A2;  //A2 = T
wire  [255:0] ma2Out;

//==== flip flops ====//
reg   [1:0] state;


reg   [8:0] j;
reg   [7:0] i;
reg   next_ready;

//MA1
reg   [255:0] A1;

//MA2
reg   [255:0] A2;


//==== combinational ckt ====//
//pre_processing
pre_processing PRE (.M(M), .N(N), .clk(clk), .rst_n(rst), .start(start), .V(preOut), .ready(preReady));
//MA1
MA_4_mod MA1 (.A(A1), .B(A2), .N(N), .clk(clk), .rst_n(rst), .V(ma1Out), .i(i));//S
//MA2
MA_4_mod MA2 (.A(A2), .B(A2), .N(N), .clk(clk), .rst_n(rst), .V(ma2Out), .i(i));//T



always@(*)begin
      if(preReady==1)begin
      next_A1 = 256'd1;
      next_A2 = preOut;
      end
      
      else if (state == S_ME && i == 8'd128 && j <=9'd255 )begin
      next_A1 = (e[j] == 1)? ma1Out: A1 ;
      next_A2 = (preReady==1)? preOut:ma2Out;
      end
      
      else begin
      next_A1 = A1;
      next_A2 = A2;
      end
      
end 



assign next_fst_e_bit=(start==1)? 8'd255:( e[fst_e_bit]==1)? fst_e_bit : fst_e_bit-1;
//FSM
always@(*) begin
    next_state = state;
    case (state)
           S_PREPROCESS    :  if(preReady==1) next_state=S_ME;
           S_ME            :  if (j==fst_e_bit+1 && i == 8'd128)next_state=S_WAIT;
           S_WAIT          :  if(start==1) next_state=S_PREPROCESS;
    endcase

end
//output_ready
always@(*) begin
    if(start == 1) next_ready = 0;
    else if(state==S_ME &&next_state == S_WAIT) next_ready = 1;
    else next_ready = ready;
end


always@(*)begin
       if(preReady==1)begin
             next_i=8'd0;
             next_j=9'd0;
       end
       if (state== S_ME && next_state==S_ME )begin
             next_i=(i == 8'd128)? 0: i+1;
             next_j=(i == 8'd128)? j+1: j;
       end
       else begin
             next_i=8'd128;
             next_j=9'd511;
       end
          

end

//==== sequencial ckt ====//
always@(posedge clk or posedge rst ) begin
  
    if(rst == 1) begin
        state <= S_WAIT;
        i     <= 8'd0;
        j     <= 9'd0;
        A1    <= 256'd0;
        A2    <= preOut;
        fst_e_bit <= 8'd255;
        ready <= 1;
    end
    
    else begin
        state <= next_state;
        i     <= next_i;
        j     <= next_j;
        A1    <= next_A1;
        A2    <= next_A2;
        fst_e_bit <= next_fst_e_bit;
        ready <= next_ready;
    end
end

endmodule