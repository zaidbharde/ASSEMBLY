; Overlap-safe byte copy, equivalent to a small memmove.
; Inputs: DS:SI source, ES:DI destination, CX byte count.
.MODEL SMALL
.CODE
memmove_bytes PROC
    cmp cx, 0
    je memmove_done
    mov ax, si
    cmp di, ax
    jb memmove_forward
    mov ax, si
    add ax, cx
    cmp di, ax
    jae memmove_forward
    add si, cx
    dec si
    add di, cx
    dec di
    std
    rep movsb
    cld
    ret
memmove_forward:
    cld
    rep movsb
memmove_done:
    ret
memmove_bytes ENDP
END
