; Count set bits using Kernighan's clearing algorithm.
; The routine accepts RDI and returns the count in RAX.

section .data
    sample      dq 0xF0F0AA5500FF11CC
    count       dq 0

section .text
    global _start
    global popcount_word

popcount_word:
    xor eax, eax
.count:
    test rdi, rdi
    jz .done
    inc rax
    lea rdx, [rdi - 1]
    and rdi, rdx
    jmp .count
.done:
    ret

_start:
    mov rdi, [sample]
    call popcount_word
    mov [count], rax
    mov eax, 60
    xor edi, edi
    syscall
