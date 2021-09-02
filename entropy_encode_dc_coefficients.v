`timescale 1ns / 1ps

module entropy_encode_dc_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input [31:0] DcCoeff,
	output reg [31:0] output_enable,//mask
output reg [31:0] previousDCDiff, 
	output reg [31:0] sum,
	output reg [31:0] sum_n,
	output wire [31:0] LENGTH,
output reg [31:0] sum_n_n,

	output reg [31:0] pppp,
output reg [31:0] abs_previousDCDiff,
output reg [31:0] abs_previousDCDiff_next, 
output reg [31:0] abs_previousDCDiff_next_next, 
output reg [31:0] previousDCCoeff, 
output reg [31:0] dc_coeff_difference, 
output reg [31:0] val,
output reg [31:0] val_n,

output reg [1:0] is_expo_golomb_code,
output reg [1:0] is_expo_golomb_code_n,
output reg [1:0] is_expo_golomb_code_n_n,


output reg [1:0] is_add_setbit,
output reg [1:0] is_add_setbit_n,

output reg [2:0] k,
output reg [2:0] k_n,
output reg [31:0] q = 32'h0,
output reg [31:0] codeword_length = 32'h0,
output reg [31:0] codeword_length_n,


output reg first_diff



);

/*
function [31:0] getfloorclog2;
	input [19:0] val;
	begin
		reg [19:0] in_val;
		in_val = val;
		for (getfloorclog2=0; in_val>0; getfloorclog2=getfloorclog2+1) begin
			in_val = in_val>>1;
		end
		getfloorclog2 = getfloorclog2 - 1;
	end
endfunction
*/
/*
function [23:0] bitmask;
	input [5:0] val;
	reg [5:0] index = 6'h0;
	begin
		bitmask = 24'h1;
		for(index=1;index<val;index=index+1) begin
			bitmask = (bitmask<<1) | 1;
		end
	end
endfunction
*/

always @(posedge clk) begin
	if (!reset_n) begin
		first_diff <= 1;
		previousDCCoeff <= 32'h0;
	end else begin
		previousDCCoeff <= DcCoeff;
	end
end


//always @(posedge clk, negedge reset_n) begin
always @(posedge clk) begin
	if (!reset_n) begin
//		# <= 20'h0;
		dc_coeff_difference <= 32'h0;
		val <= 32'h0;
//		sum = 24'hfff0;
		previousDCDiff <= 32'h3;

	end else begin
		if (previousDCDiff[31] == 1'b0) begin
			dc_coeff_difference <= DcCoeff - previousDCCoeff;
		end else begin
			dc_coeff_difference <= (~(DcCoeff - previousDCCoeff)) + 1;
		end

		if (dc_coeff_difference[31] != 1'b1) begin
			val <= dc_coeff_difference << 1;
		end else begin
			val <= ((~(dc_coeff_difference - 1)) << 1) -1;
		end

		if (first_diff) begin
			previousDCDiff <= 3;
			//previousDCDiff <= DcCoeff - previousDCCoeff;
			first_diff <=0;
			
		end else begin
			previousDCDiff <= DcCoeff - previousDCCoeff;
			
		end
	end

end



//get abs
always @(posedge clk ) begin
	if (!reset_n) begin
		abs_previousDCDiff <= 20'h0;
	end else begin
		if (previousDCDiff[31] != 1'b1) begin
			abs_previousDCDiff <= previousDCDiff;
		end else begin
			abs_previousDCDiff <= (~(previousDCDiff - 1));
		end
		abs_previousDCDiff_next <= abs_previousDCDiff;
		abs_previousDCDiff_next_next <= abs_previousDCDiff_next;

	end
end




reg first;
reg first_n;
reg first_n_n;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		first <= 1'b1;
	end else begin
		first <=0;
		first_n <=first;
		first_n_n <= first_n;
	end
end


//dicision talbe

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code <= 2'b10;
		is_add_setbit <= 2'b0;
		k <= 3'h0;
		val_n <= 32'h0;

	end else begin
		if (first_n_n == 1'b1) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 5;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 0) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 0;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 1) begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 1;
			val_n <= val;
		end else if (abs_previousDCDiff_next== 2) begin
			//uint32_t value = (last_rice_q + 1) << k_rice;
			if (val < 8) begin
				is_expo_golomb_code <= 2'b00;
				is_add_setbit <= 2'b0;
				k <= 2;
				val_n <= val;
			end else begin
				is_expo_golomb_code <= 2'b01;
		        //setBit(bitstream, 0,last_rice_q + 1);
				is_add_setbit <= 2'b10;
				k <= 3;
				val_n <= val -8;
			end
			
		end else begin
			is_expo_golomb_code <= 2'b01;
			is_add_setbit <= 2'b0;
			k <= 3;
			val_n <= val;
		end
			
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n <= 2'b10;
	end else begin
		is_expo_golomb_code_n <= is_expo_golomb_code;
	end
end





assign LENGTH = codeword_length;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousDCDiff <= 32'hffff; 
	end else begin
		
	end
end



wire [31:0] exp_golomb_sum;
wire [31:0] exp_golomb_codeword_length;

exp_golomb_code exp_golomb_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.val(val_n),
	.is_add_setbit(is_add_setbit),
	.k(k),
	.is_ac_level(0),
	.is_ac_minus_n(0),
	.sum_n(exp_golomb_sum),
	.codeword_length(exp_golomb_codeword_length)
);


wire [31:0] rice_sum;
wire [31:0] rice_codeword_length;

golomb_rice_code golomb_rice_code_inst(
	.reset_n(reset_n),
	.clk(clk),
	.k(k),
	.val(val_n),
	.is_ac_level(0),
	.is_minus_n(0),
	.sum_n(rice_sum),
	.codeword_length(rice_codeword_length),
	.k_n(k_n),
	.sum(sum)
);

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code_n_n <= 2'b00;
	end else begin
		is_expo_golomb_code_n_n <= is_expo_golomb_code_n;
	end
end

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		sum_n_n <= 32'h0;
		codeword_length_n <= 32'h0;
	end else begin
		if (is_expo_golomb_code_n_n == 2'b00) begin
			sum_n_n <= rice_sum;
			codeword_length_n <= rice_codeword_length;
//			sum_n_n <= sum_n;
//			codeword_length_n <= codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b01) begin
			sum_n_n <= exp_golomb_sum;
			codeword_length_n <= exp_golomb_codeword_length;
//			sum_n_n <= sum_n;
//			codeword_length_n <= codeword_length;
		end else if (is_expo_golomb_code_n_n == 2'b10) begin
			sum_n_n <= sum_n;
			codeword_length_n <= codeword_length;
		end
	end
end





always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_expo_golomb_code == 2'b10) begin
			codeword_length <= 32'h0;
//			output_enable = 20'h0;
			sum <= 32'h0;
			//sum[1:0] = is_expo_golomb_code;
		end
	end
end
//bitmask
always @(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		output_enable <= 32'h0;		
	end else begin
		casex(1<<(codeword_length - 1))
			32'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'hff_ffff;
			32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h7f_ffff;
			32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h3f_ffff;
			32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h1f_ffff;
			32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h0f_ffff;
			32'b0000_01xx_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h07_ffff;
			32'b0000_001x_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h03_ffff;
			32'b0000_0001_xxxx_xxxx_xxxx_xxxx: output_enable <= 32'h01_ffff;
			32'b0000_0000_1xxx_xxxx_xxxx_xxxx: output_enable <= 32'h00_ffff;
			32'b0000_0000_01xx_xxxx_xxxx_xxxx: output_enable <= 32'h00_7fff;
			32'b0000_0000_001x_xxxx_xxxx_xxxx: output_enable <= 32'h00_3fff;
			32'b0000_0000_0001_xxxx_xxxx_xxxx: output_enable <= 32'h00_1fff;
			32'b0000_0000_0000_1xxx_xxxx_xxxx: output_enable <= 32'h00_0fff;
			32'b0000_0000_0000_01xx_xxxx_xxxx: output_enable <= 32'h00_07ff;
			32'b0000_0000_0000_001x_xxxx_xxxx: output_enable <= 32'h00_03ff;
			32'b0000_0000_0000_0001_xxxx_xxxx: output_enable <= 32'h00_01ff;
			32'b0000_0000_0000_0000_1xxx_xxxx: output_enable <= 32'h00_00ff;
			32'b0000_0000_0000_0000_01xx_xxxx: output_enable <= 32'h00_007f;
			32'b0000_0000_0000_0000_001x_xxxx: output_enable <= 32'h00_003f;
			32'b0000_0000_0000_0000_0001_xxxx: output_enable <= 32'h00_001f;
			32'b0000_0000_0000_0000_0000_1xxx: output_enable <= 32'h00_000f;
			32'b0000_0000_0000_0000_0000_01xx: output_enable <= 32'h00_0007;
			32'b0000_0000_0000_0000_0000_001x: output_enable <= 32'h00_0003;
			32'b0000_0000_0000_0000_0000_0001: output_enable <= 32'h00_0001;
			32'b0000_0000_0000_0000_0000_0000: output_enable <= 32'h00_0000;
		endcase
	end
end





endmodule;
