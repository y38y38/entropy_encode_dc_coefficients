
#include <iostream>
#include <verilated.h>
#include "Ventropy_encode_dc_coefficients.h"
#include <verilated_fst_c.h> 



int16_t vals[] = {288,
 307 ,
 333,
  360, 
  287 ,
  317 ,
  361,
   356,
    364, 
	367 ,
	323 ,
	335 ,
	376,
	 392, 
	 329 ,
	 352,
	  352,
	   365,
	    384,
		 367,
		  340,
		   422,
		    317,
			 403,
			  424,
			   427,
			    418,
				 424,
				  416,
				   406,
				    427,
					 417, 

};
#define MAX_COEFFICIENT_NUM_PER_BLOCK (64)

static void golomb_rice_code(int32_t k, uint32_t val)
{
    int32_t q  = val >> k;

    if (k ==0) {
        if (q != 0) {
//            setBit(bitstream, 0,q);
		printf("%x %d\n", 0, q);
        }
//        setBit(bitstream, 1,1);
		printf("%x %d\n", 1, 1);
    } else {
        uint32_t tmp = (k==0) ? 1 : (2<<(k-1));
        uint32_t r = val & (tmp -1 );

        uint32_t codeword = (1 << k) | r;
//        setBit(bitstream, codeword, q + 1 + k );
		printf("%x %d\n", codeword, q + 1 + k);

    }
    return;
}
static void exp_golomb_code(int32_t k, uint32_t val)
{

	//LOG
    int32_t q = floor(log2(val + ((k==0) ? 1 : (2<<(k-1))))) - k;

    uint32_t sum = val + ((k==0) ? 1 : (2<<(k-1)));

    int32_t codeword_length = (2 * q) + k + 1;

//    setBit(bitstream, sum, codeword_length);
		printf("%x %d\n", sum, codeword_length);
    return;
}
static void rice_exp_combo_code(int32_t last_rice_q, int32_t k_rice, int32_t k_exp, uint32_t val)
{
    uint32_t value = (last_rice_q + 1) << k_rice;

    if (val < value) {
        golomb_rice_code(k_rice, val);
    } else {
		printf("%x %d\n", 0, last_rice_q + 1);
//        setBit(bitstream, 0,last_rice_q + 1);
        exp_golomb_code(k_exp, val - value);
    }
    return;
}
static void entropy_encode_dc_coefficient(bool first, int32_t abs_previousDCDiff , int val)
{
    if (first) {
        exp_golomb_code(5, val);
    } else if (abs_previousDCDiff == 0) {
        exp_golomb_code(0, val);
    } else if (abs_previousDCDiff == 1) {
        exp_golomb_code(1, val);
    } else if (abs_previousDCDiff == 2) {
        rice_exp_combo_code(1,2,3, val);
    } else {
        exp_golomb_code(3, val);
    }
    return;

}

static int32_t GetAbs(int32_t val)
{
    if (val < 0) {
        //printf("m\n");
        return val * -1;
    } else {
        //printf("p\n");
        return val;
    }
}



static int32_t Signedintegertosymbolmapping(int32_t val)
{
    uint32_t sn;
    if (val >=0 ) {
        sn = GetAbs(val) << 1;

    } else {
        sn = (GetAbs(val) << 1) - 1;
    }
    return sn;
}
void entropy_encode_dc_coefficients(int16_t*coefficients)
{
	int32_t numBlocks = 32;
    int32_t DcCoeff;
    int32_t val;
    int32_t previousDCCoeff;
    int32_t previousDCDiff;
    int32_t n;
    int32_t dc_coeff_difference;
    int32_t abs_previousDCDiff;

    DcCoeff = (coefficients[0]) ;
    val = Signedintegertosymbolmapping(DcCoeff);
    entropy_encode_dc_coefficient(true, 0, val);

    
    previousDCCoeff= DcCoeff;
    previousDCDiff = 3;
    n = 1;
    while( n <numBlocks) {
        DcCoeff = (coefficients[n++]); 
        dc_coeff_difference = DcCoeff - previousDCCoeff;
        if (previousDCDiff < 0) {
            dc_coeff_difference *= -1;
        }
        val = Signedintegertosymbolmapping(dc_coeff_difference);
        abs_previousDCDiff = GetAbs(previousDCDiff );
        entropy_encode_dc_coefficient(false, abs_previousDCDiff, val);
        previousDCDiff = DcCoeff - previousDCCoeff;
        previousDCCoeff= DcCoeff;

    }
    return ;
}



int time_counter = 0;

int main(int argc, char** argv) {

//	Verilated::commandArgs(argc, argv);
//	FILE *in = fopen(argv[1], "r");
//	if (in==NULL) {
//		printf("err\n");
//	}

//entropy_encode_dc_coefficients(vals);
	// Instantiate DUT
	Ventropy_encode_dc_coefficients *dut = new Ventropy_encode_dc_coefficients();
	// Trace DUMP ON
	Verilated::traceEverOn(true);
	VerilatedFstC* tfp = new VerilatedFstC;

	dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
	tfp->open("simx.fst");

	// Format
	dut->reset_n = 0;
	dut->clk = 0;

	// Reset Time
	while (time_counter < 10) {
		dut->clk = !dut->clk; // Toggle clock
		dut->eval();
		tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;
	}
	// Release reset
	dut->reset_n = 1;

	int state = 0;
//	int val[12] = {5,-6,-8,15,15,-9,-3,-5,0,0,0,0};
	int i =0;
//	int k,val,codeword_length,sum;
//			printf("previousDCDiff %d\n", dut->previousDCDiff);
//			printf("abs_previousDCDiff %d\n", dut->abs_previousDCDiff);
printf("\n\n");
/*
			printf("%x %d\n", dut->sum, dut->LENGTH);
			printf("abs_previousDCDiff %d\n", dut->abs_previousDCDiff);
			printf("abs_previousDCDiff_next %d\n", dut->abs_previousDCDiff_next);
			printf("previousDCCoeff %d\n", dut->previousDCCoeff);
			printf("previousDCDiff %d\n", dut->previousDCDiff);
			printf("dc_coeff_difference %d\n", dut->dc_coeff_difference);
			printf("val %d\n", dut->val);
			printf("val_n %d\n", dut->val_n);
			printf("DcCoeff %d\n", dut->DcCoeff);
*/
//	while (time_counter < 68 && !Verilated::gotFinish()) {
	while (time_counter < 82 && !Verilated::gotFinish()) {
		dut->clk = !dut->clk; // Toggle clock
		if (dut->clk) {
//			fscanf(in, "%d,%d,%d,%d",&k, &val, &sum, &codeword_length);
//			if (state == 0) {
//				dut->k = k;
//				if (i>=12) {
//					printf("end\n");
//					break;
//				}
				dut->DcCoeff = vals[i];
				i++;
//				state = 1;
//			}
			printf("%x %d\n", dut->sum, dut->LENGTH);
#if 0
			printf("abs_previousDCDiff %d\n", dut->abs_previousDCDiff);
			printf("abs_previousDCDiff_next %d\n", dut->abs_previousDCDiff_next);
			printf("previousDCCoeff %d\n", dut->previousDCCoeff);
			printf("previousDCDiff %d\n", dut->previousDCDiff);
			printf("dc_coeff_difference %d\n", dut->dc_coeff_difference);
			printf("val %d\n", dut->val);
			printf("val_n %d\n", dut->val_n);
			printf("DcCoeff %d %d\n", dut->DcCoeff, i);
#endif
		}

		// Evaluate DUT
		dut->eval();
		if (dut->clk) {
			
//			uint32_t sum;
//			int32_t codword_length;
//			exp_golomb_code(dut->k, dut->input_data, &sum, &codword_length);
//			if ((dut->sum != sum) || (dut->CODEWORD_LENGTH != codeword_length)) {
//				printf("q=%d\n",dut->Q);
//				printf("k=%d,input_data=%d sum=%d len=%d %x, sum=%d len=%d\n", 
//				dut->k, dut->input_data, dut->sum, dut->CODEWORD_LENGTH, dut->output_enable,  sum, codeword_length);

//			}
		}
		tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;
//		break;
	}

	dut->final();
	tfp->close(); 
}