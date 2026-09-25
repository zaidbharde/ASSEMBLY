; Encode adjacent equal bytes as (count, byte) pairs.
; Input: RSI=source, RDI=destination, RCX=source length.
; Output: RAX=encoded length. Count is capped at 255.

section .text
global rle_encode_bytes
rle_encode_bytes:
    xor     eax, eax
    test    rcx, rcx
    jz      .finish
.next_run:
    mov     dl, [rsi]
    xor     r8d, r8d
.count:
    cmp     r8b, 255
    je      .emit
    cmp     rcx, 0
    je      .emit
    cmp     [rsi], dl
    jne     .emit
    inc     r8b
    inc     rsi
    dec     rcx
    jmp     .count
.emit:
    mov     [rdi], r8b
    mov     [rdi + 1], dl
    add     rdi, 2
    add     rax, 2
    test    rcx, rcx
    jnz     .next_run
.finish:
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
