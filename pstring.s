/* 331666529 Nitay Chechik */
.section .rodata
invalid_input_str:     .string "invalid input!\n"
concat_err_str:        .string "cannot concatenate strings!\n"

.section .note.GNU-stack,"",@progbits

.text
.globl pstrlen
.type pstrlen, @function
pstrlen:
    pushq %rbp                  
    movq %rsp, %rbp
    
    # Get the length byte (first byte of Pstring)
    movzbq (%rdi), %rax         # Zero-extend byte to rax
    
    movq %rbp, %rsp             
    popq %rbp
    ret

.globl swapCase
.type swapCase, @function
swapCase:
    pushq %rbp                  
    movq %rsp, %rbp
    
    # Save the original Pstring pointer for return value
    movq %rdi, %rax
    
    # Get the length of the string
    movzbq (%rdi), %rcx         # Length in rcx
    testq %rcx, %rcx            # Check if length is 0
    jz swapCase_done            # If length 0, we're done
    
    # Point to the start of actual string data (after length byte)
    leaq 1(%rdi), %rdi
    
swapCase_loop:
    movb (%rdi), %dl            # Get current character
    
    # Check if uppercase (A-Z: 0x41-0x5A)
    cmpb $0x41, %dl
    jl swapCase_check_lower
    cmpb $0x5A, %dl
    jg swapCase_check_lower
    
    # It's uppercase, convert to lowercase by adding 32 (0x20)
    addb $0x20, %dl
    movb %dl, (%rdi)
    jmp swapCase_next
    
swapCase_check_lower:
    # Check if lowercase (a-z: 0x61-0x7A)
    cmpb $0x61, %dl
    jl swapCase_next
    cmpb $0x7A, %dl
    jg swapCase_next
    
    # It's lowercase, convert to uppercase by subtracting 32 (0x20)
    subb $0x20, %dl
    movb %dl, (%rdi)
    
swapCase_next:
    incq %rdi                   # Move to next character
    decq %rcx                   # Decrement counter
    jnz swapCase_loop           # Continue if not zero
    
swapCase_done:
    movq %rbp, %rsp             
    popq %rbp
    ret

.globl pstrijcpy
.type pstrijcpy, @function
pstrijcpy:
    pushq %rbp
    movq %rsp, %rbp
    
    # Save registers
    pushq %rbx
    pushq %r12
    pushq %r13
    pushq %r14
    
    # Save parameters: dst in %rbx, src in %r12, i in %r13, j in %r14
    movq %rdi, %rbx             # Save dst
    movq %rsi, %r12             # Save src
    movzbq %dl, %r13            # i
    movzbq %cl, %r14            # j
    
    # Check if j >= i
    cmpq %r13, %r14
    jl pstrijcpy_invalid
    
    # Check if i and j are within bounds for src
    movzbq (%r12), %rax         # src->len
    cmpq %rax, %r14
    jge pstrijcpy_invalid       # If j >= src->len, invalid
    
    # Check if i and j are within bounds for dst
    movzbq (%rbx), %rax         # dst->len
    cmpq %rax, %r14
    jge pstrijcpy_invalid       # If j >= dst->len, invalid
    
    # All checks passed, do the copy
    # Calculate starting addresses: src_start = &src->str[i], dst_start = &dst->str[i]
    leaq 1(%r12, %r13), %rsi    # src_start = &src->str[0] + i = &src + 1 + i
    leaq 1(%rbx, %r13), %rdi    # dst_start = &dst->str[0] + i = &dst + 1 + i
    
    # Calculate length to copy: j-i+1 (inclusive)
    movq %r14, %rcx
    subq %r13, %rcx
    incq %rcx                   # rcx = j-i+1
    
    # Copy bytes one by one
copy_loop:
    cmpq $0, %rcx               # Check if we've copied everything
    je copy_done
    
    movb (%rsi), %al            # Get byte from src
    movb %al, (%rdi)            # Store in dst
    
    incq %rsi                   # Move to next source byte
    incq %rdi                   # Move to next destination byte
    decq %rcx                   # Decrement counter
    jmp copy_loop
    
copy_done:
    # Return dst
    movq %rbx, %rax
    jmp pstrijcpy_done
    
pstrijcpy_invalid:
    # Print error message
    movq $invalid_input_str, %rdi
    xorq %rax, %rax
    call printf
    
    # Return dst unchanged
    movq %rbx, %rax
    
pstrijcpy_done:
    # Restore registers
    popq %r14
    popq %r13
    popq %r12
    popq %rbx
    
    movq %rbp, %rsp            
    popq %rbp
    ret

.globl pstrcmp
.type pstrcmp, @function
pstrcmp:
    pushq %rbp
    movq %rsp, %rbp
    
    # Save registers
    pushq %rbx
    pushq %r12
    
    # Save parameters: pstr1 in %rbx, pstr2 in %r12
    movq %rdi, %rbx
    movq %rsi, %r12
    
    # Point to the start of strings
    leaq 1(%rbx), %rbx
    leaq 1(%r12), %r12
    
pstrcmp_loop:
    movb (%rbx), %al            # Load char from pstr1
    movb (%r12), %cl            # Load char from pstr2
    
    # Check if we reached the end of pstr1 (null terminator)
    testb %al, %al
    jz pstrcmp_check_end
    
    # Check if we reached the end of pstr2
    testb %cl, %cl
    jz pstrcmp_pstr1_larger     # pstr1 continues but pstr2 ended -> pstr1 > pstr2
    
    # Compare characters
    cmpb %cl, %al
    jl pstrcmp_pstr1_smaller    # char1 < char2
    jg pstrcmp_pstr1_larger     # char1 > char2
    
    # Characters are equal, move to next
    incq %rbx
    incq %r12
    jmp pstrcmp_loop

pstrcmp_check_end:
    # pstr1 ended. Check if pstr2 also ended.
    testb %cl, %cl
    jnz pstrcmp_pstr1_smaller   # pstr1 ended but pstr2 continues -> pstr1 < pstr2
    
    # Both ended at the same time -> Equal
    movl $0, %eax
    jmp pstrcmp_done

pstrcmp_pstr1_smaller:
    movl $-1, %eax
    jmp pstrcmp_done

pstrcmp_pstr1_larger:
    movl $1, %eax
    jmp pstrcmp_done

pstrcmp_done:
    # Restore registers
    popq %r12
    popq %rbx
    
    movq %rbp, %rsp             
    popq %rbp
    ret

.globl pstrrev
.type pstrrev, @function
pstrrev:
    pushq %rbp                  
    movq %rsp, %rbp
    
    # Save return value
    movq %rdi, %rax
    
    # Get length
    movzbq (%rdi), %rcx
    testq %rcx, %rcx            # If length is 0, nothing to do
    jz pstrrev_done
    
    # Setup pointers:
    # %r8 points to start (first char)
    # %r9 points to end (last char)
    leaq 1(%rdi), %r8           # Start = &str[0]
    leaq 1(%rdi, %rcx), %r9     # End = &str[len-1]
    leaq (%rdi, %rcx), %r9      # End pointer
    
pstrrev_loop:
    # Check if pointers met or crossed (%r8 >= %r9)
    cmpq %r9, %r8
    jge pstrrev_done
    
    # Swap characters
    movb (%r8), %dl             # Load char from start
    movb (%r9), %cl             # Load char from end
    movb %cl, (%r8)             # Store end char at start
    movb %dl, (%r9)             # Store start char at end
    
    # Move pointers
    incq %r8                    # Move start forward
    decq %r9                    # Move end backward
    jmp pstrrev_loop
    
pstrrev_done:
    movq %rbp, %rsp             
    popq %rbp
    ret