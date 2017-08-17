.text

.globl _start

_start:
    movq %rsp, %rsi #buffer for r/w, stat

.rw:
    movq $0, %rax #read
    movq $0, %rdi #stdin
    movq $81, %rdx #buffer size
    syscall

    cmpq $0, %rax
    jna .quit

    movq %rax, %rdx # length
    movq $1, %rax # write
    movq $1, %rdi # stdout
    syscall

    jmp .rw

.quit:
    movq %rax, %rdi #exit code for quit
    movq $60, %rax #quit
    syscall
