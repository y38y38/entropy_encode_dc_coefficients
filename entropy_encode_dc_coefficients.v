module entropy_encode_dc_coefficients(
	input clk,
	input reset_n,

	//本当は19bitで足りるが、本関数の処理上桁溢れする可能性があるので、
	//1bit多く用意しておく。
	input [19:0] DcCoeff,
	output reg [23:0] output_enable,//mask
	output reg [23:0] sum,
	output wire [23:0] LENGTH,
output reg [19:0] abs_previousDCDiff,
output reg [19:0] abs_previousDCDiff_next, 
output reg [19:0] previousDCCoeff, 
output reg [19:0] previousDCDiff, 
output reg [19:0] dc_coeff_difference, 
output reg [19:0] val,
output reg [19:0] val_n

);

function [19:0] getabs;
	input [19:0] value;
	begin
		if (value[19] != 1'b1) begin
			getabs = value;
		end else begin
			getabs =  (~(value - 1));
		end
	end
endfunction


function [19:0] Signedintegertosymbolmapping;
	input [19:0] val1;
	begin
		if (val1[19] != 1'b1) begin
			Signedintegertosymbolmapping <= val1 << 1;
		end else begin
			Signedintegertosymbolmapping <= ((~(val1 - 1)) << 1) -1;
		end
	end
endfunction



/*
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		val = 20'h3;
	end else begin
		val = Signedintegertosymbolmapping(DcCoeff);
	end
end
*/


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
reg is_expo_golomb_code;
reg is_add_setbit;
reg [2:0] k;

always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		is_expo_golomb_code <= 1'b0;
		is_add_setbit <= 1'b0;
		k <= 3'h0;
		val_n <= 20'h0;

	end else begin
//		abs_previousDCDiff = 0;
		if (first_n_n == 1'b1) begin
			is_expo_golomb_code <= 1'b1;
			is_add_setbit <= 1'b0;
			k <= 5;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 0) begin
			is_expo_golomb_code <= 1'b1;
			is_add_setbit <= 1'b0;
			k <= 0;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 1) begin
			is_expo_golomb_code <= 1'b1;
			is_add_setbit <= 1'b0;
			k <= 1;
			val_n <= val;
		end else if (abs_previousDCDiff_next == 2) begin
			//uint32_t value = (last_rice_q + 1) << k_rice;
			if (val < 8) begin
				is_expo_golomb_code <= 1'b0;
				is_add_setbit <= 1'b0;
				k <= 2;
				val_n <= val;
			end else begin
				is_expo_golomb_code <= 1'b1;
		        //setBit(bitstream, 0,last_rice_q + 1);
				is_add_setbit <= 1'b1;
				k <= 3;
				val_n <= val -8;
			end
			
		end else begin
			is_expo_golomb_code <= 1'b1;
			is_add_setbit <= 1'b0;
			k <= 3;
			val_n <= val;
		end
			
	end
end




always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		previousDCCoeff <= 20'h0;
		previousDCDiff <= 20'h3;
		abs_previousDCDiff <= 20'h0;
		abs_previousDCDiff_next <= 20'h0;
		dc_coeff_difference <= 20'h0;
		val <= 20'h0;

	end else begin
		if (previousDCDiff[19] == 1'b0) begin
			dc_coeff_difference <= DcCoeff - previousDCCoeff;
		end else begin
			dc_coeff_difference <= (~(DcCoeff - previousDCCoeff)) + 1;
		end
		if (dc_coeff_difference[19] != 1'b1) begin
			val <= dc_coeff_difference << 1;
		end else begin
			val <= ((~(dc_coeff_difference - 1)) << 1) -1;
		end

//		val <= Signedintegertosymbolmapping(dc_coeff_difference);
		abs_previousDCDiff <= getabs(previousDCDiff);
		abs_previousDCDiff_next <= abs_previousDCDiff;
		previousDCDiff <= DcCoeff - previousDCCoeff;
		previousDCCoeff <= DcCoeff;
	end

end

assign LENGTH = codeword_length;


reg [31:0] q = 32'h0;
reg [31:0] codeword_length = 32'h0;

//exp_golomb_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 24'h0;
		sum = 24'h0;
	end else begin
		if (is_expo_golomb_code == 1'b1) begin
			q = getfloorclog2((val_n + (1<<(k)))) - k;
			//q =  input_data + 16'h1;
			sum[19:0] = val_n + (1<<k);
			if (is_add_setbit == 1'b1) begin
				codeword_length = (2 * q) + k + 4;
			end else begin
				codeword_length = (2 * q) + k + 1;
			end
			output_enable = bitmask(codeword_length);
		end
	end
end


//golomb_rice_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		output_enable = 24'h0;
		sum = 24'h0;
		codeword_length = 32'h0;
	end else begin
		if (is_expo_golomb_code == 1'b0) begin
			q = val_n >> k;
			if (k==0) begin
				if(q!=0) begin
					sum = 1;
					codeword_length = q+1;
					output_enable = bitmask(codeword_length);
				end else begin
					sum = 1;
					codeword_length = 1;
					output_enable = 1;
				end
			end else begin
				// 0x4 | 1 & 0x3
				// 0x5 
				sum = (1<<k) | (val_n & ((1<<k) - 1));
				codeword_length = q + 1 + k;
				output_enable = bitmask( codeword_length);	
			end
		end
	end
end



endmodule;
