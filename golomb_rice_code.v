`timescale 1ns / 1ps
module golomb_rice_code(
	input reset_n,
	input clk,
	input [2:0] k,
	input [31:0] val,
	output reg [31:0] sum_n,
	output reg [31:0] codeword_length,

	//internal reg
	output reg [31:0] q,
	output reg  [2:0] k_n,
	output reg [31:0] sum
 );

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n <= 32'h0;
		k_n <= 3'h0;
	end else begin
		if (k_n!= 0) begin
			sum_n <= sum;
		end
		k_n <= k;
	end
end

//golomb_rice_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum <= 32'h0;
	end else begin
		q <= val >> k;
		if (k != 0) begin
			sum <= (1<<k) | (val & ((1<<k) - 1));
		end
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		codeword_length <= 32'h0;
	end else begin
		if (k_n==0) begin
			if(q!=0) begin
				sum_n <= 1;
				codeword_length <= q + 1;
			end else begin
				sum_n <= 1;
				codeword_length <= 1;
			end
		end else begin
			codeword_length <= q + 1 + k_n;
		end
	end
end


endmodule;

