.globl substr
.globl get_stdin

# TODO what if rdi+rax=r9 or r10=0 ??


# search for substring
# input:  rdi = text to match
#         rax = search start position
#         r9  = text end
#         rsi = pattern to be found
#         r10 = pattern length
#         r12 = success action
#         r13 = fail action
# output: rax = substring position
#         rcx = number of bytes matched
#         dl  = last matched byte value  
# if no match, output undefined

substr:
    xorq %rcx, %rcx # pattern cursor (relative)
    addq %rdi, %rax

substr_loop:
    movb (%rax, %rcx), %dl
    cmpb (%rsi, %rcx), %dl
    jne  .move_input

    incq %rcx
    cmpq %rcx, %r10
    jne  substr_loop
    subq %rdi, %rax
    jmpq *%r12

.move_input:
    xorq %rcx, %rcx 
    incq %rax
    leaq (%rax, %r10), %rdx
    cmpq %r9, %rdx
    jle  substr_loop
    jmpq  *%r13

#function substr end

# get text portion from stdion
# input:  r12 = success action
#         r13 = failure action
# output: rax = bytes read
#         rdx = buffer size
#         rsi = buffer address
#         rdi = 0
get_stdin:
    xorq %rax,      %rax # read
    xorq %rdi,      %rdi # stdin
    syscall

    cmpq $0, %rax
    jle .no_stdin
    
    jmpq *%r12

.no_stdin:
    jmpq *%r13
