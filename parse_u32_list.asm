; Parse a comma-separated list of unsigned decimal values.
; Input: RSI=text, RCX=length, RDI=output uint32 array, R8=max items.
; Output: RAX=item count, CF=1 for malformed input or overflow.

section .text
global parse_u32_list
parse_u32_list:
    xor     eax, eax
    xor     r9d, r9d
    test    rcx, rcx
    jz      .finish
.value:
    cmp     r9, r8
    jae     .invalid
    xor     edx, edx
    xor     r10d, r10d
.digit:
    test    rcx, rcx
    jz      .store
    mov     r11b, [rsi]
    cmp     r11b, '0'
    jb      .separator
    cmp     r11b, '9'
    ja      .invalid
    imul    edx, edx, 10
    jc      .invalid
    movzx   r11d, r11b
    sub     r11d, '0'
    add     edx, r11d
    jc      .invalid
    inc     r10d
    inc     rsi
    dec     rcx
    jmp     .digit
.separator:
    test    r10d, r10d
    jz      .invalid
    cmp     r11b, ','
    jne     .invalid
    inc     rsi
    dec     rcx
.store:
    test    r10d, r10d
    jz      .invalid
    mov     [rdi + r9 * 4], edx
    inc     r9
    inc     rax
    test    rcx, rcx
    jnz     .value
.finish:
    clc
    ret
.invalid:
    stc
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
