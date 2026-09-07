; Integer square root using restoring bit-pair iteration.
; Input: AX unsigned radicand. Output: AX floor(sqrt(input)).
.MODEL SMALL
.CODE
isqrt16 PROC
    push bx
    push cx
    push dx
    xor bx, bx
    mov dx, 4000h
    mov cx, 8
sqrt_step:
    mov si, bx
    add si, dx
    cmp ax, si
    jb sqrt_skip
    sub ax, si
    shr bx, 1
    add bx, dx
    jmp sqrt_next
sqrt_skip:
    shr bx, 1
sqrt_next:
    shr dx, 2
    loop sqrt_step
    mov ax, bx
    pop dx
    pop cx
    pop bx
    ret
isqrt16 ENDP
END
