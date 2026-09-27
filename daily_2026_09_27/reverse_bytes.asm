; Reverse a mutable byte sequence in place.
; RDI points to the first byte and RSI contains the length.

section .data
    buffer      db 'reverse me safely'
    buffer_len  equ $ - buffer
    newline     db 10

section .text
    global _start
    global reverse_bytes

reverse_bytes:
    test rsi, rsi
    jz .done
    lea rdx, [rdi + rsi - 1]
.swap:
    cmp rdi, rdx
    jae .done
    mov al, [rdi]
    xchg al, [rdx]
    mov [rdi], al
    inc rdi
    dec rdx
    jmp .swap
.done:
    ret

_start:
    lea rdi, [buffer]
    mov rsi, buffer_len
    call reverse_bytes
    mov eax, 1
    mov edi, 1
    lea rsi, [buffer]
    mov edx, buffer_len
    syscall
    mov eax, 1
    mov edi, 1
    lea rsi, [newline]
    mov edx, 1
    syscall
    mov eax, 60
    xor edi, edi
    syscall
