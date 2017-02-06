reg [1:0] state, next_state;
reg MA_ready, next_MA_ready, ready;

always@(*) begin
        case(state) 
            S_preprocessing:begin
                if(&MA_ready==1) begin
				   next_state = S_forloop;
				   next_MA_ready = 0;
                   count = 0;
				   
				else next_state = S_preprocessing;
            end
            S_forloop: begin
                if(&MA_ready==1&&(&count==8d'255))begin 
				   next_state = S_postprocessing;
                   next_MA_ready = 0;
				else next_state = S_forloop;
            end
	        S_postprocessing: begin
                if(&MA_ready==1) begin
				   next_state = S_empty;
				   ready = 0;
                else next_state = S_postprocessing;
            end
			S_empty: begin
				if(posedge start) next_state = S_preprocessing;
                else next_state = S_empty;
            end
        endcase
end
reg [255:0] data_M, M, M', N, A, B, result, S, T, V, MA_start;
always@(*)begin
	   if(state == S_preprocessing)begin
	       //M = data_M;
           M' = S;
		   next_result = S;
	   end
	   else if (state == S_forloop)begin
	       
	       next_A = result;
		   next_B = result;
		   next_result =  V;
	       next_count= (&MA_ready==1)?(count + 1d'1):count;
	   end
	   else if (state == S_postprocessing)begin
	       A = result;
           B = 256d'1;
	       result = V;
	   end
	   else
end

//sequential part
state<=next_state;
MA_ready<=next_MA_ready;


pre_processing pre (.M(a1), .N(N), .clk(clk), .rst_n(rst_n), .start(), .S(S), ready(MA_ready));
MA             ma  (.A(A), .B(B), .N(N), .clk(clk), .rst_n(rst_n), .start(), .V(V), .ready(MA_ready));