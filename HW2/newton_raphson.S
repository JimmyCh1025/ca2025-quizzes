    .equ STDOUT, 1
    .equ WRITE, 64
    .equ FP_EXP_BIAS, 127
    .equ FP_NAN, 0x7FC00000
    .equ FP_ZERO, 0x00000000
    
.data
strX:       .asciz  "X = "
strY:       .asciz  ",Y = "
strEnd:     .asciz  "\n"

rsqrt_table:
    .word 65535, 46341, 32768, 23170, 16384, 11585,  8192,  5793,  4096,  2896, 2048,  1448,  1024,   724,   512, 362,   256,   181,   128,    90,  64,    45,    32,    23,    16,  11,     8,     6,     4,     3,  2,     1                  

.lcomm buffer, 32

.text
.globl nrRsqrt
nrRsqrt:
    addi sp, sp, -4
    sw   ra, 0(sp)
    # set x = t3
    add  t3, a0, x0

    j    find_msb
    
    
find_msb:
    # t4 = x
    add  t4, t3, x0

    # t5 = msb index
    addi t5, x0, -1
    
    j    find_msb_loop
    
find_msb_loop:

    beq  t4, x0, newton_raphson
    # t4/2
    srli t4, t4, 1
    # index + 1 
    addi t5, t5, 1
    
    j    find_msb_loop

newton_raphson:

    # y = rsqrt_table[msb_x]
    la   t1, rsqrt_table
    
    slli t2, t5, 2
    add  t1, t1, t2
    lw   t4, 0(t1)
    
    
    # call print_float(y)
    # put char to buffer
    la   a1, buffer
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    add  a0, t4, x0
    
    jal  intToStr
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    
    # print buffer
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 32
    li   a7, WRITE
    ecall
    
    # printf("\n")
    li   a0, STDOUT
    la   a1, strEnd
    li   a2, 1
    li   a7, WRITE
    ecall
    
    
    # converge 4 times
    addi t5, x0, 4


    j    newton_raphson_loop
    
    
newton_raphson_loop:
   
    # assign a0 = y, a1 = y
    add  a0, x0, t4
    add  a1, x0, t4
   
    # call mul(y, y)
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  ra, mul
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    # return y*y value to t2
    add  t2, a0, x0
    
    
    # assign a0 = x, a1 = t2
    add  a0, x0, t3
    add  a1, x0, t2
   
    # call mul(x, y^2)
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  ra, mul
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    # return x*y*y value to t2
    add  t2, a0, x0
    
    
    # t2 = (x*y^2) >> 16
    srli t2, t2, 16
    
    
    # set t1 = 3
    li   t1, 3
    # t1 = 3 << 16
    slli t1, t1, 16
    
    # (3<<16) - x*y^2
    sub  t2, t1, t2
    
    
    # assign a0 = y, a1 = t2
    add  a0, x0, t4
    add  a1, x0, t2
   
    # call mul(y, (3<<16) - x*y^2)
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    jal  ra, mul
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    # return y*((3<<16) - x*y^2) value to t2
    add  t2, a0, x0
    
    # y = y*((3<<16) - x*y^2) >> 17
    srli t4, t2, 17
    

    # count = count - 1
    addi t5, t5, -1 
    beq  t5, x0, nrRsqrt_done
    
    j    newton_raphson_loop


mul:
    # set t0 = a0, t1 = a1
    add  t0, a0, x0
    add  t1, a1, x0
    
    # set result = a0 = 0
    add  a0, x0, x0
    
    j    mul_loop
    
    
mul_loop:
    beq  t1, x0, mul_done
    
    # compare first bit of y 
    andi t6, t1, 1
    # first bit of y is zero jump to mul_shift
    beq  t6, x0, mul_shift
    
    # first bit of y is one
    # result = result + x
    add  a0, a0, t0
    
    j    mul_shift
    
mul_shift:
    # x <<= 1
    slli t0, t0, 1
    
    # y >>= 1
    srli t1, t1, 1
    
    j    mul_loop

mul_done:
    ret


nrRsqrt_done:

    # printf("X = ")
    li   a0, STDOUT
    la   a1, strX
    li   a2, 4
    li   a7, WRITE
    ecall
    
    
    # call intToStr(x)
    
    # put char to buffer
    la   a1, buffer
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    
    add  a0, t3, x0
    
    jal  intToStr
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    
    # print buffer
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 32
    li   a7, WRITE
    ecall
    
    
    # printf(",Y = ")
    li   a0, STDOUT
    la   a1, strY
    li   a2, 5
    li   a7, WRITE
    ecall
    
    
    # call print_float(y)
    # put char to buffer
    la   a1, buffer
    addi sp, sp, -4
    sw   ra, 0(sp)
    
    #srli t5, t4, 16
    #add  a0, t5, x0
    add  a0, t4, x0
    
    jal  intToStr
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    
    
    # print buffer
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 32
    li   a7, WRITE
    ecall
    
    
    # printf("\n")
    li   a0, STDOUT
    la   a1, strEnd
    li   a2, 1
    li   a7, WRITE
    ecall
    
    
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret
    
 
    
intToStr:
    # assign t0 = x 
    add  t0, a0, x0
    
    # t6 is buffer index
    addi t6, a1, 31
   
    # if x = 0, then jump to zero case
    beqz t0, intToStr_zero_case
    
    # assign t1 = 10
    li   t1, 10
    j    intToStr_loop
    
    
intToStr_loop:
    # t2(count 10) = 0
    li   t2, 0
    
    j    intToStr_div10
    

intToStr_div10:
    # if x >= 10, then x-10
    bge  t0, t1, intToStr_sub10
    j    intToStr_div10_done

intToStr_sub10:
    # x = x-10
    sub  t0, t0, t1
    # count++
    addi t2, t2, 1
    
    j    intToStr_div10

intToStr_div10_done:
    # point to next string index
    addi t0, t0, '0'
    sb   t0, 0(t6)   
    addi t0, t2, 0 
    addi t6, t6, -1     
    bnez t0, intToStr_loop       

    j    intToStr_done

intToStr_zero_case:
    # put 0 to buffer => string str[0] = '0' 
    li   t0, '0'
    sb   t0, 0(t6)
    addi t6, t6, -1
     
    j    intToStr_done
     


intToStr_done:
    # put "\0" on the string end
    sb   zero, 0(t6)
    addi t6, t6, -1
    ret 
    
    

 
