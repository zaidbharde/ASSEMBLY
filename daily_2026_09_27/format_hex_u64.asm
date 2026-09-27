; Format an unsigned 64-bit value as sixteen hexadecimal digits.
; Linux x86-64 NASM syntax; writes the result to stdout.

section .data
    value       dq 0x0123456789ABCDEF
    digits      db '0123456789ABCDEF'
    newline     db 10

section .bss
    output      resb 16

section .text
    global _start

_start:
    mov rax, [value]
    lea rdi, [output + 15]
    mov rcx, 16
.format_loop:
    mov rdx, rax
    and rdx, 0xF
    mov dl, [digits + rdx]
    mov [rdi], dl
    shr rax, 4
    dec rdi
    loop .format_loop

    mov eax, 1
    mov edi, 1
    lea rsi, [output]
    mov edx, 16
    syscall
    mov eax, 1
    mov edi, 1
    lea rsi, [newline]
    mov edx, 1
    syscall
    mov eax, 60
    xor edi, edi
    syscall
