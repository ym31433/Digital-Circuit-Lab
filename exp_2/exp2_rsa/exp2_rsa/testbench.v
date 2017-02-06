`timescale 1ns/1ps
`define CYCLE      1000.0
`define End_CYCLE  1000000000       // Modify cycle times once your design need more cycle times!
`define TOTAL_DATA 38
`define TEST_DATA  2


module testbench;

//===============================================================
//==== signal declaration =======================================
    // ----------------------------------------------------------
    // -------- singals in top module ---------------------------
    reg  clk;
    reg  reset;
    wire ready;
    reg  we;
    reg  oe;
    reg  start;
    reg  [1:0] reg_sel;
    reg  [4:0] addr;
    reg  [7:0] data_i;
    wire [7:0] data_o;
    wire clk_o;
    wire reset_o;
    wire ready_o;
    wire we_o;
    wire oe_o;
    wire start_o;
    wire [1:0] reg_sel_o;
    wire [4:0] addr_o;
    wire [7:0] data_i_o;

    // -------- input data & output golden pattern --------------
    reg [255:0] dn_mem [0:1];
    reg [255:0] c_mem [0:`TOTAL_DATA-1];
    reg [255:0] m_mem [0:`TOTAL_DATA-1];
    initial $readmemh("./dat/dn.dat", dn_mem);
    initial $readmemh("./dat/c.dat", c_mem);
    initial $readmemh("./dat/m.dat", m_mem);

    // -------- variables &indices ------------------------------
    integer i, j;

//==== module connection ========================================
    exp2_rsa top(
        .clk(clk),
        .reset(reset),
        .ready(ready),
        .we(we),
        .oe(oe),
        .start(start),
        .reg_sel(reg_sel),
        .addr(addr),
        .data_i(data_i),
        .data_o(data_o), 
        .clk_o(clk_o), 
        .reset_o(reset_o),
        .ready_o(ready_o),
        .we_o(we_o),
        .oe_o(oe_o),
        .start_o(start_o),
        .reg_sel_o(reg_sel_o),
        .addr_o(addr_o),
        .data_i_o(data_i_o)
    );

//==== create waveform file =====================================
    initial begin
        $fsdbDumpfile("exp2_rsa.fsdb");
        $fsdbDumpvars;
    end

//==== start simulation =========================================
    
    always begin 
        #(`CYCLE/2) clk = ~clk; 
    end
    
    initial begin
        #0; // t = 0
        clk     = 1'b1;
        reset   = 1'b0; 
        we      = 1'b0;
        oe      = 1'b0;
        start   = 1'b0;
        reg_sel = 2'd0;
        addr    = 4'd0;
        data_i  = 8'd0;

        #(`CYCLE) reset = 1'b1; // t = 1
        #(`CYCLE) reset = 1'b0; // t = 2
        
        #(0.001);
        // a3 & a2
        i = 0;
        while(i<64) begin
            #(`CYCLE);
            if(i==0) begin
                we = 1'b1;
                reg_sel = 2'd3;
                addr = 5'd0;
            end
            else if(i==32) begin
                reg_sel = 2'd2;
                addr = 5'd0;
            end
            else begin
                addr = addr+5'd1;
            end
            
            if(i<32) data_i = dn_mem[1][addr*8 +: 8];
            else     data_i = dn_mem[0][addr*8 +: 8];
            i = i+1;
        end
        
        // a1 & a0 (loop)
        j = 0;
        while(j<`TEST_DATA) begin
            // a1
            i = 0;
            while(i<32) begin
                #(`CYCLE);
                if(i==0) begin 
                    we = 1'b1;
                    reg_sel = 2'd1;
                    addr = 5'd0;
                end
                else begin
                    addr = addr+5'd1;
                end
                data_i = c_mem[j][addr*8 +: 8];
                i = i+1;
            end
            
            #(`CYCLE);
            start = 1'b1;
            we = 1'b0;
            reg_sel = 2'd0;
            addr = 5'd0;
            data_i = 0;
            
            #(`CYCLE) start = 1'b0;
            @(posedge ready);
            @(posedge clk);
            #(0.001);
            
            // a0
            i = 0;
            while(i<32) begin
                if(i==0) begin
                    oe = 1'b1;
                    addr = 5'd0;
                end
                else begin
                    addr = addr+5'd1;
                end
                #(`CYCLE);
                if(data_o !== m_mem[j][addr*8 +: 8]) begin
                    $display("-----------------------------------------------------\n");
                    $display("ERROR at %dth m[%d:%d]: output %h !== expect %h \n", j, addr*8+7, addr*8, data_o, m_mem[j][addr*8 +: 8]);
                    $display("-------------------------FAIL------------------------\n");
                    #1;
                    $finish;
                end
                i = i+1;
            end
            oe = 1'b0;
            addr = 5'd0;
            #(`CYCLE*2);
            j = j+1;
        end
        
        $display("-----------------------------------------------------\n");
        $display("Congratulations! All data have been generated successfully!\n");
        $display("-------------------------PASS------------------------\n");
        $finish;
    end

//==== Terminate the simulation, FAIL ===========================
    initial  begin
        #(`CYCLE*`End_CYCLE);
        $display("-----------------------------------------------------\n");
        $display("Error!!! Somethings' wrong with your code ...!!\n");
        $display("-------------------------FAIL------------------------\n");
        $finish;
    end

endmodule
