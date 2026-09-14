; x86-64 System V routine: saturating unsigned 64-bit addition.
; Input: RDI = left operand, RSI = right operand. Output: RAX = sum or UINT64_MAX.
section .text
global saturating_add_u64
saturating_add_u64:
    mov rax, rdi
    add rax, rsi
    jnc .done
    mov rax, -1
.done:
    ret
