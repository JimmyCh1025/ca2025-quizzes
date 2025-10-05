.data
all_tests_passed_str:
    .string "All tests passed.\n"

mismatch_prod_val_str:
    .string ": produces value "
    
mismatch_encode_str:
    .string " but encodes back to "

not_incr_val_str:
    .string ": value "
    
not_incr_prev_val_str:
    .string " <= previous_value "
    
endline_str:
    .string "\n"

.text
.global main

main:

    jal  ra, test               # call test 
    beq  a0, x0, main_return1   # return 1
    
    # printf "All tests passed.\n"
    la a0, all_tests_passed_str  
    li a7, 4                    # System call number 4 (print string)
    ecall
    
    # return 0
    li   a7, 10
    add  a0, a0, x0
    ecall

main_return1:
    # return 1
    li   a7, 10
    addi a0, a0, 1
    ecall
    
   
test:
    addi sp, sp, -16         
    sw ra, 12(sp)
    sw s0, 8(sp)
    sw s1, 4(sp)
    sw s2, 0(sp)

    addi s0, x0, -1                # previous_value = -1
    addi s1, x0, 0                 # i = 0
    addi s2, x0, 1                 # passed = true

test_loop:
    # if i > 255, break
    li  s3, 0xFF
    blt s3, s1, test_done  
    
    # uint8_t fl = i
    andi s3, s1, 0xFF         
    addi a0, s3, 0
    
    # value = uf8_decode(fl)
    jal  ra, uf8_decode
    addi s4, a0, 0       


    # fl2 = uf8_encode(value)
    addi a0, s4, 0
    jal  ra, uf8_encode
    andi s5, a0, 0xFF            

    # if (fl != fl2)
    bne s3, s5, mismatch

    # if (value <= previous_value)
    ble s4, s0, not_increasing

    # previous_value = value
    mv s0, s4

    addi s1, s1, 1           # i++
    j test_loop

mismatch:
    # printf("%02x: produces value %d but encodes back to %02x\n", fl, value, fl2);
    
    addi a0, s3, 0
    li   a7, 1
    ecall
    
    la   a0, mismatch_prod_val_str
    li   a7, 4
    ecall
    
    addi a0, s4, 0
    li   a7, 1
    ecall
    
    la   a0, mismatch_encode_str
    li   a7, 4
    ecall
    
    addi a0, s5, 0
    li   a7, 1
    ecall
    
    la   a0, endline_str
    li   a7, 4
    ecall

    add s2, x0, x0                 # passed = false
    j continue_loop

not_increasing:
    # printf("%02x: value %d <= previous_value %d\n", fl, value, previous_value);
    
    addi a0, s3, 0    # fl
    li   a7, 1
    ecall
    
    la   a0, not_incr_val_str
    li   a7, 4
    ecall
    
    addi a0, s4, 0    # value
    li   a7, 1
    ecall 
    
    la   a0, not_incr_prev_val_str
    li   a7, 4
    ecall
    
    addi a0, s0, 0    # previous_value
    li   a7, 1
    ecall
    
    la   a0, endline_str
    li   a7, 4
    ecall

    add s2, x0, x0     # passed = false

continue_loop:
    # previous_value = value
    addi s0, t0, 0          
    
    # i++
    addi s1, s1, 1           
    j test_loop

test_done:
    # return passed
    addi a0, s2, 0  
    
    lw   s2, 0(sp)
    lw   s1, 4(sp)
    lw   s0, 8(sp)
    lw   ra, 12(sp)
    addi sp, sp, 16
    jalr x0, x1, 0
    

uf8_decode:
    # u32 mantissa = fl & 0x0F
    andi t0, a0, 0x0F
    
    # u8 exponent = fl >> 4
    srli t1, a0, 4
    andi t1, t1, 0xFF
    
    # u32 offset = (0x7FFF >> (15-exponent)) << 4

    li   t2, 15
    li   t3, 0x7FFF
    sub  t2, t2, t1       # (15-exponent)
    srl  t3, t3, t2   # (0x7FFF >> (15-exponent))
    slli  t4, t3, 4        # (0x7FFF >> (15-exponent)) << 4
    
    # return (mantissa << exponent) + offset;
    sll  a0, t0, t1
    add  a0, a0, t4
    jalr x0, x1, 0
    
uf8_encode:
    li   t0, 16
    blt  a0, t0, uf8_encode_return_val
    
    # assign t0 = value
    addi t0, a0, 0 
    
    # call clz
    addi sp, sp, -8
    sw   ra, 4(sp)
    sw   t0, 0(sp) 
    jal  ra, clz
    
    lw   t0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    
    
    # lz = clz(value)
    add  t1, a0, x0
    
    # msb = 31 - lz
    li   t2, 31
    sub  t2, t2, t1
    
    # exponent = 0
    li   t3, 0
    
    # overflow = 0 
    li   t4, 0
    
    # if msb < 5
    li   t5, 5
    blt  t2, t5, uf8_find_extra_exp
    
uf8_encode_bge5:
    # exponent = msb - 4 
    addi t3, t2, -4
    andi t3, t3, 0xFF
    li   t5, 15
    
    # e = 0
    li   t6, 0
    
    # if 15 < exp
    blt  t5, t3, uf8_exp_bg15 
    j    uf8_calculate_overflow
    
uf8_exp_bg15:
    # exp = 15
    li   t3, 15
    
uf8_calculate_overflow:
    # e < exp
    bge  t6, t3, uf8_adjust_if_off
    # (overflow << 1)+16
    slli t4, t4, 1
    addi t4, t4, 16
    # e++
    addi t6, t6, 1 
    j    uf8_calculate_overflow

uf8_adjust_if_off:
    # 0 >= exponent
    bge  x0, t3, uf8_find_extra_exp
    # value >= overflow
    bge  t0, t4, uf8_find_extra_exp
    # overflow = (overflow-16) >> 1
    addi t4, t4, -16
    srli t4, t4, 1
    # exp--
    addi t3, t3, -1
    j    uf8_adjust_if_off
    
    
uf8_find_extra_exp:
    # while exp < 15
    li   t5, 15
    # if exp >= 15, return value
    bge  t3, t5, uf8_encode_return
    
    # next_overflow = (overflow << 1)+16
    slli t5, t4, 1
    addi t5, t5, 16

    # value < next_overflow 
    blt  t0, t5, uf8_encode_return
    
    # overflow = next_overflow
    add  t4, t5, x0
    # exp++
    addi t3, t3, 1
    j    uf8_find_extra_exp
    
uf8_encode_return: 
    # (value - overflow) >> exponent
    sub  t5, t0, t4
    srl  t5, t5, t3
    andi t5, t5, 0xFF
    
    # (exponent << 4)|mantissa
    slli t1, t3, 4
    andi a0, t1, 0xFF
    or   a0, a0, t5
    jalr x0, x1, 0
    
    
uf8_encode_return_val:
    # return value(a0)
    jalr x0, x1, 0
    



clz:
    li   t0, 32 # t0 = n
    li   t1, 16 # t1 = c
    
clz_whileLoop:
    srl  t2, a0, t1                # y = t2, y = x >> c
    beq  t2, x0, shift_right_1bit  # if y == 0, jump to shift_right_1bit
    sub  t0, t0, t1                # n = n - c
    addi a0, t2, 0                 # x = y
    
shift_right_1bit:
    srli t1, t1, 1                 # c = c >> 1
    bne  t1, x0, clz_whileLoop     # if c != 0, jump to clz_whileLoop

    sub  a0, t0, a0   # x = n - x
    jalr x0, x1, 0    # return x 

