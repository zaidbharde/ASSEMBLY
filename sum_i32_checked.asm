; x86-64 System V routine: sum signed 32-bit integers with overflow detection.
; Input: RDI = pointer, RSI = element count. Output: RAX = sign-extended sum.
; Carry flag is set when a signed overflow occurs.
section .text
global sum_i32_checked
sum_i32_checked:
    xor eax, eax
    xor ecx, ecx
.loop:
    cmp rcx, rsi
    jae .done
    movsxd rdx, dword [rdi + rcx * 4]
    add rax, rdx
    jo .overflow
    inc rcx
    jmp .loop
.done:
    clc
    ret
.overflow:
    stc
    ret
