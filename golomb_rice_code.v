`timescale 1ns / 1ps
module golomb_rice_code(
	input reset_n,
	input clk,
	input [2:0] k,
	input [31:0] val,
	input is_ac_level,
	input is_minus_n,
	output reg [31:0] sum_n,
	output reg [31:0] codeword_length,

	//internal reg
	output reg is_minus_n_n,
	output reg is_ac_level_n,
	output reg [31:0] q,
	output reg  [2:0] k_n,
	output reg [31:0] sum
 );
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_minus_n_n <= 1'b0;
		is_ac_level_n <= 1'b0;
	end else begin
		is_minus_n_n <= is_minus_n;
		is_ac_level_n <= is_ac_level;		
	end
end

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
			if (is_ac_level) begin
				if (is_minus_n) begin
					sum <= (((1<<k) | (val & ((1<<k) - 1))) << 1)|1;
					
				end else begin
					sum <= (((1<<k) | (val & ((1<<k) - 1))) << 1)|0;
				end
				
			end else begin
				sum <= (1<<k) | (val & ((1<<k) - 1));
			end
		end
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		codeword_length <= 32'h0;
	end else begin
		if (k_n==0) begin
			if (is_ac_level_n) begin
				if (is_minus_n_n) begin
					sum_n <= 3;
				end else begin
					sum_n <= 2;
				end
				codeword_length <= q + 2;
			end else begin
				sum_n <= 1;
				codeword_length <= q + 1;
			end
		end else begin
			if (is_ac_level_n) begin
				codeword_length <= q + 2 + k_n;
			end else begin
				codeword_length <= q + 1 + k_n;
			end
		end
	end
end


endmodule;

