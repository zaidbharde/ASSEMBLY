; x86-64 System V routine: count set bits in an unsigned 64-bit value.
; Input: RDI = value. Output: RAX = population count.

section .text
global popcount_u64

popcount_u64:
    xor eax, eax
    mov rcx, rdi

.count_loop:
    test rcx, rcx
    jz .finished
    mov rdx, rcx
    dec rdx
    and rcx, rdx
    inc eax
    jmp .count_loop

.finished:
    ret
