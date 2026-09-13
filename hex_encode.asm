; x86-64 System V routine: encode bytes as lowercase hexadecimal.
; Input: RDI = source pointer, RSI = byte count, RDX = destination pointer.
; Output: RAX = number of bytes written, or zero for an invalid destination.

section .text
global encode_hex

encode_hex:
    test rdx, rdx
    jz .invalid
    xor rcx, rcx
    lea r8, [rel hex_digits]

.next_byte:
    cmp rcx, rsi
    jae .done
    movzx rax, byte [rdi + rcx]
    mov r9, rax
    shr r9, 4
    mov r9b, [r8 + r9]
    mov [rdx + rcx * 2], r9b
    and al, 0x0f
    mov al, [r8 + rax]
    mov [rdx + rcx * 2 + 1], al
    inc rcx
    jmp .next_byte

.done:
    lea rax, [rcx * 2]
    ret

.invalid:
    xor eax, eax
    ret

section .rodata
hex_digits db '0123456789abcdef'
