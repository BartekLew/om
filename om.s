.text

.comm buffer, 1048576, 32

.globl _start

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
    movq %rdx, %r9 # input length

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

    subq $1, %rax # skip newline
    movq %rax, %r10 # pattern length
    xorq %rbx, %rbx # pattern cursor (relative)
    movq %r8, %rdi # input cursor (absolute)
    leaq (%r8, %r9), %r14 # end of input

    #would be logical to use r11, but
    #write syscall change it some way...
    #I'll use it to mark if pattern was found
    movq $1, %r11

.search:
    movb (%rdi, %rbx), %ah
    cmpb (%rsi, %rbx), %ah
    jne  .move_input

    incq %rbx
    cmpq %rbx, %r10
    je   .print_offset
    jmp  .search

.move_input:
    xorq %rbx, %rbx 
    incq %rdi
    leaq (%rdi, %r10), %rax
    cmpq %r14, %rax
    jge  .no_match
    jmp  .search

.no_match:
    movq %r11, %rax
    jmp .quit

.print_offset:
    movq %rdi, %r12 #remember input cursor
    movq %rsi, %r13 #remember pattern buffer
    subq $20, %rsp  #space for position as string
    movq %rsp, %rsi

    subq %r8, %rdi #match position
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
    xorq %r11, %r11    #mark that pattern was found
        
    addq $20,  %rsp  #free space for position as string
    movq %r12, %rdi  #recall input cursor
    addq %rdx, %rdi  #continue from the end of match
    movq %r13, %rsi  #recall pattern buffer
    xorq %rbx, %rbx  #pattern matching offset
    jmp .search      #continue search

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
