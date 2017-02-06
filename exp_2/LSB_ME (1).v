module LSB_ME(clk, rst, start, ready, M, N, e, S);

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
output [255:0] S;//a0
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
reg  [255:0] next_V1  ,next_V2; 
reg  [255:0] V1       ,V2;
reg  [1:0]   tmp1     ,tmp2;
reg  [257:0] tempT1   ,tempT2; 
reg  [257:0] tempN1   ,tempN2;
reg  [258:0] tempV1_1 ,tempV2_1;
reg  [258:0] tempV1_2 ,tempV2_2;
 
wire  [1:0]   q1,q2;
wire  [7:0]   i_2,i_2_p1;
//==== flip flops ====//
reg   [1:0] state;


reg   [8:0] j;
reg   [7:0] i;
reg   next_ready;

//MA1
reg   [255:0] S,next_S;

//MA2
reg   [255:0] T,next_T;


//==== combinational ckt ====//
//pre_processing
assign next_fst_e_bit=(start==1)? 8'd255:(e[fst_e_bit]==1)? fst_e_bit : fst_e_bit-8'd1;

pre_processing PRE (.M(M), .N(N), .clk(clk), .rst_n(rst), .start(start), .V(preOut), .ready(preReady));

assign i_2       = i<<1;
assign i_2_p1    = i_2+8'd1;



always@(*) begin
    if(S[i_2_p1] == 0) begin
        if(S[i_2] == 0)   tempT1=258'd0; 
        else                 tempT1=T;

    end
    else begin
        if(S[i_2] == 0)   tempT1=(T<<1);              
        else                 tempT1=(T+(T<<1));
    end 
    tmp1=V1[1:0]+tempT1[1:0];
end

assign q1[1] = tmp1[1]^tmp1[0];
assign q1[0] = tmp1[0];


always@(*) begin
    
    case(q1)
        2'b00:begin 
        tempN1 = 258'd0  ; 
        end
        2'b01:begin 
        tempN1 = N ;   
        end
        2'b10:begin 
        tempN1 =(N<<1);         
        end
        2'b11:begin 
        tempN1 =((N<<1)+N);         
        end
      endcase 
    
    tempV1_1=(V1+tempT1+tempN1)>>2;
    tempV1_2=((V1-(N<<2))+tempT1+tempN1)>>2;
    
end

always@(*) begin
   if(i==8'd128)     next_V1=0;
    else             next_V1= (tempV1_2[256]==0)?tempV1_2[255:0]:tempV1_1[255:0];
end


always@(*) begin
    if(T[i_2_p1] == 0) begin
        if(T[i_2] == 0)   tempT2=258'd0; 
        else              tempT2=T;
                                  
    end                           
    else begin                    
        if(T[i_2] == 0)   tempT2=(T<<1);              
        else              tempT2=(T+(T<<1));
    end 
    tmp2=V2[1:0]+tempT2[1:0];
end

assign q2[1] = tmp2[1]^tmp2[0];
assign q2[0] = tmp2[0];

always@(*) begin

      case(q2)
        2'b00:begin 
        tempN2 = 258'd0  ; 
        end
        2'b01:begin 
        tempN2 = N ;      
        end
        2'b10:begin 
        tempN2 =(N<<1);         
        end
        2'b11:begin 
        tempN2 =((N<<1)+N);         
        end
      endcase 

    tempV2_1=(V2+tempT2+tempN2)>>2;
    tempV2_2=((V2-(N<<2))+tempT2+tempN2)>>2;
   
end
always@(*) begin

    if(i==8'd128) next_V2=0;
    else next_V2= (tempV2_2[256]==0)? tempV2_2[255:0]:tempV2_1[255:0];
end


//==========sequential circuit=============//
always@( posedge clk or posedge rst ) begin
	if(rst == 1 ) begin  
		V1    <= 256'd0;
        V2    <= 256'd0;
    end
	else begin
		V1    <= next_V1;
        V2    <= next_V2;
    end
end


always@(*)begin
      if(preReady==1)begin
      next_S = 256'd1;
      next_T = preOut;
      end
      
      else if (state == S_ME && i == 8'd128 && j <=(fst_e_bit))begin
      next_S = (e[j] == 1)? V1: S ;
      next_T = V2;
      end
      
      else begin
      next_S = S;
      next_T = T;
      end
      
end 


//FSM
always@(*) begin
    next_state = state;
    case (state)
           S_PREPROCESS    :  if(preReady==1) next_state=S_ME;
           S_ME            :  if (j==(fst_e_bit+1)&& i == 8'd128)next_state=S_WAIT;
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
             next_i=(i == 8'd128)? 8'd0: i+8'd1;
             next_j=(i == 8'd128)? j+8'd1: j;
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
        S    <= 256'd0;
        T    <= 256'd0;
        fst_e_bit <= 8'd0;
        ready <= 1'd1;
    end
    
    else begin
        state <= next_state;
        i     <= next_i;
        j     <= next_j;
        S    <= next_S;
        T    <= next_T;
        fst_e_bit<=next_fst_e_bit;
        ready <= next_ready;
    end
end

endmodule