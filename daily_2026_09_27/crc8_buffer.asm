; Compute CRC-8 with polynomial 0x07 over a byte buffer.
; The final checksum is returned in AL for callers.

section .data
    message      db 'assembly data'
    message_len  equ $ - message
    result       db 0

section .text
    global _start
    global crc8

crc8:
    xor eax, eax
.next_byte:
    test rsi, rsi
    jz .done
    xor al, [rdi]
    mov ecx, 8
.next_bit:
    shl al, 1
    jnc .no_feedback
    xor al, 0x07
.no_feedback:
    loop .next_bit
    inc rdi
    dec rsi
    jmp .next_byte
.done:
    ret

_start:
    lea rdi, [message]
    mov rsi, message_len
    call crc8
    mov [result], al
    mov eax, 60
    xor edi, edi
    syscall
