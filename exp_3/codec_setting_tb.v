`timescale 1ns/10ps
module tb();
reg           clk, rst;
wire          sda, sclk, ready;

initial begin
	$dumpfile("codec_setting.fsdb");
	$dumpvars;
	clk    = 1'b0;
	rst    = 1'b1;
	$finish;
end

always begin
	#20 clk = ~clk;
end

codec_setting set(rst, clk, sda, sclk, ready);
endmodule