verilator --cc --exe  --trace-fst --trace-params --trace-structs --trace-underscore \
    entropy_encode_dc_coefficients.v -exe test_entropy_encode_dc_coefficients.cpp
make -C obj_dir -f Ventropy_encode_dc_coefficients.mk

