; Reverse a byte sequence in place using the machine stack.
; Input: DS:SI buffer, CX length. Uses SS stack temporarily.
.MODEL SMALL
.CODE
reverse_bytes PROC
    push bx
    push cx
    push si
    mov bx, cx
    jcxz reverse_done
reverse_push:
    xor ah, ah
    mov al, [si]
    push ax
    inc si
    loop reverse_push
    mov cx, bx
    sub si, cx
reverse_pop:
    pop ax
    mov [si], al
    inc si
    loop reverse_pop
reverse_done:
    pop si
    pop cx
    pop bx
    ret
reverse_bytes ENDP
END
