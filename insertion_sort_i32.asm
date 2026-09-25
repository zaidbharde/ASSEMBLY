; Stable in-place insertion sort for signed int32 values.
; Input: RDI=array pointer, RSI=element count.
; Preserves the order of equal values.

section .text
global insertion_sort_i32
insertion_sort_i32:
    cmp     rsi, 1
    jbe     .done
    mov     rcx, 1
.outer:
    mov     eax, [rdi + rcx * 4]
    mov     rdx, rcx
.inner:
    test    rdx, rdx
    jz      .insert
    mov     r8d, [rdi + rdx * 4 - 4]
    cmp     r8d, eax
    jle     .insert
    mov     [rdi + rdx * 4], r8d
    dec     rdx
    jmp     .inner
.insert:
    mov     [rdi + rdx * 4], eax
    inc     rcx
    cmp     rcx, rsi
    jb      .outer
.done:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
