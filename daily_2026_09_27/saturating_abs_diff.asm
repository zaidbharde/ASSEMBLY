; Compute |left - right| while saturating at the signed 64-bit maximum.
; The routine returns the result in RAX and preserves nonvolatile registers.

section .data
    left        dq 0x7FFFFFFFFFFFFFF0
    right       dq -32
    label_text  db 'absolute difference ready', 10

section .text
    global _start
    global saturated_abs_diff

saturated_abs_diff:
    mov rax, rdi
    sub rax, rsi
    jno .non_overflow
    mov rax, 0x7FFFFFFFFFFFFFFF
    ret
.non_overflow:
    mov rdx, rax
    sar rdx, 63
    xor rax, rdx
    sub rax, rdx
    ret

_start:
    mov rdi, [left]
    mov rsi, [right]
    call saturated_abs_diff
    mov eax, 1
    mov edi, 1
    lea rsi, [label_text]
    mov edx, 26
    syscall
    mov eax, 60
    xor edi, edi
    syscall
