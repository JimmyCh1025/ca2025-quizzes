.set STDOUT, 1
.set SYSREAD, 63
.set SYSWRITE, 64
.set SYSEXIT, 93

.data
input:
    .word 1, 509, 1000

ans:
    .word 1, 511, 1023

output_str:
    .string "output = "

answer_str:
    .string ", answer = "  

endline_str:
    .string "\n"

true_str:
    .string "True\n"

false_str:
    .string "False\n"

.lcomm buffer, 12

.text
.global lc3370

lc3370:
    addi sp, sp, -24
    sw   s0, 20(sp)
    sw   s1, 16(sp)
    sw   s2, 12(sp)
    sw   s3, 8(sp)
    sw   s4, 4(sp)
    sw   ra, 0(sp)

    # load input array
    la   s0, input
    
    # load answer array
    la   s1, ans

    j    main_for

main_for:
    
    # loop unrolling
    
    # load input[0] to a0
    addi t3, s0, 0
    lw   a0, 0(t3)
 
    # call smallestNumber    
    addi sp, sp, -4
    sw   ra, 0(sp)


    jal  ra, smallestNumber
    
    
    # output = smallestNumber(input[0])
    add  s2, a0, x0
    

    
    # load input[1] to a0
    addi t3, s0, 4
    lw   a0, 0(t3)
     
    # call smallestNumber  
    jal  ra, smallestNumber
    
    
    # output = smallestNumber(input[1])
    add  s3, a0, x0
    
    
    # load input[2] to a0
    addi t3, s0, 8
    lw   a0, 0(t3)
     
    # call smallestNumber   
    jal  ra, smallestNumber
    
    # output = smallestNumber(input[1])
    add  s4, a0, x0
    

    lw   ra, 0(sp)
    addi sp, sp, 4
    
    j    print_result_0
    
print_result_0:
    # print "output = "
    li   a0, STDOUT
    la   a1, output_str
    li   a2, 9
    li   a7, SYSWRITE
    ecall

    # print output
    addi t0, s2, 0
    la   a1, buffer
    call num_to_str
    
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    # add  a2, t4, x0
    li   a7, SYSWRITE
    ecall
    
    # ", answer = "
    li   a0, STDOUT
    la   a1, answer_str
    li   a2, 11
    li   a7, SYSWRITE
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 0
    lw   a0, 0(t2)
    
    addi t0, a0, 0
    la   a1, buffer
    call num_to_str

    # print buffer
    addi t2, s1, 0
    lw   t2, 0(t2)
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    li   a7, SYSWRITE
    ecall

    # print "\n"
    li   a0, STDOUT
    la   a1, endline_str
    li   a2, 1
    li   a7, SYSWRITE
    ecall   

    # if (output[i] == ans[i])
    beq  s2, t2, print_true_0
    # else 
    j    print_false_0
    
    
print_true_0:

    # print "True\n"
    li   a0, STDOUT
    la   a1, true_str
    li   a2, 5
    li   a7, SYSWRITE
    ecall   

    j    print_result_1
    
print_false_0:
    
    # print "False\n"
    li   a0, STDOUT
    la   a1, false_str
    li   a2, 6
    li   a7, SYSWRITE
    ecall   
    
    j    print_result_1

print_result_1:

    # print "output = "
    li   a0, STDOUT
    la   a1, output_str
    li   a2, 9
    li   a7, SYSWRITE
    ecall
    
    # print output
    addi t0, s3, 0
    la   a1, buffer
    call num_to_str
    
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    li   a7, SYSWRITE
    ecall
    
    # ", answer = "  
    li   a0, STDOUT
    la   a1, answer_str
    li   a2, 11
    li   a7, SYSWRITE
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 4
    lw   a0, 0(t2)
    
    addi t0, a0, 0
    la   a1, buffer
    call num_to_str
    
    # print buffer
    addi t2, s1, 4
    lw   t2, 0(t2)
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    li   a7, SYSWRITE
    ecall
    
    # print "\n"
    li   a0, STDOUT
    la   a1, endline_str
    li   a2, 1
    li   a7, SYSWRITE
    ecall   
    
    # if (output == ans[1])
    beq  s3, t2, print_true_1
    # else 
    j    print_false_1
    
print_true_1:
    
    # print "True\n"
    li   a0, STDOUT
    la   a1, true_str
    li   a2, 5
    li   a7, SYSWRITE
    ecall   
    
    j    print_result_2
    
print_false_1:
    
    # print "False\n"
    li   a0, STDOUT
    la   a1, false_str
    li   a2, 6
    li   a7, SYSWRITE
    ecall   
    
    j    print_result_2
    
print_result_2:
    # print "output = "
    li   a0, STDOUT
    la   a1, output_str
    li   a2, 9
    li   a7, SYSWRITE
    ecall
    
    # print output
    addi t0, s4, 0
    la   a1, buffer
    call num_to_str
    
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    li   a7, SYSWRITE
    ecall
    
    # ", answer = "  
    li   a0, STDOUT
    la   a1, answer_str
    li   a2, 11
    li   a7, SYSWRITE
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 8
    lw   a0, 0(t2)
    
    addi t0, a0, 0
    la   a1, buffer
    call num_to_str
    
    # print buffer
    addi t2, s1, 8
    lw   t2, 0(t2)
    li   a0, STDOUT
    la   a1, buffer
    li   a2, 12
    li   a7, SYSWRITE
    ecall
    
    # print "\n"
    li   a0, STDOUT
    la   a1, endline_str
    li   a2, 1
    li   a7, SYSWRITE
    ecall   
    
    # if (output == ans[2])
    beq  s4, t2, print_true_2
    # else 
    j    print_false_2
    
print_true_2:
    
    # print "True\n"
    li   a0, STDOUT
    la   a1, true_str
    li   a2, 5
    li   a7, SYSWRITE
    ecall   


    j    main_exit
    
print_false_2:
    
    # print "False\n"
    li   a0, STDOUT
    la   a1, false_str
    li   a2, 6
    li   a7, SYSWRITE
    ecall   
    

    j    main_exit
    
smallestNumber:
    addi sp, sp, -12
    sw   ra, 8(sp)
    sw   t0, 4(sp)
    sw   t1, 0(sp)
   
    # call clz    
    addi sp, sp, -8 # store ra, a0(n)
    sw   ra, 4(sp)
    sw   a0, 0(sp)
    jal  ra, clz
    
    li   t0, 32     # bit_len = 32
    li   t1, 1   
    
    sub  t0, t0, a0 # bit_len = 32 - clz(n)
    lw   a0, 0(sp)
    lw   ra, 4(sp)
    addi sp, sp, 8
    
    sll  t1, t1, t0
    addi a0, t1, -1
    
    
    lw   t1, 0(sp)
    lw   t0, 4(sp)
    lw   ra, 8(sp)
    addi sp, sp, 12
    
    jalr x0, x1, 0

clz:
    
    li   t0, 32 # t0 = n
    li   t1, 16 # t1 = c
    
    j    clz_whileLoop
    
clz_whileLoop:
    srl  t2, a0, t1                # y = t2, y = x >> c
    beq  t2, x0, shift_right_1bit  # if y == 0, jump to shift_right_1bit
    sub  t0, t0, t1                # n = n - c
    addi a0, t2, 0                 # x = y
    
    j    shift_right_1bit
    
shift_right_1bit:
    srli t1, t1, 1                 # c = c >> 1
    bne  t1, x0, clz_whileLoop     # if c != 0, jump to clz_whileLoop

    sub  a0, t0, a0   # x = n - x
    jalr x0, x1, 0


num_to_str:
    # t1 is string index
    addi t1, a1, 11
    
    beqz t0, num_to_str_zero_case
   
    j    num_to_str_loop
    
num_to_str_loop:
    li   t2, 10
    li   t3, 0

    j    num_to_str_div10
    
num_to_str_div10:
    # if t0 >= 10, t0 - 10
    bge  t0, t2, num_to_str_sub10
    j    num_to_str_div_done
    
num_to_str_sub10:
    sub  t0, t0, t2      
    addi t3, t3, 1      
    j    num_to_str_div10

num_to_str_div_done:
    # point to next string index
    addi t0, t0, '0'
    sb   t0, 0(t1)   
    addi t0, t3, 0 
    addi t1, t1, -1     
    bnez t0, num_to_str_loop       

    j    num_to_str_done
    
num_to_str_zero_case:
    li   t3, '0'         
    sb   t3, 0(t1)
    addi t1, t1, -1
    j    num_to_str_done
    
num_to_str_done:
    # put "\0" on the string end
    sb   zero, 0(t1)
    addi t1, t1, -1
    ret 
    
main_exit:
    lw   s0, 20(sp)
    lw   s1, 16(sp)
    lw   s2, 12(sp)
    lw   s3, 8(sp)
    lw   s4, 4(sp)
    lw   ra, 0(sp)
    addi sp, sp, 24
    ret
