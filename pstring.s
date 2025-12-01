/* 331666529 Nitay Chechik */
.section .rodata
invalid_input_str:     .string "invalid input!\n"
concat_err_str:        .string "cannot concatenate strings!\n"

.section .note.GNU-stack,"",@progbits

.text
.globl pstrlen
.type pstrlen, @function
pstrlen:
    pushq %rbp                  # Prologue
    movq %rsp, %rbp
    
    # Get the length byte (first byte of Pstring)
    movzbq (%rdi), %rax         # Zero-extend byte to rax
    
    movq %rbp, %rsp             # Epilogue
    popq %rbp
    ret

.globl swapCase
.type swapCase, @function
swapCase:
    pushq %rbp                  # Prologue
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
    movq %rbp, %rsp             # Epilogue
    popq %rbp
    ret

.globl pstrijcpy
.type pstrijcpy, @function
pstrijcpy:
    pushq %rbp                  # Prologue
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
    
    movq %rbp, %rsp             # Epilogue
    popq %rbp
    ret

.globl pstrcat
.type pstrcat, @function
pstrcat:
    pushq %rbp                  # Prologue
    movq %rsp, %rbp
    
    # Save registers
    pushq %rbx
    pushq %r12
    
    # Save parameters: dst in %rbx, src in %r12
    movq %rdi, %rbx             # Save dst
    movq %rsi, %r12             # Save src
    
    # Calculate total length
    movzbq (%rbx), %rcx         # dst->len in rcx
    movzbq (%r12), %rdx         # src->len in rdx
    movq %rcx, %rax             # Save original dst->len in rax
    addq %rdx, %rcx             # rcx = dst->len + src->len
    
    # Check if total length <= 254
    cmpq $254, %rcx
    jg pstrcat_error
    
    # Update the length byte of dst
    movb %cl, (%rbx)
    
    # Calculate where to append: dst_start = &dst->str[dst->len]
    leaq 1(%rbx, %rax), %rdi    # dst_start = &dst + 1 + dst->len
    
    # Calculate src start: src_start = &src->str[0]
    leaq 1(%r12), %rsi          # src_start = &src + 1
    
    # Set up for copy loop
    movq %rdx, %rcx             # Number of bytes to copy = src->len
    
copy_cat_loop:
    cmpq $0, %rcx               # Check if we've copied everything
    je copy_cat_done
    
    movb (%rsi), %al            # Get byte from src
    movb %al, (%rdi)            # Store in dst
    
    incq %rsi                   # Move to next source byte
    incq %rdi                   # Move to next destination byte
    decq %rcx                   # Decrement counter
    jmp copy_cat_loop
    
copy_cat_done:
    # Return dst
    movq %rbx, %rax
    jmp pstrcat_done
    
pstrcat_error:
    # Print error message
    movq $concat_err_str, %rdi
    xorq %rax, %rax
    call printf
    
    # Return dst unchanged
    movq %rbx, %rax
    
pstrcat_done:
    # Restore registers
    popq %r12
    popq %rbx
    
    movq %rbp, %rsp             # Epilogue
    popq %rbp
    ret