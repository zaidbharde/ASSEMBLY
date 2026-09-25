; Parse an unsigned hexadecimal string into RAX.
; Input: RSI points to bytes, RCX contains length.
; Output: RAX=value, CF=1 on invalid digit or overflow.
; Clobbers: RDX, R8, R9.

section .text
global hex_parse_u64
hex_parse_u64:
    xor     eax, eax
    xor     edx, edx
    test    rcx, rcx
    jz      .done
.loop:
    mov     r8b, [rsi]
    cmp     r8b, '0'
    jb      .invalid
    cmp     r8b, '9'
    jbe     .digit
    cmp     r8b, 'A'
    jb      .lower
    cmp     r8b, 'F'
    ja      .lower
    sub     r8b, 'A' - 10
    jmp     .have_digit
.lower:
    cmp     r8b, 'a'
    jb      .invalid
    cmp     r8b, 'f'
    ja      .invalid
    sub     r8b, 'a' - 10
    jmp     .have_digit
.digit:
    sub     r8b, '0'
.have_digit:
    movzx   r9, r8b
    shl     rax, 4
    jc      .invalid
    add     rax, r9
    jc      .invalid
    inc     rsi
    dec     rcx
    jnz     .loop
.done:
    clc
    ret
.invalid:
    stc
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
