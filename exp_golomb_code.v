module exp_golomb_code(
	input reset_n,
	input clk,
	input [31:0] val,
	input [1:0] is_add_setbit,
	input [2:0]k,
	input is_ac_level,
	input is_ac_minus_n,
	output reg [31:0] sum_n,
	output reg [31:0] codeword_length,

	//deubg
	output reg [31:0] sum,
	output reg [31:0] q,
	output reg  [1:0] is_add_setbit_n,
	output reg [2:0] k_n

);



always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
		k_n <= 3'h0;
		sum_n <= 32'h0;
		is_add_setbit_n <= 2'h0;
	end else begin
		k_n <= k;
		sum_n <= sum;
		is_add_setbit_n <= is_add_setbit;
	end
end


//exp_golomb_code
always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
		if (is_ac_level) begin
			if (is_ac_minus_n) begin
				sum <= (val + (1<<k))<<1|1;
			end else begin
				sum <= (val + (1<<k))<<1|0;
			end
			
		end else begin
			sum <= (val + (1<<k));
		end
	end
end

//log2
//			q = getfloorclog2((val_n + (1<<(k)))) - k;

always @(posedge clk, negedge reset_n) begin
	if(!reset_n) begin
		q <= 32'h0;
	end else begin
		casex(val + (1<<(k)))
			32'b1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001f - k;
			32'b01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001e - k;
			32'b001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001d - k;
			32'b0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001c - k;
			32'b0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001b - k;
			32'b0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_001a - k;
			32'b0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0019 - k;
			32'b0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0018 - k;
			32'b0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0017 - k;
			32'b0000_0000_01xx_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0016 - k;
			32'b0000_0000_001x_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0015 - k;
			32'b0000_0000_0001_xxxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0014 - k;
			32'b0000_0000_0000_1xxx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0013 - k;
			32'b0000_0000_0000_01xx_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0012 - k;
			32'b0000_0000_0000_001x_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0011 - k;
			32'b0000_0000_0000_0001_xxxx_xxxx_xxxx_xxxx: q <= 32'h00_0010 - k;
			32'b0000_0000_0000_0000_1xxx_xxxx_xxxx_xxxx: q <= 32'h00_000f - k;
			32'b0000_0000_0000_0000_01xx_xxxx_xxxx_xxxx: q <= 32'h00_000e - k;
			32'b0000_0000_0000_0000_001x_xxxx_xxxx_xxxx: q <= 32'h00_000d - k;
			32'b0000_0000_0000_0000_0001_xxxx_xxxx_xxxx: q <= 32'h00_000c - k;
			32'b0000_0000_0000_0000_0000_1xxx_xxxx_xxxx: q <= 32'h00_000b - k;
			32'b0000_0000_0000_0000_0000_01xx_xxxx_xxxx: q <= 32'h00_000a - k;
			32'b0000_0000_0000_0000_0000_001x_xxxx_xxxx: q <= 32'h00_0009 - k;
			32'b0000_0000_0000_0000_0000_0001_xxxx_xxxx: q <= 32'h00_0008 - k;
			32'b0000_0000_0000_0000_0000_0000_1xxx_xxxx: q <= 32'h00_0007 - k;
			32'b0000_0000_0000_0000_0000_0000_01xx_xxxx: q <= 32'h00_0006 - k;
			32'b0000_0000_0000_0000_0000_0000_001x_xxxx: q <= 32'h00_0005 - k;
			32'b0000_0000_0000_0000_0000_0000_0001_xxxx: q <= 32'h00_0004 - k;
			32'b0000_0000_0000_0000_0000_0000_0000_1xxx: q <= 32'h00_0003 - k;
			32'b0000_0000_0000_0000_0000_0000_0000_01xx: q <= 32'h00_0002 - k;
			32'b0000_0000_0000_0000_0000_0000_0000_001x: q <= 32'h00_0001 - k;
			32'b0000_0000_0000_0000_0000_0000_0000_0001: q <= 32'h00_0000 - k;
			32'b0000_0000_0000_0000_0000_0000_0000_0000: q <= 32'h00_0000 - k;
		endcase
	end
end


always @(posedge clk, negedge reset_n) begin
	if (!reset_n) begin
	end else begin
//		if (is_add_setbit_n == 1'b1) begin
//			codeword_length <= (2 * q) + k_n + 3;
//		end else begin
		if (is_ac_level) begin
			codeword_length <= (2 * q) + k_n + 2 + is_add_setbit_n;
		end else begin
			codeword_length <= (2 * q) + k_n + 1 + is_add_setbit_n;
		end
//		end
	end
end


endmodule;

