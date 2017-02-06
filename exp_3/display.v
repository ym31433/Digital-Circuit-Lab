module display(rst, clk, state, ready, data);
	input rst, clk;
	input [8:0] state;
	input ready;

	output [7:0] data;

	reg   [7:0] regdata1[0:15];
	reg   [7:0] regdata2[0:15];

	reg   [4:0] step_r;
	wire  [4:0] step_w;

	reg  line_r;
	wire line_w;

	parameter S_WAIT   = 5'd1;
	parameter S_RECORD = 5'd2;
	parameter S_PAUSE  = 5'd3;

	integer i;

	assign step_w = (ready == 1'b1 || step_r == 5'd0)? 5'd16: step_r-5'd1;
	assign line_w = (step_r = 5'd0)? ~line_r: line_r;
	assign data = (line_r == 1'b0)? regdata1[step_r]: regdata2[step_r];

	always@(*) begin
		for(i = 15; i >= 0; i = i-1) begin
			regdata1[i] = 8'b1111_1110;
			regdata2[i] = 8'b1111_1110;
		end

      if( state[6]==1'd0) begin
        
				regdata1[10] = 8'b0101_0000;//P
				regdata1[9] = 8'b0100_0001; //A
				regdata1[8] = 8'b0101_0101; //U
				regdata1[7] = 8'b0101_0011; //S
				regdata1[6] = 8'b0100_0101; //E
                regdata1[5] = 8'b1111_1110;
      end


		case(state[8:7])
			2'd2: begin                       //waiting

				regdata1[9] = 8'b0101_0111; //W
				regdata1[8] = 8'b0100_0001; //A
				regdata1[7] = 8'b0100_1001; //I
				regdata1[6] = 8'b0101_0100; //T

			end
			2'd3:begin                       //record

				regdata1[10] = 8'b0101_0010;  //R
				regdata1[9] = 8'b0100_0101;   //E
				regdata1[8] = 8'b0100_0011;   //C
				regdata1[7] = 8'b0100_1111;   //O
				regdata1[6] = 8'b0101_0010;   //R
				regdata1[5] = 8'b0100_0100;   //D

			end
		 endcase 

	    case (state[5] && state[8:7]== 2'd1 && state[6]==1'd1)
                1'd0:begin
                regdata2[10] = 8'b0100_0110;//F
   				regdata2[9] = 8'b0100_1111;//O
   				regdata2[8] = 8'b0101_0010;//R
   				regdata2[7] = 8'b0101_0111;//W
   				regdata2[6] = 8'b0100_0001;//A
   				regdata2[5] = 8'b0101_0010;//R
   				regdata2[4] = 8'b0100_0100;//D

                end

                1'd1:begin
                regdata2[11] = 8'b0100_0010;//B
   				regdata2[10] = 8'b0100_0001;//A
   				regdata2[9] = 8'b0100_0011;//C
   				regdata2[8] = 8'b0100_1011;//K
   				regdata2[7] = 8'b0101_0111;//W
   				regdata2[6] = 8'b0100_0001;//A
   				regdata2[5] = 8'b0101_0010;//R
   				regdata2[4] = 8'b0100_0100;//D
   				end

        endcase 

         if( state[8:7] == 2'd1 && state[2:0]==3'd0 && state[6]==1'd1) begin
                regdata1[10] = 8'b0100_1110;//N
   				regdata1[9] = 8'b0100_1111;//O
   				regdata1[8] = 8'b0101_0010;//R
   				regdata1[7] = 8'b0100_1101;//M
   				regdata1[6] = 8'b0100_0001;//A
   				regdata1[5] = 8'b0100_1100;//L
         end

         else if ( state[6]==1'd1 )begin


            	regdata1[12] = 8'b0101_0100;//T
   				regdata1[11] = 8'b0100_1001;//I
   				regdata1[10] = 8'b0100_1101;//M
   				regdata1[9] = 8'b0100_0101;//E
   				regdata1[8] = 8'b0101_0011;//S

           case ( state[2:0])
			3'd1: 	regdata1[14] = 8'b0011_0010;//2
			3'd2: 	regdata1[14] = 8'b0011_0011;//3
			3'd3: 	regdata1[14] = 8'b0011_0100;//4
			3'd4: 	regdata1[14] = 8'b0011_0101;//5
			3'd5: 	regdata1[14] = 8'b0011_0110;//6
			3'd6: 	regdata1[14] = 8'b0011_0111;//7
			3'd7: 	regdata1[14] = 8'b0011_1000;//8
			default: ;
           endcase 
           

           case ( state[3])
                1'd0:begin
                regdata1[6] = 8'b0100_0110;//F
   				regdata1[5] = 8'b0100_0001;//A
   				regdata1[4] = 8'b0101_0011;//S
   				regdata1[3] = 8'b0101_0100;//T
   				regdata1[2] = 8'b0100_0101;//E
   				regdata1[1] = 8'b0101_0010;//R


                end

                1'd1:begin
                regdata1[6] = 8'b0101_0011;//s
   				regdata1[5] = 8'b0100_1100;//L
   				regdata1[4] = 8'b0100_1111;//O
   				regdata1[3] = 8'b0101_0111;//W
   				regdata1[2] = 8'b0100_0101;//E
   				regdata1[1] = 8'b0101_0010;//R
                end

           endcase 
 


            case ( state[4] && state[3]== 1'd1)
   				1'd1:regdata2[3] = 8'b0011_0001;//1
   				1'd0:regdata2[3] = 8'b0011_0000;//0

		    endcase
	end

	always@(posedge clk or negedge rst) begin
		if(rst == 1'b0) begin
			line_r <= 1'b0;
			step_r <= 5'd16;
		end

		else begin
			line_r <= line_w;
			step_r <= step_w;
		end
	end
endmodule