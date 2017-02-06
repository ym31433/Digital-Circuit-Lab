module exp1_traffic (
    clk, 
    rst_n,
    pause, 
    change_phase,
    b_switch,
    HEX0,HEX1,//countdown
    HEX4,
    HEX6,HEX7,//period of next phase
    light,
    unused_light,
	pattern,
    LCD_DATA,
    LCD_RW,
    LCD_EN,
    LCD_RS
);

//==== parameter definition ===============================
    // for finite state machine
    parameter S_NORMAL  = 1'd0;
    parameter S_PAUSE   = 1'd1;
    // for countdown
    parameter C_PERIOD = 7'd20;
    
//==== in/out declaration ==================================
    //-------- input ---------------------------
    input clk;
    input rst_n; // reset signal (button)
    input pause; // pause signal (switch)
    input change_phase; // change phase signal (button)
    input [6:0] b_switch;//for period assigned
    
    //-------- output --------------------------------------
    output [6:0] HEX0;
    output [6:0] HEX1;
    output [6:0] HEX4;
    output [6:0] HEX6;
    output [6:0] HEX7;
    output [9:0] light;
    output [16:0] unused_light = {17{1'b0}};
	output [23:0] pattern;
    output [7:0]LCD_DATA;
    output LCD_RW,LCD_EN,LCD_RS;

//==== reg/wire declaration ================================
    //-------- output --------------------------------------
    wire [6:0] HEX0;
    wire [6:0] HEX1;
    wire [6:0] HEX4;
    wire [6:0] HEX6;
    wire [6:0] HEX7;
    reg  [9:0] light;
    wire [7:0] LCD_DATA;
    wire LCD_RW,LCD_EN,LCD_RS;
    //-------- wires ---------------------------------------
    wire clk_16; // 16MHz clock signal
    wire [23:0] next_clks;
    reg         next_state;
    reg   [7:0] next_countdown;
    wire  [6:0] next_HEX0;
    wire  [6:0] next_HEX1;
    wire  [6:0] next_HEX4;
    wire  [6:0] next_HEX6;
    wire  [6:0] next_HEX7;
    reg   [9:0] next_light;
    reg   [3:0] next_phase;
    wire  [2:0] next_button_cp; // button state -- change phase manually
    reg   [6:0] next_cperiod;
    
    //-------- flip-flops ----------------------------------    
    reg [23:0] clks;
    reg        state;   
    reg  [7:0] countdown; 
    reg  [3:0] phase;
    wire [2:0] button_cp; // button state -- change phase manually
    reg  [6:0] cperiod;
     
//==== combinational part ==================================
    
    // clock signal
    clksrc clksrc1 (clk, clk_16);   
    assign next_clks = (state==S_PAUSE)? clks: (button_cp == 3'd7)? 24'd0: clks+24'd1;
    
    // finite state machine (state)
    always@(*) begin
        case(state) 
            S_NORMAL: begin
                if(pause==1) next_state = S_PAUSE;
                else next_state = S_NORMAL;
            end
            S_PAUSE: begin
                if(pause==1) next_state = S_PAUSE;
                else next_state = S_NORMAL;
            end
        endcase
    end
    
    // countdown
    always@(*) begin
        if(button_cp == 3'd7)
            next_countdown = cperiod; 
        else if(clks[23] == 1'b1 && next_clks[23] == 1'b0) 
            next_countdown = (countdown==0)? cperiod: countdown-4'd1;  
        else 
            next_countdown = countdown;
    end 
    
    //Print words on LCD
    LCD_TEST LCD_test (clk,rst_n,phase,next_phase,LCD_DATA,LCD_RW,LCD_EN,LCD_RS);
    
    // 7-segment Displays
    display_2digits display_countdown (
    .clk       (clk),
    .rst_n     (rst_n),
    .HEX0      (HEX0),
    .next_HEX0 (next_HEX0),
    .HEX1      (HEX1),
    .next_HEX1 (next_HEX1),
    .num       (countdown)
    );
     
    
    display8x8 display( clks, next_clks, clk_16, phase, rst_n, pattern);
    
    //change phase
    button change_phase_button (
    .clk        (clk_16),
    .rst_n      (rst_n),
    .button     (change_phase),
    .state      (button_cp),
    .next_state (next_button_cp)
    );
    
    always@(*) begin
        if( button_cp == 3'd7 || (countdown == 4'd0 && next_countdown == cperiod) )
            next_phase = (phase == 4'd9)? 4'd0: phase+4'd1;
        else
            next_phase = phase;
    end
    
    //change phase & light
    always@(*) begin
          case(phase)
               4'd0: next_light = 10'b0010_1100_10;
               4'd1: begin
                   if(clks[20]== 1'b1 && next_clks[20]== 1'b0 ) next_light[5]=~light[5];
                   else next_light=light;
               end
               4'd2: next_light = 10'b0011_0100_10;
               4'd3: next_light = 10'b0101_0100_10;
               4'd4: next_light = 10'b1001_0100_10;
               4'd5: next_light = 10'b1001_0001_01;
               4'd6:begin
                   if(clks[20]== 1'b0 && next_clks[20]== 1'b1 ) next_light[0]=~light[0];
                   else next_light=light;
               end
               4'd7: next_light = 10'b1001_0001_10;
               4'd8: next_light = 10'b1001_0010_10;
               4'd9: next_light = 10'b1001_0100_10;
               default: next_light = 10'b1111_1111_11;
          endcase
    end
    
    //SETTING -- 7-segment display -- current phase
    display_1digit display_currentphase (
    .clk       (clk_16),
    .rst_n     (rst_n),
    .HEX       (HEX4),
    .next_HEX  (next_HEX4),
    .num       (phase)
    );
    
    //SETTING -- 7-segment display -- period of next phase
    display_2digits display_cperiod (
    .clk       (clk_16),
    .rst_n     (rst_n),
    .HEX0      (HEX6),
    .next_HEX0 (next_HEX6),
    .HEX1      (HEX7),
    .next_HEX1 (next_HEX7),
    .num       (cperiod)
    );
    
    //SETTING -- cperiod -- time control of next phase
    always@(*) begin
        if(|b_switch == 0)
            next_cperiod = C_PERIOD;
        else begin
            next_cperiod[0] = b_switch[0];
            next_cperiod[1] = b_switch[1];
            next_cperiod[2] = b_switch[2];
            next_cperiod[3] = b_switch[3];
            next_cperiod[4] = b_switch[4];
            next_cperiod[5] = b_switch[5];
            next_cperiod[6] = b_switch[6];
        end
    end


//==== sequential part =====================================  
    always@( posedge clk_16 or negedge rst_n ) begin
    
        if( rst_n==0) begin
            clks           <= 24'hfffff0;
            state          <= S_NORMAL;
            countdown      <= 0;
            light          <= 10'b0010_1100_10;
            phase          <= 4'd9;
            cperiod        <= next_cperiod;
        end 
        else begin
            clks           <= next_clks;
            state          <= next_state;
            countdown      <= next_countdown;
            light          <= next_light;
            phase          <= next_phase;
            cperiod        <= next_cperiod;
        end        
    end 

endmodule



//module to use:


//button state
module button( clk, rst_n, button, state, next_state);
    
    input  clk, rst_n, button;
    inout  [2:0] state;
    output [2:0] next_state;
    
    reg    [2:0] state;
    reg    [2:0] next_state;
    
    always@(*) begin
        case(state)
            3'd0: next_state = (button)? 3'd0: 3'd1;
            3'd1: next_state = (button)? 3'd0: 3'd2;
            3'd2: next_state = (button)? 3'd0: 3'd3;
            3'd3: next_state = 3'd4;
            3'd4: next_state = (button)? 3'd5: 3'd4;
            3'd5: next_state = (button)? 3'd6: 3'd4;
            3'd6: next_state = (button)? 3'd7: 3'd4;
            3'd7: next_state = 3'd0;
        endcase
    end
    
    always@(posedge clk, negedge rst_n) begin
        if(rst_n == 0)
            state <= 3'd0;
        else
            state <= next_state;
    end
endmodule

//7-segment -- 1digit
module display_1digit( clk, rst_n, num, HEX, next_HEX);
    
    input  clk, rst_n;
    input  [3:0] num;
    output [6:0] HEX;
    output [6:0] next_HEX;
    
    reg [6:0] HEX;
    reg [6:0] next_HEX;
   
    always@(*) begin
        case(num)
            4'd0: next_HEX = 7'b1000000;
            4'd1: next_HEX = 7'b1111001;
            4'd2: next_HEX = 7'b0100100;
            4'd3: next_HEX = 7'b0110000;
            4'd4: next_HEX = 7'b0011001;
            4'd5: next_HEX = 7'b0010010;
            4'd6: next_HEX = 7'b0000010;
            4'd7: next_HEX = 7'b1111000;
            4'd8: next_HEX = 7'b0000000;
            4'd9: next_HEX = 7'b0010000;
            default: next_HEX = 7'b1111111;
        endcase
    end
    
    always@(posedge clk, negedge rst_n) begin
        if(rst_n == 0)
            HEX <= 7'h7f;
        else
            HEX <= next_HEX;
    end
endmodule

//7-segment -- 2digits
module display_2digits( clk, rst_n, num, HEX0, HEX1, next_HEX0, next_HEX1);
    
    input   clk,rst_n;
    input   [6:0] num;
    output  [6:0] HEX0,HEX1;
    output  [6:0] next_HEX0,next_HEX1;
   
    //wire
    reg     [6:0] HEX0, HEX1;
    reg     [6:0] next_HEX0, next_HEX1;
    
    always@(*) begin
        case(num%10)
            7'd0: next_HEX0 = 7'b1000000;
            7'd1: next_HEX0 = 7'b1111001;
            7'd2: next_HEX0 = 7'b0100100;
            7'd3: next_HEX0 = 7'b0110000;
            7'd4: next_HEX0 = 7'b0011001;
            7'd5: next_HEX0 = 7'b0010010;
            7'd6: next_HEX0 = 7'b0000010;
            7'd7: next_HEX0 = 7'b1111000;
            7'd8: next_HEX0 = 7'b0000000;
            7'd9: next_HEX0 = 7'b0010000;
            default: next_HEX0 = 7'b1111111;
        endcase
    end
    always@(*) begin
        case((num/10)%10)
            7'd0: next_HEX1 = 7'b1000000;
            7'd1: next_HEX1 = 7'b1111001;
            7'd2: next_HEX1 = 7'b0100100;
            7'd3: next_HEX1 = 7'b0110000;
            7'd4: next_HEX1 = 7'b0011001;
            7'd5: next_HEX1 = 7'b0010010;
            7'd6: next_HEX1 = 7'b0000010;
            7'd7: next_HEX1 = 7'b1111000;
            7'd8: next_HEX1 = 7'b0000000;
            7'd9: next_HEX1 = 7'b0010000;
            default: next_HEX1 = 7'b1111111;
        endcase
    end
    
    always@(posedge clk, negedge rst_n) begin
        if(rst_n == 0) begin
            HEX0  <=  7'h7f;
            HEX1  <=  7'h7f;
        end
        else begin
            HEX0  <=  next_HEX0;
            HEX1  <=  next_HEX1;
        end
    end
endmodule


// dot matrix
module display8x8 (clks,next_clks,clk_16,phase,rst_n,pattern) ;

    input [23:0] clks, next_clks;
    input [3:0]  phase;
    input rst_n, clk_16;
    output [23:0] pattern;
    
    // if pause only a row will be displayed
    wire [23:0] nextlocalclock;
    reg  [23:0] localclock, npattern, pattern ;
    reg  [2:0]  nextpstate; 
    reg  [3:0]  pstate, frame, next_frame;
    
    assign nextlocalclock=localclock+1'b1;
    
    //row control
    always@(*)begin
        if( localclock[14]==1'b0 && nextlocalclock[14]==1'b1)
            case (pstate)
                3'd0: nextpstate= 3'd1; 
                3'd1: nextpstate= 3'd2;
                3'd2: nextpstate= 3'd3;
                3'd3: nextpstate= 3'd4;
                3'd4: nextpstate= 3'd5;
                3'd5: nextpstate= 3'd6;
                3'd6: nextpstate= 3'd7;
                3'd7: nextpstate= 3'd0;
                default: nextpstate= 3'd0;
            endcase
        else
            nextpstate=pstate;
    end
    //frame control
    always@(*)begin
         if(clks[19]===1'b0 && next_clks [19]==1'b1)
              next_frame=(frame==17)? 4'd0 : frame+1;
         else
              next_frame=frame;
    end
    //3 case for r,y,g dot matrix
    always@(*)begin
        case(phase)
            4'd0://green
            case(frame)
                4'd0,4'd1,4'd2,:
                case(pstate)
                      3'd0: npattern= 24'b111110010010011011011011 ;
                      3'd1: npattern= 24'b110011010010011011011010 ;
                      3'd2: npattern= 24'b110110011010011011011011 ;
                      3'd3: npattern= 24'b110110010011011010010010 ;
                      3'd4: npattern= 24'b010010110010010011011110 ;
                      3'd5: npattern= 24'b110110110010010011111010 ;
                      3'd6: npattern= 24'b110010010110011111010011 ;
                      3'd7: npattern= 24'b010110110110110010011011 ;
                      default: npattern= 24'b0;
                endcase
                4'd3,4'd4,4'd5,4'd15,4'd16,4'd17:
                case(pstate)
                      3'd0: npattern= 24'b111110010010011011011011 ;
                      3'd1: npattern= 24'b110011010010011011011010 ;
                      3'd2: npattern= 24'b110110011010011011011011 ;
                      3'd3: npattern= 24'b110110010011011011010010 ;
                      3'd4: npattern= 24'b110010110010011010011110 ;
                      3'd5: npattern= 24'b010110110010010011111010 ;
                      3'd6: npattern= 24'b110110010110011111011010 ;
                      3'd7: npattern= 24'b110010110110111010010011 ;
                      default: npattern= 24'b0;                      
                endcase
                4'd6,4'd7,4'd8,4'd12,4'd13,4'd14:
                case(pstate)
                      3'd0: npattern= 24'b111110010010011011011011 ;
                      3'd1: npattern= 24'b110011010010011011011010 ;
                      3'd2: npattern= 24'b110110011010011011011011 ;
                      3'd3: npattern= 24'b110110010011011011010010 ;
                      3'd4: npattern= 24'b110110010010011011010110 ;
                      3'd5: npattern= 24'b110010110010011010111010 ;
                      3'd6: npattern= 24'b110110110010011111011010 ;
                      3'd7: npattern= 24'b110110010110111011011010 ;
                      default: npattern= 24'b0;
                endcase
                4'd9,4'd10,4'd11:
                case(pstate)
                      3'd0: npattern= 24'b111110010010011011011011  ;
                      3'd1: npattern= 24'b110011010010011011011010  ;
                      3'd2: npattern= 24'b110110011010011011011011  ;
                      3'd3: npattern= 24'b110110010011011011010010  ;
                      3'd4: npattern= 24'b110110010010011011010110  ;
                      3'd5: npattern= 24'b110110010010011011110010  ;
                      3'd6: npattern= 24'b110110110010011111011010  ;
                      3'd7: npattern= 24'b110110110010111011011010  ;
                      default: npattern= 24'b0;
                endcase
                default: ;
            endcase                  
            4'd1:  //yellow
            case(frame)
                4'd0,4'd12:
                case(pstate)
                      3'd0: npattern= 24'b111110000000011011011011;
                      3'd1: npattern= 24'b110001000000011011011000;
                      3'd2: npattern= 24'b110110001000011011011011;
                      3'd3: npattern= 24'b110110000001011000000000;
                      3'd4: npattern= 24'b000000110000000011011100;
                      3'd5: npattern= 24'b110110110000000011111000;
                      3'd6: npattern= 24'b110000000110011111000011;
                      3'd7: npattern= 24'b000110110110100000011011;
                      default: npattern= 24'b0;
                endcase
                4'd1,4'd5,4'd13,4'd17:
                case(pstate)
                      3'd0: npattern= 24'b111110000000011011011011;
                      3'd1: npattern= 24'b110001000000011011011000;
                      3'd2: npattern= 24'b110110001000011011011011;
                      3'd3: npattern= 24'b110110000001011011000000;
                      3'd4: npattern= 24'b110000110000011000011100;
                      3'd5: npattern= 24'b000110110000000011111000;
                      3'd6: npattern= 24'b110110000110011111011000;
                      3'd7: npattern= 24'b110000110110111000000011;
                      default: npattern= 24'b0;                      
                endcase
                4'd2,4'd4,4'd14,4'd16:
                case(pstate)
                      3'd0: npattern= 24'b111110000000011011011011;
                      3'd1: npattern= 24'b110001000000011011011000;
                      3'd2: npattern= 24'b110110001000011011011011;
                      3'd3: npattern= 24'b110110000001011011000000;
                      3'd4: npattern= 24'b110110000000011011000100;
                      3'd5: npattern= 24'b110000110000011000111000;
                      3'd6: npattern= 24'b110110110000011111011000;
                      3'd7: npattern= 24'b110110000110111011011000;
                      default: npattern= 24'b0;
                endcase
                4'd3,4'd15:
                case(pstate)
                      3'd0: npattern= 24'b111110000000011011011011;
                	  3'd1: npattern= 24'b110001000000011011011000;
                      3'd2: npattern= 24'b110110001000011011011011;
                      3'd3: npattern= 24'b110110000001011011000000;
                      3'd4: npattern= 24'b110110000000011011000100;
                      3'd5: npattern= 24'b110110000000011011100000;
                      3'd6: npattern= 24'b110110110000011111011000;
                      3'd7: npattern= 24'b110110110000111011011000;
                      default: npattern= 24'b0;
                endcase
                default:
                case(pstate)
                      3'd0: npattern= 24'b111110110110011011011011;
                      3'd1: npattern= 24'b110111110110011011011011;
                      3'd2: npattern= 24'b110110111110011011011011;
                      3'd3: npattern= 24'b110110110111011011011011;
                      3'd4: npattern= 24'b110110110110011011011111;
                      3'd5: npattern= 24'b110110110110011011111011;
                      3'd6: npattern= 24'b110110110110011111011011;
                      3'd7: npattern= 24'b110110110110111011011011;
                      default: npattern= 24'b0;
                endcase
            endcase            
            default: //red
                case(pstate)
                      3'd0: npattern= 24'b111110110100011011011001;
    	              3'd1: npattern= 24'b110111100100011011001001;
                      3'd2: npattern= 24'b110110111100011011011001;
                      3'd3: npattern= 24'b110110100101011011001001;
                      3'd4: npattern= 24'b110100110100011001011101;
                      3'd5: npattern= 24'b110110110100011011111001;
                      3'd6: npattern= 24'b110110100110011111001011;
                      3'd7: npattern= 24'b110100110110111001011011;
                      default: npattern= 24'b0;
                endcase
        endcase
    end

    always@(posedge clk_16 or negedge rst_n)begin
        if( rst_n==0)begin
            frame   <= 4'd0;
            pattern <= 24'b0;
            pstate  <= 0 ;
        end
        else begin
            frame   <= next_frame;
            pstate  <= nextpstate;
            pattern <= npattern;
            localclock  <= nextlocalclock;
        end
    end

endmodule


 module	LCD_TEST (	//	Host Side
                    iCLK,iRST_N,phase,next_phase,
                    //	LCD Side
                    LCD_DATA,LCD_RW,LCD_EN,LCD_RS );
                    
    //	Host Side
    input			iCLK,iRST_N;
    input [3:0] phase,next_phase;
    //	LCD Side
    output	[7:0]	LCD_DATA;
    output			LCD_RW,LCD_EN,LCD_RS;
    //	Internal Wires/Registers
    reg	[5:0]	LUT_INDEX;
    reg	[8:0]	LUT_DATA;
    reg	[5:0]	mLCD_ST;
    reg	[17:0]	mDLY;
    reg			mLCD_Start;
    reg	[7:0]	mLCD_DATA;
    reg			mLCD_RS;
    wire		mLCD_Done;
    
    parameter	LCD_INTIAL	=	0;
    parameter	LCD_LINE1	=	5;
    parameter	LCD_CH_LINE	=	LCD_LINE1+16;
    parameter	LCD_LINE2	=	LCD_LINE1+16+1;
    parameter	LUT_SIZE	=	LCD_LINE1+32+1;

    always@(posedge iCLK or negedge iRST_N)
    begin
    	if( !iRST_N  )
    	begin
    		LUT_INDEX	<=	0;
    		mLCD_ST		<=	0;
    		mDLY		<=	0;
    		mLCD_Start	<=	0;
    		mLCD_DATA	<=	0;
    		mLCD_RS		<=	0;
    	end
        else if ( iRST_N&&(phase!=next_phase))
        begin
            LUT_INDEX	<=	0;
    		mLCD_ST		<=	0;
    		mDLY		<=	0;
    		mLCD_Start	<=	0;
    		mLCD_DATA	<=	0;
    		mLCD_RS		<=	0;
        end
    	else
    	begin
    		if(LUT_INDEX<LUT_SIZE)
    		begin
    			case(mLCD_ST)
    			0:	begin
    					mLCD_DATA	<=	LUT_DATA[7:0];
    					mLCD_RS		<=	LUT_DATA[8];
    					mLCD_Start	<=	1;
    					mLCD_ST		<=	1;
    				end
    			1:	begin
    					if(mLCD_Done)
    					begin
    						mLCD_Start	<=	0;
    						mLCD_ST		<=	2;					
    					end
    				end
    			2:	begin
    					if(mDLY<18'h3FFFE)
    					mDLY	<=	mDLY+1;
    					else
    					begin
    						mDLY	<=	0;
    						mLCD_ST	<=	3;
    					end
    				end
    			3:	begin
    					LUT_INDEX	<=	LUT_INDEX+1;
    					mLCD_ST	<=	0;
    				end
    			endcase
    		end
        end
    end

    always
    begin
      case(phase)
        4'd0:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110001;//1
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
    	
        4'd1:case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110010;//2
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b100100001;//!
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		LUT_DATA	<=	9'h120;
        endcase
        
        4'd2:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110011;//3
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        4'd3:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110100;//4
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b100100001;//!
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        4'd5:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110110;//6
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101001111;//O
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        4'd6:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110111;//7
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b100100001;//!
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        
        4'd7:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100111000;//8
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101001111;//O
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        
        4'd8:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100111001;//9
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b100100001;//!
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        4'd9:
    	case(LUT_INDEX)
    	   //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110001;//1
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'b100110000;//0
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		    LUT_DATA	<=	9'h120;
        endcase
        default:case(LUT_INDEX)
           //	Initial
    	   LCD_INTIAL+0:	LUT_DATA	<=	9'h038;
    	   LCD_INTIAL+1:	LUT_DATA	<=	9'h00C;
    	   LCD_INTIAL+2:	LUT_DATA	<=	9'h001;
    	   LCD_INTIAL+3:	LUT_DATA	<=	9'h006;
    	   LCD_INTIAL+4:	LUT_DATA	<=	9'h080;
    	   //	Line 1
    	   LCD_LINE1+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE1+1:	    LUT_DATA	<=	9'b101010000;//P
    	   LCD_LINE1+2:	    LUT_DATA	<=	9'b101101000;//h
    	   LCD_LINE1+3:	    LUT_DATA	<=	9'b101100001;//a
    	   LCD_LINE1+4:	    LUT_DATA	<=	9'b101110011;//s
    	   LCD_LINE1+5:	    LUT_DATA	<=	9'b101100101;//e
    	   LCD_LINE1+6:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+7:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+8:	    LUT_DATA	<=	9'b100110101;//5
    	   LCD_LINE1+9:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE1+10:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+11:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+12:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+14:	LUT_DATA	<=	9'h120;
    	   LCD_LINE1+15:	LUT_DATA	<=	9'h120;
    	   //	Change Line
    	   LCD_CH_LINE:	    LUT_DATA	<=	9'h0C0;
    	   //	Line 2      
    	   LCD_LINE2+0:	    LUT_DATA	<=	9'h120;	
    	   LCD_LINE2+1:	    LUT_DATA	<=	9'b101001110;//N	
    	   LCD_LINE2+2:	    LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+3:	    LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+4:	    LUT_DATA	<=	9'b101010011;//S
    	   LCD_LINE2+5:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+6:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+7:	    LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+8:	    LUT_DATA	<=	9'h120;
    	   LCD_LINE2+9:	    LUT_DATA	<=	9'b101000101;//E
    	   LCD_LINE2+10:	LUT_DATA	<=	9'b101111111;//<-
    	   LCD_LINE2+11:	LUT_DATA	<=	9'b101111110;//->
    	   LCD_LINE2+12:	LUT_DATA	<=	9'b101010111;//W
    	   LCD_LINE2+13:	LUT_DATA	<=	9'h120;
    	   LCD_LINE2+14:	LUT_DATA	<=	9'b101011000;//X
    	   LCD_LINE2+15:	LUT_DATA	<=	9'b101011000;//X
    	   default:		LUT_DATA	<=	9'h120;
        endcase
        
      endcase
    end

    LCD_Controller 	u0	(	//	Host Side
							.iDATA(mLCD_DATA),
							.iRS(mLCD_RS),
							.iStart(mLCD_Start),
							.oDone(mLCD_Done),
							.iCLK(iCLK),
							.iRST_N(iRST_N),
							//	LCD Interface
							.LCD_DATA(LCD_DATA),
							.LCD_RW(LCD_RW),
							.LCD_EN(LCD_EN),
							.LCD_RS(LCD_RS)	);

endmodule

module LCD_Controller (	//	Host Side
						iDATA,iRS,
						iStart,oDone,
						iCLK,iRST_N,
						//	LCD Interface
						LCD_DATA,
						LCD_RW,
						LCD_EN,
						LCD_RS	);
    //	CLK
    parameter	CLK_Divide	=	16;
    
    //	Host Side
    input	[7:0]	iDATA;
    input	iRS,iStart;
    input	iCLK,iRST_N;
    output	reg		oDone;
    //	LCD Interface
    output	[7:0]	LCD_DATA;
    output	reg		LCD_EN;
    output			LCD_RW;
    output			LCD_RS;
    //	Internal Register
    reg		[4:0]	Cont;
    reg		[1:0]	ST;
    reg		preStart,mStart;
    
    /////////////////////////////////////////////
    //	Only write to LCD, bypass iRS to LCD_RS
    assign	LCD_DATA	=	iDATA; 
    assign	LCD_RW		=	1'b0;
    assign	LCD_RS		=	iRS;
    /////////////////////////////////////////////
    
    always@(posedge iCLK or negedge iRST_N)
    begin
    	if(!iRST_N)
    	begin
    		oDone	<=	1'b0;
    		LCD_EN	<=	1'b0;
    		preStart<=	1'b0;
    		mStart	<=	1'b0;
    		Cont	<=	0;
    		ST		<=	0;
    	end
    	else
    	begin
    		//////	Input Start Detect ///////
    		preStart<=	iStart;
    		if({preStart,iStart}==2'b01)
    		begin
    			mStart	<=	1'b1;
    			oDone	<=	1'b0;
    		end
    		//////////////////////////////////
    		if(mStart)
    		begin
    			case(ST)
    			0:	ST	<=	1;	//	Wait Setup
    			1:	begin
    					LCD_EN	<=	1'b1;
    					ST		<=	2;
    				end
    			2:	begin					
    					if(Cont<CLK_Divide)
    					Cont	<=	Cont+1;
    					else
    					ST		<=	3;
    				end
    			3:	begin
    					LCD_EN	<=	1'b0;
    					mStart	<=	1'b0;
    					oDone	<=	1'b1;
    					Cont	<=	0;
    					ST		<=	0;
    				end
    			endcase
    		end
    	end
    end

endmodule