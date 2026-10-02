; Find the first set bit at or after a requested bit index.
; Inputs: RDI = pointer to little-endian qword bitmap
;         RSI = number of qwords in bitmap
;         RDX = starting bit index
; Output: RAX = bit index, or -1 when no bit is set
; Clobbers: RCX, R8, R9, R10

global bitset_next_set
section .text
bitset_next_set:
    mov     rax, -1
    test    rsi, rsi
    jz      .done
    mov     rcx, rdx
    shr     rcx, 6
    cmp     rcx, rsi
    jae     .done
    mov     r8, rdx
    and     r8, 63
    mov     r9, [rdi + rcx * 8]
    mov     r10, rcx
    mov     ecx, r8d
    mov     rax, 1
    shl     rax, cl
    mov     rcx, r10
    dec     rax
    not     rax
    and     r9, rax
.scan:
    test    r9, r9
    jnz     .found
    inc     rcx
    cmp     rcx, rsi
    jae     .done
    mov     r9, [rdi + rcx * 8]
    jmp     .scan
.found:
    bsf     r8, r9
    lea     rax, [rcx * 64 + r8]
.done:
    ret
