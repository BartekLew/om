.text

.comm buffer, 1048576, 32

.globl _start
.extern substr

_start:
    popq %rcx
    cmpq $2, %rcx   #one argument
    jne  .usage

    addq $8, %rsp   #forget argv[0]

    movq $2, %rax   #open
    popq %rdi       #file name
    xorq %rsi, %rsi #ro
    xorq %rdx, %rdx #mode
    syscall

    cmp $2, %rax
    jng .usage

    movq %rax, %r10 #file descriptor for read
    movq $buffer, %rsi #buffer for r/w, stat

    movq %rax, %rdi #file descriptor
    movq $5, %rax   #fstat
    syscall

    test %rax, %rax
    jnz  .usage

    movq 48(%rsi), %rdx #get open file size
    cmpq $1048576, %rdx #check max file size
    jg   .too_big_file

    movq $0, %rax #read
    movq %r10, %rdi #file descritor
    syscall

    cmpq $0, %rax
    jl .io_error

    movq %rsi, %r8 # input buffer
    leaq (%r8, %rax), %r9 # end of input


    movq $3, %rax # close input
    syscall

    movq $buffer, %rsi
    addq %rdx, %rsi # place for pattern line

    xorq %rax, %rax # read
    movq $127, %rdx # buffer size
    xorq %rdi, %rdi # stdin
    syscall

    cmpq $0, %rax
    jle .io_error

    subq $1, %rax   # skip newline
    movq %rax, %r10 # pattern length
    movq %r8, %rdi  # input buffer
    xorq %rax, %rax # start from beginning

    movq $.print_offset, %r12
    movq $.no_match, %r13
    jmp  substr

.no_match:
    movq $1, %rax
    jmp .quit

.print_offset:
    movq %rax, %r12 #remember match position
    movq %rsi, %r13 #remember pattern buffer
    subq $20, %rsp  #space for position as string
    movq %rsp, %rsi

    movq %rax, %rdi #match position
    movq $10, %rcx
    movq $10, %rax

.pos_digits:
    cmpq %rdi, %rax
    jge   .store_digits
    mulq %rcx
    jmp .pos_digits


.store_digits:
    xorq %rdx, %rdx
    divq %rcx
    movq %rax, %rcx # divisor
    movq %rdi, %rax # match position
    xorq %rbx, %rbx
    movq $10, %r15

.sd_loop:
    xorq %rdx, %rdx
    divq %rcx
    addq $0x30, %rax
    movq %rax, (%rsi, %rbx)
    subq $0x30, %rax
    incq %rbx
    cmpq $1, %rcx
    je   .println
    movq %rcx, %rax
    movq %rdx, %rcx
    xorq %rdx, %rdx
    divq %r15
    movq %rcx, %rdx
    movq %rax, %rcx
    movq %rdx, %rax
    jmp  .sd_loop
    
.println:
    movq $0xa, (%rsi, %rbx)
    incq %rbx
    movq $1, %rax
    movq $1, %rdi
    movq %rbx, %rdx
    syscall
        
    addq $20,  %rsp  #free space for position as string
    movq %r8,  %rdi  #recall input buffer
    movq %r12, %rax  #recall match position
    addq %rdx, %rax  #continue from the end of match
    movq %r13, %rsi  #recall pattern buffer

    #set actions
    movq $.print_offset, %r12
    movq $.match_fin, %r13
    jmp substr      #continue search

.match_fin:
    xorq %rax, %rax
    jmp  .quit

usage_msg:
    .ascii "USAGE: om file_name\n"
io_error_msg:
    .ascii "om: i/o error\n"
tbf_msg:
    .ascii "om: too big file (max=1048576)\n"

.usage:
    movq $1, %rax #write
    movq $1, %rdi #stdout
    movq $usage_msg, %rsi
    movq $20, %rdx
    syscall

    movq $1, %rax
    jmp  .quit

.io_error:
    movq $io_error_msg, %rsi
    movq $14, %rdx
    jmp .print_error

.too_big_file:
    movq $tbf_msg, %rsi
    movq $31, %rdx

.print_error:
    movq $1, %rax
    movq $2, %rdi #stderr
    syscall

    movq $2, %rax

.quit:
    movq %rax, %rdi #exit code for quit
    movq $60, %rax #quit
    syscall
