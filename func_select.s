/* 331666529 Nitay Chechik */
.section .rodata
format_lengths:    .string "first pstring length: %d, second pstring length: %d\n"
format_pstring:    .string "length: %d, string: %s\n"
format_invalid:    .string "invalid option!\n"
cmp_small:           .string "First string is smaller\n"
cmp_equel:            .string "Strings are equal\n"
cmp_large:           .string "First string is larger\n"
scan_indexes:      .string "%d %d"

.section .note.GNU-stack,"",@progbits

.text
.globl run_func
.type run_func, @function
run_func:
    pushq %rbp                  
    movq %rsp, %rbp
    subq $16, %rsp              # Allocate space for local variables
    
    # Save callee-saved registers
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    
    # Save parameters: choice in %ebx, pstr1 in %r12, pstr2 in %r13
    movl %edi, %ebx
    movq %rsi, %r12
    movq %rdx, %r13
    
    # Switch based on choice
    cmpl $31, %ebx
    je case_31
    
    cmpl $33, %ebx
    je case_33
    
    cmpl $34, %ebx
    je case_34
    
    cmpl $41, %ebx
    je case_41
    
    cmpl $42, %ebx
    je case_42
    
    # Default case - invalid option
    movq $format_invalid, %rdi
    xorq %rax, %rax
    call printf
    jmp func_done
    
case_31:
    # pstrlen - print lengths of both strings
    movq %r12, %rdi
    call pstrlen
    movzbq %al, %rsi            # First length
    
    movq %r13, %rdi
    call pstrlen
    movzbq %al, %rdx            # Second length
    
    movq $format_lengths, %rdi
    xorq %rax, %rax
    call printf
    jmp func_done
    
case_33:
    # swapCase - swap case of both strings and print
    movq %r12, %rdi
    call swapCase
    
    # Print first string after swap
    movzbq (%r12), %rsi         # Length
    leaq 1(%r12), %rdx          # String pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    
    # Swap second string
    movq %r13, %rdi
    call swapCase
    
    # Print second string after swap
    movzbq (%r13), %rsi         # Length
    leaq 1(%r13), %rdx          # String pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    jmp func_done
    
case_34:
    # pstrijcpy - copy substring
    # First read i and j from user
    leaq -8(%rbp), %rsi         # &i
    leaq -4(%rbp), %rdx         # &j
    movq $scan_indexes, %rdi
    xorq %rax, %rax
    call scanf
    
    # Call pstrijcpy
    movq %r12, %rdi             # dst
    movq %r13, %rsi             # src
    movb -8(%rbp), %dl          # i
    movb -4(%rbp), %cl          # j
    call pstrijcpy
    
    # Print both strings
    movzbq (%r12), %rsi         # First length
    leaq 1(%r12), %rdx          # First string pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    
    movzbq (%r13), %rsi         # Second length
    leaq 1(%r13), %rdx          # Second string pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    jmp func_done
    
case_41:
    # pstrcmp - compare strings
    movq %r12, %rdi             # pstr1
    movq %r13, %rsi             # pstr2
    call pstrcmp
    
    # Check result
    cmpl $0, %eax
    jl case_41_smaller          # result < 0
    jg case_41_larger           # result > 0
    
    # Equal
    movq $cmp_equel, %rdi
    jmp case_41_print

case_41_smaller:
    movq $cmp_small, %rdi
    jmp case_41_print

case_41_larger:
    movq $cmp_large, %rdi

case_41_print:
    xorq %rax, %rax
    call printf
    jmp func_done

case_42:
    # pstrrev - reverse both strings
    # Reverse pstr1
    movq %r12, %rdi
    call pstrrev
    
    # Print pstr1
    movzbq (%r12), %rsi         # Length
    leaq 1(%r12), %rdx          # String pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    
    # Reverse pstr2
    movq %r13, %rdi
    call pstrrev
    
    # Print pstr2
    movzbq (%r13), %rsi         # Length
    leaq 1(%r13), %rdx          # String pointer
    movq $format_pstring, %rdi
    xorq %rax, %rax
    call printf
    jmp func_done
    
func_done:
    # Restore callee-saved registers
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    
    movq %rbp, %rsp             
    popq %rbp
    ret