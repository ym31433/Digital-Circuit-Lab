module lcd(rst, clk, RS, RW, DB, E_r, data, ready);

	input rst, clk;     //clk is 5M
	input [7:0] data;
	output RS, RW, E_r;
	output [7:0] DB;
	output ready;

	reg  RS, RW;
	reg  [7:0] DB;
	reg  E_r, E_w;

	reg  [3:0] state_r, state_w;
	reg  [5:0] step_r;
	wire [5:0] step_w;
	reg  [15:0] counter_r;
    wire [15:0] counter_w;
    reg  [1:0] count_r;    //one cycle 500ns
    wire [1:0] count_w;

	parameter S_WAIT1 = 4'd0;
    parameter S_WAIT2 = 4'd1;
    parameter S_WAIT3 = 4'd2;
    parameter S_BF1   = 4'd3 ;
	parameter S_FNSET = 4'd4 ;
    parameter S_BF2   = 4'd5 ;
	parameter S_DPON  = 4'd6 ;
    parameter S_BF3   = 4'd7 ;
	parameter S_DPCLR = 4'd8 ;
    parameter S_BF4   = 4'd9 ;
	parameter S_EMSET = 4'd10;
    parameter S_BF5   = 4'd11;
	parameter S_WRITE = 4'd12;

	assign count_w = count_r + 2'd1;

	always@(*) begin
		state_w = state_r;
		case(state_r)
			S_WAIT1:
				if(counter_r == 16'd27030) state_w = S_WAIT2;
            S_WAIT2:
				if(counter_r == 16'd7390) state_w = S_WAIT3;
            S_WAIT3:
				if(counter_r == 16'd185) state_w = S_BF1;
            S_BF1:
                if(DB[7] == 0) state_w = S_FNSET;
			S_FNSET:
				state_w = S_BF2;
            S_BF2:
                if(DB[7] == 0) state_w = S_DPON;
			S_DPON:
				state_w = S_BF3;
            S_BF3:
                if(DB[7] == 0) state_w = S_DPCLR;
			S_DPCLR:
				state_w = S_BF4;
            S_BF4:
                if(DB[7] == 0) state_w = S_EMSET;
			S_EMSET:
				state_w = S_BF5;
            S_BF5:
                if(DB[7] == 0) state_w = S_WRITE;
			S_WRITE:
                state_w = S_WRITE;
		endcase
	end

	//assign E = (counter_r == 9'd0 || state_r == S_WRITE)? ((count_r == 2'd0 || count_r == 2'd2)? ~E: E) : 1'b0;
	always@(*) begin
		E_w = 1'b0;
		if( (counter_r == 9'd0 || state_r == S_WRITE) && (count_r == 2'd0 || count_r == 2'd1) ) begin
			E_w = 1'b1;
		end
	end

	assign counter_w = (state_r != state_w)? 9'd0: (count_r == 2'd3)? counter_r + 9'd1: counter_r;
	assign step_w = ((state_r == S_BF5 && state_w == S_WRITE) || step_r == 6'd34)? 6'd0: (count_r == 2'd3)? step_r+6'd1: step_r;
	assign ready = (state_r == S_BF5 && state_w == S_WRITE)? 1'b1: 1'b0;

    
	always@(*) begin
		RS = 1'b0;
		RW = 1'b0;
		DB = 8'b0000_0000;
		case(state_r)
			S_WAIT1: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0011_0000;
			end
            S_WAIT2: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0011_0000;
			end
            S_WAIT3: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0011_0000;
			end
			S_FNSET: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0011_1000;
			end
			S_DPON: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0000_1100;
			end
			S_DPCLR: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0000_0001;
			end
			S_EMSET: begin
				RS = 1'b0;
				RW = 1'b0;
				DB = 8'b0000_0110;
			end
			S_WRITE: begin
				if(step_r == 6'd0) begin
					RS = 1'b0;
					RW = 1'b0;
					DB = 8'b1000_0000;
				end
				else if(step_r == 6'd17) begin
					RS = 1'b0;
					RW = 1'b0;
					DB = 8'b1100_0000;
				end
				else begin
					RS = 1'b1;
					RW = 1'b0;
					DB = data;
				end
			end
            default: begin   // BF check
                RS = 1'b0;
                RW = 1'b1;
                //DB[7] = 1'bz;
            end
		endcase
	end

	always@(posedge clk, negedge rst) begin
		if(rst == 1'b0) begin
			counter_r <= 9'd0;
			state_r   <= S_WAIT1;
			step_r    <= 6'd0;
			count_r   <= 2'd0;
		end
		else begin
			counter_r <= counter_w;
			state_r   <= state_w;
			step_r    <= step_w;
			count_r   <= count_w;
		end
	end

endmodule