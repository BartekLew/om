.text

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
    movq %rsp, %rsi #buffer for r/w, stat

    movq %rax, %rdi #file descriptor
    movq $5, %rax   #fstat
    syscall

    test %rax, %rax
    jnz  .usage

    movq 48(%rsi), %rdx #get open file size

#TODO: This implementation is vulnerable to stack overflow

    movq $0, %rax #read
    movq %r10, %rdi #file descritor
    syscall

    cmpq $0, %rax
    jl .io_error

    movq %rax, %rdx # length
    movq $1, %rax # write
    movq $1, %rdi # stdout
    syscall

    jmp .quit

usage_msg:
    .ascii "USAGE: om file_name\n"
io_error_msg:
    .ascii "om: io/error\n"

.usage:
    movq $1, %rax #write
    movq $1, %rdi #stdout
    movq $usage_msg, %rsi
    movq $20, %rdx
    syscall

    movq $1, %rax
    jmp  .quit

.io_error:
    movq $1, %rax
    movq $2, %rdi #stderr
    movq $io_error_msg, %rsi
    movq $12, %rdx
    syscall

    movq $2, %rax

.quit:
    movq %rax, %rdi #exit code for quit
    movq $60, %rax #quit
    syscall
