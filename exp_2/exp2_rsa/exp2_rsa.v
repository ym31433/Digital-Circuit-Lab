module exp2_rsa (
    clk,     reset,     we,    oe,    start,
    reg_sel,   addr,    data_i,
    clk_o,     reset_o,     we_o,    oe_o,    start_o,   
	reg_sel_o,    addr_o,    data_i_o,	 data_o,
	ready,	 ready_o
);


    
//==== in/out declaration ==================================
    //-------- input output  ---------------------------
    input clk, reset, we, oe,start;
    input [1:0] reg_sel;
    input [4:0] addr;
    input [7:0] data_i;
    output clk_o, reset_o, we_o,oe_o,start_o;
    output [1:0] reg_sel_o;
    output [4:0] addr_o;
    output [7:0] data_i_o,data_o;
	output ready,ready_o;
//==== reg/wire declaration ================================
    //-------- output --------------------------------------
    reg [255:0] a0,a1,a2,a3,n_a1,n_a2,n_a3;
	reg [7:0]   data_o,n_data_o;
    wire [7:0] addrbit;
	reg ready;
    wire n_ready;
    wire [255:0] n_a0;
	     
     
//==== combinational part ==================================
    
    
    // clock signal
 
    assign addrbit=addr<<3;
	assign clk_o=clk;
	assign reset_o=reset;
	assign we_o=we;
	assign oe_o=oe;
	assign start_o=start;
	assign reg_sel_o=reg_sel;
	assign addr_o=addr;
	assign data_i_o=data_i;
	assign ready_o=ready;
	 
    always@(*) begin
	    
	    n_data_o=data_o;
	    n_a1 = a1;
	    n_a2 = a2;
	    n_a3 = a3;
	    if(we==1)begin
        case(reg_sel) 
            2'd3:  n_a3[addrbit+:8]=data_i;
			2'd2:  n_a2[addrbit+:8]=data_i;
			2'd1:  n_a1[addrbit+:8]=data_i;
            default: ;
        endcase
		end

		if(oe==1)begin
		case(reg_sel) 
            2'd3:  n_data_o=a3[addrbit+:8];
			2'd2:  n_data_o=a2[addrbit+:8];
			2'd1:  n_data_o=a1[addrbit+:8];
			2'd0:  n_data_o=a0[addrbit+:8];
            default: ;
        endcase
		end
	end
    LSB_ME lsb_me(.clk(clk), .rst(reset), .start(start), .ready(n_ready), .M(a1), .N(a3), .e(a2), .A1(n_a0));
     


//==== sequential part =====================================  
    always@( posedge clk or posedge reset or posedge we ) begin
        
    
        if( reset==1 ) begin

            a0 <= 256'd0;
			a1 <= 256'd0;
			a2 <= 256'd0;
			a3 <= 256'd0;				
			ready <= 1;
            data_o <= 8'd0;

        end 
        
        else begin
            a0 <= n_a0;
			a1 <= n_a1;
			a2 <= n_a2;
			a3 <= n_a3;
			ready  <= n_ready;
			data_o <= n_data_o;
			
        end        
    end 
endmodule 

