.text

.comm buffer, 1048576, 32
.comm cmd_buff, 255, 32

.globl _start
.extern substr
.extern int_to_str

_start:
    popq %rcx
    cmpq $2, %rcx   #one argument
    jne  .usage

    open ro   8(%rsp) .usage
    stat %rax $buffer .usage

    movq 48(%rsi), %rdx #get open file size
    cmpq $1048576, %rdx #check max file size
    jg   .too_big_file

    read %rdi %rsi %rdx .io_error

    leaq (%rsi, %rax), %r8 # end of input

    close %rdi

    read+ $0 $cmd_buff $255 .io_error

.in_to_cmd:
    movq %rsi,         %rdi #stdin buffer
    leaq (%rdi, %rax), %r9  #end of stdin buffer
    movq $.nlstr,      %rsi #pattern to look for
    movq $1,           %r10 #pattern length
    xorq %rax,         %rax #start from beginning
    
    movq $.have_patten, %r12   #on success
    movq $.patt_too_long, %r13 #on fail
    jmp  substr

.patt_too_long:
    quit 2

.no_patt:
    quit 1

.nlstr: .ascii "\n"

.have_patten:
    test %rax, %rax
    jz   .no_patt

    movq %rdi,    %r14 # where current pattern start
    movq %r9,     %r15 # where all patterns loaded end
    movq %rax,    %r10 # where this pattern end
    movq %r8,     %r9
    movq %rdi,    %rsi
    movq $buffer, %rdi  # input buffer
    xorq %rax, %rax # start from beginning

    movq $.print_offset, %r12
    movq $.no_match, %r13
    jmp  substr

.no_match:
    quit 1

.print_offset:
    movq %rax, %r13 #remember match position

    movq %rax,      %rdi #match position
    subq $21,       %rsp  #space for position as string
    movq %rsp,      %rsi
    movq $.println, %r12
    jmp  int_to_str

.println:
    movq $0xa, (%rsi, %rbx)
    incq %rbx

    write? $1 %rsi %rbx
        
    addq $21,  %rsp       #free space for position as string
    movq $buffer,  %rdi   #recall input buffer
    movq %r13, %rax       #recall match position
    addq %rdx, %rax       #continue from the end of match
    movq %r14, %rsi       #recall pattern buffer

    #set actions
    movq $.print_offset, %r12
    movq $.match_fin, %r13
    jmp substr      #continue search

.match_fin:
    addq $1,        %r10  #where next pattern could start
    addq %r10,      %rsi
    movq %r15,      %rax
    subq %rsi,      %rax
    jnz  .in_to_cmd

    read+ $0 $cmd_buff $255 .job_done
    jmp  .in_to_cmd

.job_done:
    quit 0

usage_msg:
    .ascii "USAGE: om file_name\n"
io_error_msg:
    .ascii "om: i/o error\n"
tbf_msg:
    .ascii "om: too big file (max=1048576)\n"

.usage:
    write? $1 $usage_msg $20
    quit   1

.io_error:
    write? $2 $io_error_msg $14
    quit   2

.too_big_file:
    movq $tbf_msg, %rsi
    movq $31, %rdx
