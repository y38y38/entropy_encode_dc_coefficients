
#include <iostream>
#include <verilated.h>
#include "Ventropy_encode_dc_coefficients.h"
//#include <verilated_fst_c.h> 



int16_t vals[] = {
	#if 0
-179,
-191,
-181,
-179,
-194,
-179,
-193,
-173,
-187,
-182,
-199,
-183,
-203,
-194,
-201,
-195,
#else

#if 0
397,
412,
395,
404,
411,
415,
407,
417,
427,
456,
428,
445,
479,
483,
463,
479,
486,
485,
493,
504,
496,
510,
508,
518,
512,
517,
531,
536,
528,
543,
554,
578,
#else







-138,
-147,
-140,
-147,
-130,
-136,
-118,
-125,
-127,
-122,
-129,
-123,
-121,
-121,
-119,
-115,

#endif

#endif

};

#define MAX_COEFFICIENT_NUM_PER_BLOCK (64)
#define LOG_ON	(1)

static void golomb_rice_code(int32_t k, uint32_t val)
{
    int32_t q  = val >> k;
#if LOG_ON
	printf("r q= %d\n",q);
	printf("k= %d\n",k);
	printf("val= %d\n",val);
 #endif

    if (k ==0) {
        if (q != 0) {
//            setBit(bitstream, 0,q);
		printf("%x %d\n", 1, q+1);
        } else {
		printf("%x %d\n", 1, 1);

		}
//        setBit(bitstream, 1,1);
    } else {
        uint32_t tmp = (k==0) ? 1 : (2<<(k-1));
        uint32_t r = val & (tmp -1 );

        uint32_t codeword = (1 << k) | r;
//        setBit(bitstream, codeword, q + 1 + k );
		printf("%x %d\n", codeword, q + 1 + k);

    }
    return;
}
static void exp_golomb_code(int32_t k, uint32_t val, int add_bit)
{

	//LOG
    int32_t q = floor(log2(val + ((k==0) ? 1 : (2<<(k-1))))) - k;
#if LOG_ON
	printf("q= %d\n",q);
	printf("k= %d\n",k);
	printf("val= %d\n",val);
	printf("add_bit= %d\n",add_bit);
 #endif
    uint32_t sum = val + ((k==0) ? 1 : (2<<(k-1)));

    int32_t codeword_length = (2 * q) + k + 1;

//    setBit(bitstream, sum, codeword_length);
		printf("%x %d\n", sum, codeword_length+add_bit);
    return;
}
static void rice_exp_combo_code(int32_t last_rice_q, int32_t k_rice, int32_t k_exp, uint32_t val)
{
    uint32_t value = (last_rice_q + 1) << k_rice;

    if (val < value) {
        golomb_rice_code(k_rice, val);
    } else {
//		printf("%x %d\n", 0, last_rice_q + 1);
//        setBit(bitstream, 0,last_rice_q + 1);
        exp_golomb_code(k_exp, val - value, last_rice_q + 1);
    }
    return;
}
static void entropy_encode_dc_coefficient(bool first, int32_t abs_previousDCDiff , int val)
{
    if (first) {
        exp_golomb_code(5, val,0);
    } else if (abs_previousDCDiff == 0) {
        exp_golomb_code(0, val,0);
    } else if (abs_previousDCDiff == 1) {
        exp_golomb_code(1, val,0);
    } else if (abs_previousDCDiff == 2) {
        rice_exp_combo_code(1,2,3, val);
    } else {
        exp_golomb_code(3, val,0);
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
#if LOG_ON
		printf("DcCoeff=%d\n", DcCoeff);
		printf("previousDCCoeff=%d\n", previousDCCoeff);
		printf("b dc_coeff_difference=%d\n", dc_coeff_difference);
		printf("previousDCDiff=%d\n", previousDCDiff);
#endif
        if (previousDCDiff < 0) {
            dc_coeff_difference *= -1;
        }
#if LOG_ON
		printf("a dc_coeff_difference=%d\n", dc_coeff_difference);
#endif
        val = Signedintegertosymbolmapping(dc_coeff_difference);
#if LOG_ON
		printf("previousDCDiff=%d\n",previousDCDiff);
 #endif
        abs_previousDCDiff = GetAbs(previousDCDiff );
#if LOG_ON
		printf("abs_previousDCDiff=%d\n",abs_previousDCDiff);
		printf("val=%d\n",val);
#endif		
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

//	entropy_encode_dc_coefficients(vals);
//	return 0;
	// Instantiate DUT
	Ventropy_encode_dc_coefficients *dut = new Ventropy_encode_dc_coefficients();
	// Trace DUMP ON
	Verilated::traceEverOn(true);
//	VerilatedFstC* tfp = new VerilatedFstC;

//	dut->trace(tfp, 100);  // Trace 100 levels of hierarchy
//	tfp->open("simx.fst");

	// Format
	dut->reset_n = 0;
	dut->clk = 0;

	// Reset Time
	while (time_counter < 10) {
		dut->clk = !dut->clk; // Toggle clock
		dut->eval();
	//	tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
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
	while (time_counter < 84 && !Verilated::gotFinish()) {
		dut->clk = !dut->clk; // Toggle clock
		if (dut->clk) {
//			fscanf(in, "%d,%d,%d,%d",&k, &val, &sum, &codeword_length);
//			if (state == 0) {
//				dut->k = k;
//				if (i>=12) {
//					printf("end\n");
//					break;
//				}
				dut->DcCoeff = vals[i%16];
//				printf("v %d\n", vals[i]);
//				printf("d %d\n", dut->DcCoeff);
				i++;
//				state = 1;
//			}
//			printf("%x %d %x\n", dut->sum_n, dut->LENGTH, dut->output_enable);
#if 0
			printf("\n");
			printf("DcCoeff %d %d\n", dut->DcCoeff, i);
			printf("previousDCCoeff %d\n", dut->previousDCCoeff);

			printf("\n");
			printf("dc_coeff_difference %d\n", dut->dc_coeff_difference);
//			printf("previousDCCoeff %d\n", dut->previousDCCoeff);
			printf("abs_previousDCDiff %d\n", dut->abs_previousDCDiff);
			printf("previousDCDiff %d\n", dut->previousDCDiff);

			printf("\n");
			printf("abs_previousDCDiff_next %d\n", dut->abs_previousDCDiff_next);
			printf("val %d\n", dut->val);
//			printf("previousDCDiff %d\n", dut->previousDCDiff);

			printf("\n");
//			printf("abs_previousDCDiff_next %d\n", dut->abs_previousDCDiff_next);
			printf("is_expo_golomb_code %d\n", dut->is_expo_golomb_code);
			printf("is_add_setbit %d\n", dut->is_add_setbit);
			printf("k %d\n", dut->k);
			printf("val_n %d\n", dut->val_n);

			printf("\n");
//			printf("abs_previousDCDiff_next_next %d\n", dut->abs_previousDCDiff_next_next);
			printf("is_expo_golomb_code_n %d\n", dut->is_expo_golomb_code_n);
			printf("is_add_setbit_n %d\n", dut->is_add_setbit_n);
			printf("k_n %d\n", dut->k_n);
			printf("q %d\n", dut->q);
			printf("sum %x\n", dut->sum);

			printf("\n");
			printf("codeword_length %d\n", dut->codeword_length);
			printf("sum_n %x\n", dut->sum_n);
			printf("---------------------------\n", dut->sum_n);
#endif
			printf("%x %d\n", dut->sum_n, dut->LENGTH);
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
		//tfp->dump(time_counter);  // 波形ダンプ用の記述を追加
		time_counter++;
//		break;
	}

	dut->final();
	//tfp->close(); 
}