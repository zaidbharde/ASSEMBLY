; Saturating signed multiplication for two's-complement int64 values.
; Input: RDI=a, RSI=b. Output: RAX=clamped product.
; Uses signed multiply and checks the high half against the sign extension.

section .text
global saturating_mul_i64
saturating_mul_i64:
    mov     rax, rdi
    imul    rsi
    mov     rcx, rax
    sar     rcx, 63
    cmp     rdx, rcx
    je      .exact
    test    rdi, rdi
    jns     .positive_limit
    mov     rax, 0x8000000000000000
    ret
.positive_limit:
    mov     rax, 0x7fffffffffffffff
    ret
.exact:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
