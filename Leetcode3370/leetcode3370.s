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

.text
.global main

main:
    # load input array
    la   s0, input
    
    # load answer array
    la   s1, ans

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
    la   a0, output_str
    li   a7, 4
    ecall
    
    # print output
    addi a0, s2, 0
    li   a7, 1
    ecall
    
    # ", answer = "  
    la   a0, answer_str
    li   a7, 4
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 0
    lw   a0, 0(t2)
    # reorder li and add
    li   a7, 1
    add  t2, a0, x0
    ecall
    
    # print "\n"
    la   a0, endline_str
    li   a7, 4
    ecall   
    
    # if (output[i] == ans[i])
    beq  s2, t2, print_true_0
    # else 
    j    print_false_0
    
    
print_true_0:
    
    # print "True\n"
    la   a0, true_str
    ecall   

    j    print_result_1
    
print_false_0:
    
    # print "False\n"
    la   a0, false_str
    ecall   
    
    j    print_result_1

print_result_1:
    # print "output = "
    la   a0, output_str
    ecall
    
    # print output
    addi a0, s3, 0
    li   a7, 1
    ecall
    
    # ", answer = "  
    la   a0, answer_str
    li   a7, 4
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 4
    lw   a0, 0(t2)
    # reorder li and add
    li   a7, 1
    add  t2, a0, x0
    ecall
    
    # print "\n"
    la   a0, endline_str
    li   a7, 4
    ecall   
    
    # if (output == ans[1])
    beq  s3, t2, print_true_1
    # else 
    j    print_false_1
    
print_true_1:
    
    # print "True\n"
    la   a0, true_str
    ecall   
    
    j    print_result_2
    
print_false_1:
    
    # print "False\n"
    la   a0, false_str
    ecall   
    
    j    print_result_2
    
print_result_2:
    # print "output = "
    la   a0, output_str
    ecall
    
    # print output
    addi a0, s4, 0
    li   a7, 1
    ecall
    
    # ", answer = "  
    la   a0, answer_str
    li   a7, 4
    ecall
    
    # load ans[0] to t3
    # print answer
    addi t2, s1, 8
    lw   a0, 0(t2)
    # reorder li and add
    li   a7, 1
    add  t2, a0, x0
    ecall
    
    # print "\n"
    la   a0, endline_str
    li   a7, 4
    ecall   
    
    # if (output == ans[2])
    beq  s4, t2, print_true_2
    # else 
    j    print_false_2
    
print_true_2:
    
    # print "True\n"
    la   a0, true_str
    ecall   


    j    main_exit
    
print_false_2:
    
    # print "False\n"
    la   a0, false_str
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


main_exit:
    li   a7, 10
    ecall
