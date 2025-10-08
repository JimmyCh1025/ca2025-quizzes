#=======================================================================================
# File : bfloat16.s 
# Author : Jimmy Chen
# Date : 2025-10-08
# Brief : Implementation of bfloat16 arithmetic operations (add, sub, mul, div, sqrt)
#          including conversion between float and bfloat16, with IEEE 754 support.
#=======================================================================================

.data

# define

.equ BF16_SIGN_MASK, 0x8000
.equ BF16_EXP_MASK, 0x7F80
.equ BF16_MANT_MASK, 0x007F
.equ BF16_EXP_BIAS, 127
.equ BF16_NAN, 0x7FC0
.equ BF16_ZERO, 0x0000

# input data

input_a:
    .half 0x0000, 0x8000, 0x3f80, 0x4000, 0x4040, 0xbf80, 0x7f80, 0xff80, 0x7fc1, 0x4110, 0xc080, 0x0001, 0x0a4b, 0x40a0, 0x7f00

input_b:
    .half 0x0000, 0x0000, 0x4000, 0x3f80, 0x4000, 0x3f80, 0x3f80, 0x7f80, 0x3f80, 0x0000, 0x0000, 0x0001, 0x0a4b, 0x0000, 0x7f00

input_float:
    .word 0x3F800000, 0x3FC00000, 0x3F81AE14, 0x00000000, 0x80000000, 0x477FE000, 0x7F800000, 0xFF800000, 0x7FC00000, 0x00000001, 0xC0200000, 0x40490FDB, 0xC2F6E979, 0x3EAAAAAB, 0x2F06C6D6

# ans 
isNanAns:
    .half 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000

isInfAns:
    .half 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0001, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000

isZeroAns:
    .half 0x0001, 0x0001, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000

f32tob16Ans:
    .half 0x3f80, 0x3fc0, 0x3f82, 0x0000, 0x8000, 0x4780, 0x7f80, 0xff80, 0x7fc0, 0x0000, 0xc020, 0x4049, 0xc2f7, 0x3eab, 0x2f07


b16tof32Ans:
    .word 0x00000000, 0x80000000, 0x3f800000, 0x40000000, 0x40400000, 0xbf800000, 0x7f800000, 0xff800000, 0x7fc10000, 0x41100000, 0xc0800000, 0x00010000, 0x0a4b0000, 0x40a00000, 0x7f000000

addAns:
    .half 0x0000, 0x0000, 0x4040, 0x4040, 0x40a0, 0x0000, 0x7f80, 0x7fc0, 0x7fc1, 0x4110, 0xc080, 0x0002, 0x0acb, 0x40a0, 0x7f80

subAns:
    .half 0x8000, 0x8000, 0xbf80, 0x3f80, 0x3f80, 0xc000, 0x7f80, 0xff80, 0x7fc1, 0x4110, 0xc080, 0x0000, 0x0000, 0x40a0, 0x0000

mulAns:
    .half 0x0000, 0x8000, 0x4000, 0x4000, 0x40c0, 0xbf80, 0x7f80, 0xff80, 0x7fc1, 0x0000, 0x8000, 0x0000, 0x0000, 0x0000, 0x7f80

divAns:
    .half 0x7fc0, 0x7fc0, 0x3f00, 0x4000, 0x3fc0, 0xbf80, 0x7f80, 0x7fc0, 0x7fc1, 0x7f80, 0xff80, 0x3f80, 0x3f80, 0x7f80, 0x3f80
 
sqrtAns:
    .half 0x0000, 0x0000, 0x3f80, 0x3fb5, 0x3fdd, 0x7fc0, 0x7f80, 0x7fc0, 0x7fc1, 0x4040, 0x7fc0, 0x0000, 0x24e4, 0x400f, 0x5f35

# string
msg_test_nan:
    .string "======Test NAN======\n"

msg_test_inf:
    .string "======Test INF======\n"

msg_test_zero:
    .string "======Test ZERO======\n"

msg_test_f32tob16:
    .string "======Test F32ToB16======\n"
    
msg_test_b16tof32:
    .string "======Test B16ToF32======\n"
    
msg_test_add:
    .string "======Test ADD======\n"
    
msg_test_sub:
    .string "======Test SUB======\n"
    
msg_test_mul:
    .string "======Test MUL======\n"
    
msg_test_div:
    .string "======Test DIV======\n"
    
msg_test_sqrt:
    .string "======Test SQRT======\n"


pass_str:
    .string " => Pass\n"

fail_str:
    .string " => Fail\n"

output_str:
    .string "Output = "


answer_str:
    .string ",Answer = "


.text
.global main

# =======================================================
# Function : main()
# Parameter : none
# Variable : i = s0, boundary = 15 
# Description : execute all function and print the result
# Return : 0 (exit program)
# =======================================================
main:
    #  i = 0, boundary = 15
    add  s0, x0, x0  

    j    main_for 

main_for:
    addi t0, x0, 15
    
    # if i >= 15, return exit
    bge  s0, t0, main_exit
    j    main_for_run_nan

#======================nan=====================
main_for_run_nan:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i] to bf16_nan()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call bf16_isnan
    jal  ra, bf16_isnan

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_nan


main_for_printf_nan:
    
    # print test nan
    la   a0, msg_test_nan
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, isNanAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_nan_pass

    j    main_for_nan_fail

main_for_nan_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall
    
    j    main_for_run_inf


main_for_nan_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_inf

#======================inf=====================
main_for_run_inf:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i] to bf16_inf()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call bf16_isinf
    jal  ra, bf16_isinf

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_inf

main_for_printf_inf:
    # print test inf
    la   a0, msg_test_inf
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, isInfAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_inf_pass

    j    main_for_inf_fail

main_for_inf_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_zero

main_for_inf_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_zero

#======================zero=====================
main_for_run_zero:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i] to bf16_iszero()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call bf16_iszero
    jal  ra, bf16_iszero

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_zero

main_for_printf_zero:
    # print test zero
    la   a0, msg_test_zero
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, isZeroAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_zero_pass

    j    main_for_zero_fail

main_for_zero_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_f32tob16

main_for_zero_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_f32tob16


#======================f32tob16=====================
main_for_run_f32tob16:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load test_float[i] to f32_to_bf16()
    slli t0, s0, 2
    la   t1, input_float
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call f32_to_bf16
    jal  ra, f32_to_bf16

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_f32tob16

main_for_printf_f32tob16:
    # print test f32tob16
    la   a0, msg_test_f32tob16
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, f32tob16Ans
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_f32tob16_pass

    j    main_for_f32tob16_fail

main_for_f32tob16_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_b16tof32

main_for_f32tob16_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_b16tof32

#======================b16tof32=====================
main_for_run_b16tof32:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i] to bf16_to_f32()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call bf16_to_f32
    jal  ra, bf16_to_f32

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_b16tof32

main_for_printf_b16tof32:
    # print test b16tof32
    la   a0, msg_test_b16tof32
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    add  a0, s3, x0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, b16tof32Ans
    slli t0, s0, 2
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    ecall  

    beq  t5, t6, main_for_b16tof32_pass

    j    main_for_b16tof32_fail


main_for_b16tof32_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_add

main_for_b16tof32_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_add

#======================add=====================
main_for_run_add:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i], b[i] to bf16_add()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    la   t2, input_b
    add  t2, t2, t0
    lw   a1, 0(t2)

    # call bf16_add
    jal  ra, bf16_add

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_add

main_for_printf_add:
    # print test add
    la   a0, msg_test_add
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, addAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_add_pass

    j    main_for_add_fail

main_for_add_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_sub

main_for_add_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_sub

#======================sub=====================
main_for_run_sub:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i], b[i] to bf16_sub()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    la   t2, input_b
    add  t2, t2, t0
    lw   a1, 0(t2)

    # call bf16_sub
    jal  ra, bf16_sub

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_sub

main_for_printf_sub:
    # print test sub
    la   a0, msg_test_sub
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, subAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_sub_pass

    j    main_for_sub_fail

main_for_sub_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_mul

main_for_sub_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_mul

#======================mul=====================
main_for_run_mul:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i], b[i] to bf16_mul()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    la   t2, input_b
    add  t2, t2, t0
    lw   a1, 0(t2)

    # call bf16_mul
    jal  ra, bf16_mul

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_mul

main_for_printf_mul:
    # print test mul
    la   a0, msg_test_mul
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, mulAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_mul_pass

    j    main_for_mul_fail

main_for_mul_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_div

main_for_mul_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_div


#======================div=====================
main_for_run_div:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i], b[i] to bf16_div()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    la   t2, input_b
    add  t2, t2, t0
    lw   a1, 0(t2)

    # call bf16_div
    jal  ra, bf16_div

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_div

main_for_printf_div:
    # print test div
    la   a0, msg_test_div
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, divAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_div_pass

    j    main_for_div_fail

main_for_div_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    j    main_for_run_sqrt

main_for_div_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    j    main_for_run_sqrt

#======================sqrt=====================
main_for_run_sqrt:
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   s0, 0(sp)

    # load a[i] to bf16_sqrt()
    slli t0, s0, 1
    la   t1, input_a
    add  t1, t1, t0
    lw   a0, 0(t1)

    # call bf16_sqrt
    jal  ra, bf16_sqrt

    # value of return stores in s3 
    add  s3, a0, x0

    lw   s0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8

    j    main_for_printf_sqrt

main_for_printf_sqrt:
    # print test sqrt
    la   a0, msg_test_sqrt
    li   a7, 4
    ecall

    # print output string
    la   a0, output_str
    ecall

    # print output value
    li   t0, 0xFFFF
    and  a0, s3, t0
    li   a7, 34
    # for compare
    add  t5, a0, x0
    ecall  

    # print answer string
    la   a0, answer_str
    li   a7, 4
    ecall

    # print ans value
    la   s3, sqrtAns
    slli t0, s0, 1
    add  t0, s3, t0
    lw   a0, 0(t0) 
    li   a7, 34
    # for compare
    add  t6, a0, x0
    li   t4, 0xffff
    and  a0, t6, t4
    and  t6, t6, t4
    ecall  

    beq  t5, t6, main_for_sqrt_pass

    j    main_for_sqrt_fail

main_for_sqrt_pass:
    # print pass
    la   a0, pass_str
    li   a7, 4
    ecall

    # ++i
    addi s0, s0, 1

    j    main_for

main_for_sqrt_fail:
    # print fail
    la   a0, fail_str
    li   a7, 4
    ecall

    # ++i
    addi s0, s0, 1

    j    main_for

#======================main exit=====================
main_exit:
    li   a7, 10
    ecall
    
# =======================================================
# Function : bf16_isnan()
# Parameter : bf16_t a
# Variable : 
# Description : Returns true if a is NaN; otherwise, returns false 
# Return : 1(true) or 0(false)
# =======================================================
# test ok
bf16_isnan:
    # t1 = (a.bits & BF16_EXP_MASK)
    li   t0, BF16_EXP_MASK
    and  t1, a0, t0
    
    # if (a.bits & BF16_EXP_MASK) == BF16_EXP_MASK
    bne  t1, t0, bf16_isnan_ret0
    
    # if (a.bits & BF16_MANT_MASK) == 0
    li   t0, BF16_MANT_MASK
    and  t1, a0, t0
    beq  t1, x0, bf16_isnan_ret0
    
    # return 1
    addi a0, x0, 1
    jalr x0, ra, 0

bf16_isnan_ret0:
    # return 0
    add  a0, x0, x0
    jalr x0, ra, 0

# =======================================================
# Function : bf16_isinf()
# Parameter : bf16_t a
# Variable : 
# Description : Returns true if the input is +Infinity or -Infinity.
# Return : 1(true) or 0(false)
# =======================================================
# test ok
bf16_isinf:
    # t1 = (a.bits & BF16_EXP_MASK)
    li   t0, BF16_EXP_MASK
    and  t1, a0, t0
    
    # if (a.bits & BF16_EXP_MASK) == BF16_EXP_MASK
    bne  t1, t0, bf16_isinf_ret0
    
    # if !(a.bits & BF16_MANT_MASK) == 0
    li   t0, BF16_MANT_MASK
    and  t1, a0, t0
    bne  t1, x0, bf16_isinf_ret0
    
    # return 1
    addi a0, x0, 1
    jalr x0, ra, 0

bf16_isinf_ret0:
    # return 0
    add  a0, x0, x0
    jalr x0, ra, 0

# =======================================================
# Function : bf16_iszero()
# Parameter : bf16_t a
# Variable : 
# Description : Returns true if the input is positive or negative zero.
# Return : 1(true) or 0(false)
# =======================================================
# test ok
bf16_iszero:
    # t1 = (a.bits & 0x7FFF)
    li   t0, 0x7FFF
    and  t1, a0, t0
    bne  t1, x0, bf16_iszero_ret0
    
    # return 1
    addi a0, x0, 1
    jalr x0, ra, 0
    
bf16_iszero_ret0:
    # return 0
    add  a0, x0, x0
    jalr x0, ra, 0


# =======================================================
# Function : f32_to_bf16()
# Parameter : float val
# Variable : 
# Description : Convert a 32-bit float to 16-bit bfloat16 by keeping the upper 16 bits.
# Return : bf16_t value(a0)
# =======================================================
# test ok
f32_to_bf16:
    # u32 t0 = f32bits
    # memcpy(&f32bits, &val, sizeof(float));
    add  t0, a0, x0
    
    # if (((f32bits >> 23) & 0xFF) == 0xFF)
    srli t1, t0, 23
    andi t2, t1, 0xFF
    li   t3, 0xFF
    bne  t2, t3 , f32_to_bf16_ret_exp_not_allOne
    
    # return all exp 1
    # (f32bits >> 16)& 0xFFFF
    srli t1, t0, 16
    li   t2, 0xFFFF
    and  a0, t1, t2
    
    # return all exp 1
    jalr x0, ra, 0 
    
f32_to_bf16_ret_exp_not_allOne:
    # return exp not all 1
    # f32bits += ((f32bits >> 16) & 1) + 0x7FFF;
    srli t1, t0, 16
    andi t2, t1, 1
    li   t3, 0x7FFF
    add  t4, t2, t3
    add  t0, t0, t4
    
    # return (bf16_t)f32bits >> 16
    srli a0, t0, 16
    li   t1, 0xFFFF
    and  a0, a0, t1
    jalr x0, ra, 0
    

# =======================================================
# Function : bf16_to_f32()
# Parameter : bf16_t a
# Variable : 
# Description : Converts a bfloat16 value to 32-bit float by zero-extending the lower bits.
# Return : float value(a0)
# =======================================================
# test ok
bf16_to_f32:
    # u32 f32bits = ((u32) val.bits) << 16;
    slli t0, a0, 16
    
    # memcpy(&result, &f32bits, sizeof(float))
    add  a0, t0, x0
    
    # return result
    jalr x0, ra, 0

# =======================================================
# Function : bf16_add()
# Parameter : bf16_t a, bf16_t b
# Variable : 
# Description : Performs bfloat16 addition with proper handling of special cases (NaN, Inf, zero).
# Return : b16_t value(a0)
# =======================================================
# test ok
bf16_add:
    addi sp, sp, -24
    sw   s6, 20(sp)
    sw   s5, 16(sp)
    sw   s4, 12(sp)
    sw   s3, 8(sp)
    sw   s2, 4(sp)
    sw   s1, 0(sp)

    # sign_a =  (a.bits >> 15) & 1
    srli s1, a0, 15
    andi s1, s1, 1

    # sign_b = (b.bits >> 15) & 1;
    srli s2, a1, 15
    andi s2, s2, 1
    
    # exp_a = ((a.bits >> 7) & 0xFF)
    srli s3, a0, 7
    andi s3, s3, 0xFF
    
    # exp_b = ((b.bits >> 7) & 0xFF)
    srli s4, a1, 7
    andi s4, s4, 0xFF
    
    # mant_a = a.bits & 0x7F
    andi s5, a0, 0x7F
    
    # mant_b = b.bits & 0x7F
    andi s6, a1, 0x7F    

    # if exp_a == 0xFF
    li   t0, 0xFF
    beq  s3, t0, bf16_add_exp_a_allOne
    
    # if exp_b == 0xFF
    beq  s4, t0, bf16_add_ret_b
    
    
    # if (!exp_a && !mant_a) <=> exp and mant = 0
    or   t6, s3, s5
    beq  t6, x0, bf16_add_ret_b


    # if (!exp_b && !mant_b) <=> exp and mant = 0
    or   t6, s4, s6
    beq  t6, x0, bf16_add_ret_a
    
    # if (exp_a)
    bne  s3, x0, bf16_add_mant_a_or0x80
    
    # if (exp_b)
    bne  s4, x0, bf16_add_mant_b_or0x80  
    j    bf16_add_dif


bf16_add_mant_a_or0x80:
    ori  s5, s5, 0x80
    
bf16_add_exp_b_not0:
    # if (exp_b)
    bne  s4, x0, bf16_add_mant_b_or0x80  
    j    bf16_add_dif
    
bf16_add_mant_b_or0x80:
    ori  s6, s6, 0x80

bf16_add_dif:
    # maybe some error
    # exp_diff = exp_a - exp_b;
    sub  t0, s3, s4
    
    # if (exp_diff > 0)
    blt  x0, t0, bf16_add_exp_dif_bgt0
    
    # if (exp_diff < 0)
    blt  t0, x0, bf16_add_exp_dif_blt0
    
    # if (exp_diff == 0) 
    beq  x0, t0, bf16_add_exp_dif_beq0
    
    # impossible
    j    bf16_add_check_sign
    
    
bf16_add_exp_dif_bgt0:
    # result_exp = exp_a
    add  t2, s3, x0
    
    # if (exp_diff > 8)
    li   t6, 8
    blt  t6, t0, bf16_add_ret_a
    
    # mant_b >>= exp_diff
    srl  s6, s6, t0
    
    # jump to if (sign_a == sign_b)
    j    bf16_add_check_sign
    
    
bf16_add_exp_dif_blt0:
    # result_exp = exp_b
    add  t2, s4, x0
    
    # if (exp_diff < -8)
    li   t6, -8
    blt  t0, t2, bf16_add_ret_b
    
    # mant_a >>= -exp_diff
    sub  t6, x0, t0
    srl  s6, s6, t6
    
    # jump to if (sign_a == sign_b)
    j    bf16_add_check_sign
    
    
bf16_add_exp_dif_beq0:
    # result_exp = exp_a
    add  t2, s3, x0

bf16_add_check_sign:
    # if (sign_a == sign_b) , eq jump to bf16_add_check_sign_eq
    beq  s1, s2, bf16_add_check_sign_eq
    
    # else
    
    
    # if (mant_a >= mant_b), true jump to gn
    bge  s5, s6, bf16_add_check_mant_gn
    
    # else  <
    # result_sign = sign_b
    add  t1, s2, x0
    
    # result_mant = mant_b - mant_a
    sub  t3, s6, s5
    
    # jump bf16_add_check_result_mant
    j    bf16_add_check_result_mant
    
    


bf16_add_check_mant_gn:    
    # result_sign = sign_a
    add  t1, s1, x0
    
    # result_mant = mant_a - mant_b
    sub  t3, s5, s6
    
bf16_add_check_result_mant:
    # if (!result_mant)
    beq  t3, x0, bf16_add_ret0
    
bf16_add_check_result_mant_while:
    # while (!(result_mant & 0x80))
    andi t5, t3, 0x80
    bne  t5, x0, bf16_add_ret
    
    # result_mant <<= 1
    slli t3, t3, 1
    
    # if (--result_exp <= 0)
    addi t2, t2, -1
    bge  x0, t2, bf16_add_ret0
    
    j    bf16_add_check_result_mant_while
    

bf16_add_check_sign_eq:   
    # result_sign = sign_a
    add  t1, s1, x0
    
    # result_mant = (uint32_t) mant_a + mant_b
    add  t3, s5, s6

    # if (result_mant & 0x100), eq 0 jump to return
    andi t6, t3, 0x100
    beq  t6, x0, bf16_add_ret
    
    # result_mant >>= 1
    srli t3, t3, 1
    
    # if(++result_exp >= 0xFF)
    # ++result_exp
    addi t2, t2, 1
    
    # (++result_exp >= 0xFF), if result_exp < 0xFF, jump return
    li   t6, 0xFF
    blt  t2, t6, bf16_add_ret
    
    # else
    #  ((return result_sign << 15) | 0x7F80)
    li   t6, 0x7F80
    slli t1, t1, 15
    or   a0, t1, t6
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
    

bf16_add_exp_a_allOne:
    # if mant_a != 0
    bne  s5, x0, bf16_add_ret_a
    
    # if (exp_b == 0xFF)
    beq  s4, t0, bf16_add_exp_b_allOne
    j    bf16_add_ret_a
    
    
bf16_add_exp_b_allOne:
    # return (mant_b || sign_a == sign_b) ? b : BF16_NAN()
    
    # sign_a == sign_b
    sub  t0, s1, s2
    
    # (mant_b || sign_a == sign_b)
    or   t1, s6, t0
    
    # if true , return b, otherwise return bf16 nan 
    bne  t1, x0, bf16_add_ret_b
   
    # return BF16_NAN
    li   a0, BF16_NAN
    add  a0, a1, x0
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_add_ret_a:
    # return a
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_add_ret_b:
    # return b
    add  a0, a1, x0
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_add_ret0:
    li   a0, BF16_ZERO
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_add_ret:

    # (result_sign << 15) | ((result_exp & 0xFF) << 7) | (result_mant & 0x7F)
                
    # (result_sign << 15)
    slli a0, t1, 15
    
    # ((result_exp & 0xFF) << 7)
    andi t5, t2, 0xFF
    slli t5, t5, 7
    
    # (result_mant & 0x7F)
    andi t6, t3, 0x7F
    
    or   a0, a0, t5
    or   a0, a0, t6
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

# =======================================================
# Function : bf16_sub()
# Parameter : bf16_t a, bf16_t b
# Variable : 
# Description : Performs bfloat16 subtraction by flipping the sign of the second operand and adding.
# Return : b16_t value(a0)
# =======================================================
# test ok
bf16_sub:
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    # b.bits ^= BF16_SIGN_MASK
    li   t0, BF16_SIGN_MASK
    xor  a1, a1, t0
    
    # call bf16_add
    jal  ra, bf16_add
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    jalr x0, ra, 0

# =======================================================
# Function : bf16_mul()
# Parameter : bf16_t a, bf16_t b
# Variable : 
# Description : Performs bfloat16 multiplication with normalization and special case handling.
# Return : b16_t value(a0)
# =======================================================
# test ok
bf16_mul:
    addi sp, sp, -24
    sw   s6, 20(sp)
    sw   s5, 16(sp)
    sw   s4, 12(sp)
    sw   s3, 8(sp)
    sw   s2, 4(sp)
    sw   s1, 0(sp)
    
    # sign_a =  (a.bits >> 15) & 1
    srli s1, a0, 15
    andi s1, s1, 1

    # sign_b = (b.bits >> 15) & 1;
    srli s2, a1, 15
    andi s2, s2, 1
    
    # exp_a = ((a.bits >> 7) & 0xFF)
    srli s3, a0, 7
    andi s3, s3, 0xFF
    
    # exp_b = ((b.bits >> 7) & 0xFF)
    srli s4, a1, 7
    andi s4, s4, 0xFF
    
    # mant_a = a.bits & 0x7F
    andi s5, a0, 0x7F
    
    # mant_b = b.bits & 0x7F
    andi s6, a1, 0x7F 
    
    
    # result_sign = sign_a ^ sign_b
    xor  t1, s1, s2
    
    # if (exp_a == 0xFF), exp_a all one jump to bf16_mul_a_exp_allOne
    li   t6, 0xFF
    beq  s3, t6, bf16_mul_a_exp_allOne


    # if (exp_b == 0xFF), exp_b all one jump to bf16_mul_b_exp_allOne
    beq  s4, t6, bf16_mul_b_exp_allOne
    
    # if ((!exp_a && !mant_a) || (!exp_b && !mant_b))
    or   t5, s3, s5
    or   t6, s4, s6
    beq  t5, x0, bf16_mul_retSign_slli15
    beq  t6, x0, bf16_mul_retSign_slli15

    # exp_adjust = 0
    add  t4, x0, x0
    
    # if (!exp_a), a exp is zero, jump bf16_mul_a_exp_zero
    beq  s3, x0, bf16_mul_a_exp_zero
    
    # mant_a |= 0x80
    ori  s5, s5, 0x80
    
    # if (!exp_b), b exp is zero, jump bf16_mul_b_exp_zero
    beq  s4, x0, bf16_mul_b_exp_zero
    
    # mant_b |= 0x80
    ori  s6, s6, 0x80
    
    j    bf16_mul_result_exp_mant
    
bf16_mul_a_exp_zero:
    # (mant_a & 0x80)
    andi t6, s5, 0x80

    #  while (!(mant_a & 0x80))
    beq  t6, x0, bf16_mul_a_exp_zero_while
    
    # exp_a = 1
    addi s3, x0, 1
    
    # if (!exp_b), b exp is zero, jump bf16_mul_b_exp_zero
    beq  s4, x0, bf16_mul_b_exp_zero
    
    # mant_b |= 0x80
    ori  s6, s6, 0x80
    
    j    bf16_mul_result_exp_mant
    
bf16_mul_a_exp_zero_while:
    # mant_a <<= 1
    slli s5, s5, 1
    # exp_adjust--
    addi t4, t4, -1
    
    # (mant_a & 0x80)
    andi t6, s5, 0x80
    
    #  while (!(mant_a & 0x80))
    beq  t6, x0, bf16_mul_a_exp_zero_while
    
    # exp_a = 1
    addi s3, x0, 1
    
    # if (!exp_b), b exp is zero, jump bf16_mul_b_exp_zero
    beq  s4, x0, bf16_mul_b_exp_zero
    
    # mant_b |= 0x80
    ori  s6, s6, 0x80
    
    j    bf16_mul_result_exp_mant

bf16_mul_b_exp_zero:
    # (mant_b & 0x80)
    andi t6, s6, 0x80

    #  while (!(mant_b & 0x80))
    beq  t6, x0, bf16_mul_b_exp_zero_while
    
    # exp_b = 1
    addi s4, x0, 1
    
    j    bf16_mul_result_exp_mant

bf16_mul_b_exp_zero_while:
    # mant_b <<= 1
    slli s6, s6, 1
    # exp_adjust--
    addi t4, t4, -1
    
    # (mant_b & 0x80)
    andi t6, s6, 0x80
    
    #  while (!(mant_b & 0x80))
    beq  t6, x0, bf16_mul_b_exp_zero_while
    
    # exp_b = 1
    addi s4, x0, 1
    
    
bf16_mul_result_exp_mant:
    # result_mant = (uint32_t) mant_a * mant_b
    mul  t3, s5, s6
    
    # result_exp = (int32_t) exp_a + exp_b - BF16_EXP_BIAS + exp_adjust
    li   t6, BF16_EXP_BIAS
    # result_exp = exp_a + exp_b
    add  t2, s3, s4
    
    # result_exp = result_exp - BF16_EXP_BIAS
    sub  t2, t2, t6
    
    # result_exp = result_exp + exp_adjust
    add  t2, t2, t4
    
    
    # if (result_mant & 0x8000) 
    li   t6, 0x8000
    and  t6, t3, t6
    beq  t6, x0, bf16_mul_set_result_mant_srl7
    
    # result_mant = (result_mant >> 8) & 0x7F
    srli t3, t3, 8
    andi t3, t3, 0x7F
    
    # result_exp++
    addi t2, t2, 1

    j    bf16_mul_check_result_exp
    
    
bf16_mul_set_result_mant_srl7:
    # result_mant = (result_mant >> 7) & 0x7F
    srli t3, t3, 7
    andi t3, t3, 0x7F
    
bf16_mul_check_result_exp:
    # if (result_exp >= 0xFF)
    li   t6, 0xFF
    bge  t2, t6, bf16_mul_result_exp_bg0xFF_ret
    
    # if (result_exp <= 0), exp > 0, jump ret
    blt  x0, t2, bf16_mul_ret
    
    
    # if (result_exp < -6)
    li   t6, -6
    blt  t2, t6, bf16_mul_result_exp_smNeg6_ret
    
    # result_mant >>= (1 - result_exp)
    li   t6, 1
    sub  t5, t6, t2
    srl  t3, t3, t5
    
    # result_exp = 0
    add  t2, x0, x0
    
    # return 
    j    bf16_mul_ret
    
bf16_mul_result_exp_bg0xFF_ret:
    # return ((result_sign << 15) | 0x7F80)
    li   t6, 0x7F80
    slli t1, t1, 15
    or   a0, t1, t6

    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_mul_result_exp_smNeg6_ret:
    # return (result_sign << 15)
    slli a0, t1, 15
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
bf16_mul_a_exp_allOne:
    # if (mant_a), mant_a isn't zero, jump return a 
    bne  s5, x0, bf16_mul_reta
    
    # if (!exp_b && !mant_b) <=> b exp and mant equal 0
    or   t5, s4, s6
    beq  t5, x0, bf16_mul_retNan
    
    
    # return ((result_sign << 15) | 0x7F80)
    li   t6, 0x7F80
    slli t1, t1, 15
    or   a0, t1, t6
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
    
bf16_mul_b_exp_allOne:
    # if (mant_b), mant_b isn't zero, jump return b 
    bne  s6, x0, bf16_mul_retb
    
    # if (!exp_a && !mant_a) <=> a exp and mant equal 0
    or   t5, s3, s5
    beq  t5, x0, bf16_mul_retNan
      
    # return ((result_sign << 15) | 0x7F80)
    li   t6, 0x7F80
    slli t1, t1, 15
    or   a0, t1, t6
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

bf16_mul_retSign_slli15:
    # return result_sign << 15
    slli a0, t1, 15
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
bf16_mul_retNan:
    # a0 = a1
    li   a0, BF16_NAN
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0


bf16_mul_reta:
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
bf16_mul_retb:
    # a0 = a1
    add  a0, a1, x0
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0
    
    
bf16_mul_ret:
    # return ((result_sign << 15) | ((result_exp & 0xFF) << 7) | (result_mant & 0x7F))
    slli t1, t1, 15
    andi t2, t2, 0xFF
    slli t2, t2, 7
    andi t3, t3, 0x7F
    or   a0, t1, t2
    or   a0, a0, t3
    
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

# =======================================================
# Function : bf16_div()
# Parameter : bf16_t a, bf16_t b
# Variable : 
# Description : Performs bfloat16 division using bit-level integer division and handles edge cases.
# Return : b16_t value(a0)
# =======================================================
# test ok
bf16_div:
    addi sp, sp, -24
    sw   s6, 20(sp)
    sw   s5, 16(sp)
    sw   s4, 12(sp)
    sw   s3, 8(sp)
    sw   s2, 4(sp)
    sw   s1, 0(sp)

    # sign_a =  (a.bits >> 15) & 1
    srli s1, a0, 15
    andi s1, s1, 1

    # sign_b = (b.bits >> 15) & 1;
    srli s2, a1, 15
    andi s2, s2, 1
    
    # exp_a = ((a.bits >> 7) & 0xFF)
    srli s3, a0, 7
    andi s3, s3, 0xFF
    
    # exp_b = ((b.bits >> 7) & 0xFF)
    srli s4, a1, 7
    andi s4, s4, 0xFF
    
    # mant_a = a.bits & 0x7F
    andi s5, a0, 0x7F
    
    # mant_b = b.bits & 0x7F
    andi s6, a1, 0x7F 
    
    
    # result_sign = sign_a ^ sign_b
    xor  t1, s1, s2
    
    
    # if (exp_b == 0xFF)
    li   t6, 0xFF
    beq  s4, t6, bf16_div_b_exp_allOne
    
    
    # if (!exp_b && !mant_b)
    or   t5, s4, s6
    beq  t5, x0, bf16_div_b_exp_mant_zero
    
    # if (exp_a == 0xFF)
    beq  s3, t6, bf16_div_a_exp_allOne
    
    # if (!exp_a && !mant_a), a exp and mant all zero
    or   t5, s3, s5
    beq  t5, x0, bf16_div_a_exp_mant_zero
    
    # if (exp_a)
    bne  s3, x0, bf16_div_mant_a_or0x80
    
    # if (exp_b)
    bne  s4, x0, bf16_div_mant_b_or0x80
    
    j bf16_div_run
    
bf16_div_mant_a_or0x80:
    # mant_a |= 0x80
    ori  s5, s5, 0x80
    
    # if (exp_b)
    bne  s4, x0, bf16_div_mant_b_or0x80
    
    j    bf16_div_run
    
bf16_div_mant_b_or0x80:
    # mant_b |= 0x80
    ori  s6, s6, 0x80
    
    j    bf16_div_run

bf16_div_run:
    
    # dividend = (uint32_t) mant_a << 15
    slli t3, s5, 15
    
    # divisor = mant_b
    add  t4, s6, x0
    
    # uint32_t quotient = 0
    add  t5, x0, x0
    
    # set i = 0
    add  t0, x0, x0
    
    li   t6, 16

    j    bf16_div_for
    
bf16_div_for:
    # for (int i = 0; i < 16; i++)
    bge  t0, t6, bf16_div_result_exp
    
    # quotient <<= 1
    slli t5, t5, 1
    
    # (divisor << (15 - i))
    li   t6, 15
    sub  t6, t6, t0
    sll  t6, t4, t6
    
    # if (dividend >= (divisor << (15 - i)))
    bge  t3, t6, bf16_div_for_divdend_divsor
    
    li   t6, 16
    
    # i++
    addi t0, t0, 1
    
    j    bf16_div_for
    
bf16_div_for_divdend_divsor:
    # dividend -= (divisor << (15 - i))
    sub  t3, t3, t6
    
    # quotient |= 1
    ori  t5, t5, 1
    
    li   t6, 16
    
    # i++
    addi t0, t0, 1
    
    j    bf16_div_for
    

bf16_div_result_exp:
    # result_exp = (int32_t) exp_a - exp_b + BF16_EXP_BIAS
    li   t6, BF16_EXP_BIAS
    sub  t2, s3, s4
    add  t2, t2, t6

    # if (!exp_a)
    beq  s3, x0, bf16_div_result_exp_minus1
    
    # if (!exp_b)
    beq  s4, x0, bf16_div_result_exp_plus1
    
    j    bf16_div_quotient
    
bf16_div_result_exp_minus1:
    # result_exp--
    addi t2, t2, -1
    
    # if (!exp_b)
    beq  s4, x0, bf16_div_result_exp_plus1
    
    j    bf16_div_quotient
    
bf16_div_result_exp_plus1:
    # result_exp++
    addi t2, t2, 1
    
    j    bf16_div_quotient
    
bf16_div_quotient:    
    # if (quotient & 0x8000), quot&0x8000 > 0, srli 8
    li   t6, 0x8000
    and  t6, t5, t6
    bne  t6, x0, bf16_div_quot_srl8

    # else jump quot while
    j    bf16_div_quot_while
    
bf16_div_quot_while:
    # while (!(quotient & 0x8000) && result_exp > 1)
    bne  t6, x0, bf16_div_quot_srl8
    li   t0, 1
    bge  t0, t2, bf16_div_quot_srl8
    
    # quotient <<= 1
    slli t5, t5, 1
    
    # result_exp--
    addi t2, t2, -1
    
    # quotient & 0x8000
    li   t6, 0x8000
    and  t6, t5, t6
    
    j    bf16_div_quot_while
    
bf16_div_quot_srl8:
    # quotient >>= 8
    srli t5, t5, 8
    
    j    bf16_div_result_exp_ret
    
bf16_div_result_exp_ret:
    # quotient &= 0x7F
    andi t5, t5, 0x7F
    
    # if (result_exp >= 0xFF)
    li   t6, 0xFF
    bge  t2, t6, bf16_div_ret_sign_sll15_or7F80
    
    # if (result_exp <= 0)
    bge  x0, t2, bf16_div_ret_sign_sll15
    
    j    bf16_div_ret
    
bf16_div_a_exp_allOne:
    # if (mant_a), mant_a != 0, return a
    bne  s5, x0, bf16_div_reta
    
    # return ((result_sign << 15) | 0x7F80)
    j    bf16_div_ret_sign_sll15_or7F80


bf16_div_a_exp_mant_zero:
    # return (result_sign << 15)
    j    bf16_div_ret_sign_sll15
    
bf16_div_b_exp_allOne:
    # if (mant_b), b mant != 0, return b
    bne  s6, x0, bf16_div_retb
    
    # if (exp_a == 0xFF && !mant_a)
    li   t6, 0xFF
    beq  s3, t6, bf16_div_b_check_a_NAN
    
    # return result_sign << 15
    j    bf16_div_ret_sign_sll15

bf16_div_b_exp_mant_zero:
    # if (!exp_a && !mant_a), a exp and mant all zero, return NAN
    or   t5, s3, s5
    beq  t5, x0, bf16_div_retNAN
    
    # return ((result_sign << 15) | 0x7F80)
    j    bf16_div_ret_sign_sll15_or7F80
    
bf16_div_b_check_a_NAN:
    # if (exp_a == 0xFF && !mant_a), exp = 0xFF, mant == 0 return nan
    beq  s5, x0, bf16_div_retNAN 

    # else mant = 0
    
    # return result_sign << 15
    j    bf16_div_ret_sign_sll15
    

bf16_div_ret_sign_sll15_or7F80:
    # return ((result_sign << 15) | 0x7F80)
    slli a0, t1, 15
    li   t6, 0x7F80
    or   a0, a0, t6
    j    bf16_div_return

bf16_div_ret_sign_sll15:
    # return result_sign << 15
    slli a0, t1, 15
    j    bf16_div_return

bf16_div_retNAN:
    # set a0 = BF16_NAN
    li   a0, BF16_NAN
    j    bf16_div_return

bf16_div_reta:
    j    bf16_div_return

bf16_div_retb:
    # set a0 = b
    add  a0, a1, x0  
    
    j    bf16_div_return


bf16_div_ret:
    # ((result_sign << 15) | ((result_exp & 0xFF) << 7) |(quotient & 0x7F))
    slli t1, t1, 15
    andi t2, t2, 0xFF
    slli t2, t2, 7
    andi t5, t5, 0x7F
    or   a0, t1, t2
    or   a0, a0, t5
    
    j    bf16_div_return

bf16_div_return:
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    lw   s4, 12(sp)
    lw   s5, 16(sp)
    lw   s6, 20(sp)
    addi sp, sp, 24
    jalr x0, ra, 0

# =======================================================
# Function : bf16_sqrt()
# Parameter : bf16_t a
# Variable : 
# Description : Computes the square root of a bfloat16 number using bitwise operations and binary search.
# Return : b16_t value(a0)
# =======================================================
# test ok
bf16_sqrt:
    addi sp, sp, -12
    sw   s3, 8(sp)
    sw   s2, 4(sp)
    sw   s1, 0(sp)
    
    # sign = (a.bits >> 15) & 1
    srli s1, a0, 15
    andi s1, s1, 1
    
    # exp = ((a.bits >> 7) & 0xFF)
    srli s2, a0, 7
    andi s2, s2, 0xFF
    
    # mant = a.bits & 0x7F
    andi s3, a0, 0x7F
    
    
    # if (exp == 0xFF), exp all one, jump bf16_sqrt_exp_allOne
    li   t6, 0xFF
    beq  s2, t6, bf16_sqrt_exp_allOne
    
    
    # if (!exp && !mant), exp and mant all zeros, return zero
    or   t0, s2, s3
    beq  t0, x0, bf16_sqrt_retZero
    
    
    # if (sign), sign = 1 => negative, return nan
    bne  s1, x0, bf16_sqrt_retNAN
    
    
    # if (!exp), exp = 0, return zero
    beq  s2, x0, bf16_sqrt_retZero


    # e = exp - BF16_EXP_BIAS
    li   t6, BF16_EXP_BIAS
    sub  t1, s2, t6
    
    # m = 0x80 | mant
    ori  t3, s3, 0x80
    
    j    bf16_sqrt_adjust_odd_exp

bf16_sqrt_adjust_odd_exp:
    # if (e & 1), odd, jump bf16_sqrt_adjust_odd
    andi t5, t1, 1
    bne  t5, x0, bf16_sqrt_adjust_odd
    
    # else jump bf16_sqrt_adjust_even
    j    bf16_sqrt_adjust_even

bf16_sqrt_adjust_odd:
    # m <<= 1
    slli t3, t3, 1
    
    # new_exp = ((e - 1) >> 1) + BF16_EXP_BIAS
    addi t2, t1, -1
    srai t2, t2, 1
    li   t6, BF16_EXP_BIAS
    add  t2, t2, t6
    
    j    bf16_sqrt_search_square
        
bf16_sqrt_adjust_even:
    # new_exp = (e >> 1) + BF16_EXP_BIAS
    srai t2, t1, 1
    li   t6, BF16_EXP_BIAS
    add  t2, t2, t6
    
    j    bf16_sqrt_search_square
    
bf16_sqrt_search_square:
    # low = 90
    li   t4, 90
    
    # high = 256
    li   t5, 256
    
    # result = 128
    li   t6, 128

    j    bf16_sqrt_search_square_while
    
bf16_sqrt_search_square_while:
    # while (low <= high), low > high, jump ensure result
    blt  t5, t4, bf16_sqrt_norm_ensure_result
    
    #  mid = (low + high) >> 1
    add  t0, t4, t5
    srli t0, t0, 1
    
    j    bf16_sqrt_pow_init

bf16_sqrt_search_square_pow:
    # sq = (mid * mid) / 128
    srli t1, t1, 7
    
    # if (sq <= m)
    bge  t3, t1, bf16_sqrt_search_square_while_midPlus1
    
    # else
    
    j    bf16_sqrt_search_square_while_midMinus1 

bf16_sqrt_pow_init:
    # set sq = 0 , s5 = t0 , s4 = t0
    add  s4, t0, x0
    add  s5, t0, x0
    add  t1, x0, x0

    j    bf16_sqrt_pow_forLoop
        
bf16_sqrt_pow_forLoop: 
    # if s5 == 0, return bf16_sqrt_search_square_pow
    beq  s5, x0, bf16_sqrt_search_square_pow
 
    andi s0, s5, 1
    # if (s0&1  ==  0), j bf16_sqrt_pow_lsbZero
    beq  s0, x0, bf16_sqrt_pow_lsbZero

    j    bf16_sqrt_pow_lsbOne

bf16_sqrt_pow_lsbOne:
    # sq = sq + s4
    add  t1, t1, s4
    
    # s4 <<= 1
    slli s4, s4, 1

    # s5 >>= 1
    srli s5, s5, 1

    j    bf16_sqrt_pow_forLoop

bf16_sqrt_pow_lsbZero:
    # s4 <<= 1
    slli s4, s4, 1

    # s5 >>= 1
    srli s5, s5, 1

    j    bf16_sqrt_pow_forLoop

bf16_sqrt_search_square_while_midPlus1:
    # result = mid;
    add  t6, t0, x0
    
    # low = mid + 1;
    addi t4, t0, 1
    
    j    bf16_sqrt_search_square_while 
    
bf16_sqrt_search_square_while_midMinus1:
    # high = mid - 1;
    addi t5, t0, -1
    
    j    bf16_sqrt_search_square_while 
    
bf16_sqrt_norm_ensure_result:
    # if (result >= 256), bge
    li   t0, 256
    bge  t6, t0, bf16_sqrt_norm_ensure_result_bge256
    
    # else if (result < 128) 
    li   t0, 128
    blt  t6, t0, bf16_sqrt_norm_ensure_result_blt128
    
    j    bf16_sqrt_extract_mantissa
    
bf16_sqrt_norm_ensure_result_bge256:
    # result >>= 1
    srli t6, t6, 1
    
    # new_exp++
    addi t2, t2, 1
    
    j    bf16_sqrt_extract_mantissa
    
    
bf16_sqrt_norm_ensure_result_blt128:
    li   t0, 128
    li   t1, 1
    j    bf16_sqrt_norm_ensure_result_blt128_while
    
bf16_sqrt_norm_ensure_result_blt128_while:
    # while (result < 128 && new_exp > 1)

    # result < 128 
    bge  t6, t0, bf16_sqrt_extract_mantissa
    
    # new_exp > 1
    bge  t1, t2, bf16_sqrt_extract_mantissa
    
    
    # result <<= 1
    slli t6, t6, 1
    
    # new_exp--
    addi t2, t2, -1
    
    j    bf16_sqrt_norm_ensure_result_blt128_while
    
    
bf16_sqrt_extract_mantissa:
    # new_mant = result & 0x7F
    andi t4, t6, 0x7F
    
    li   t5, 0xFF
    # if (new_exp >= 0xFF)
    bge  t2, t5, bf16_sqrt_retBge0xFF
    
    # if (new_exp <= 0)
    bge  x0, t2, bf16_sqrt_retZero
    
    j    bf16_sqrt_ret
    
bf16_sqrt_exp_allOne:
    # if (mant), mant != 0, return a
    bne  s3, x0, bf16_sqrt_reta
    
    # if (sign), sign != 0, return nan
    bne  s1, x0, bf16_sqrt_retNAN
    
    # return a
    j    bf16_sqrt_reta

bf16_sqrt_retBge0xFF:
    # return 0x7F80
    li   a0, 0x7F80
    j    bf16_sqrt_return

bf16_sqrt_retZero:
    # return zero
    li   a0, BF16_ZERO
    j    bf16_sqrt_return
    
bf16_sqrt_retNAN:
    # return NAN
    li   a0, BF16_NAN
    j    bf16_sqrt_return

bf16_sqrt_reta:
    # return a
    j    bf16_sqrt_return

bf16_sqrt_ret:
    # return ((new_exp & 0xFF) << 7) | new_mant
    andi a0, t2, 0xFF
    slli a0, a0, 7
    or   a0, a0, t4
    j    bf16_sqrt_return
    
    
bf16_sqrt_return:
    lw   s1, 0(sp)
    lw   s2, 4(sp)
    lw   s3, 8(sp)
    addi sp, sp, 12
    jalr x0, ra, 0    