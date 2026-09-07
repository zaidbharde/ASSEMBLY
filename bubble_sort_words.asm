; In-place ascending bubble sort for unsigned 16-bit values.
; Input: DS:SI array, CX element count.
.MODEL SMALL
.CODE
sort_words PROC
    cmp cx, 1
    jbe sort_done
    dec cx
sort_pass:
    push cx
    mov di, si
    mov bx, cx
sort_compare:
    mov ax, [di]
    cmp ax, [di+2]
    jbe sort_ordered
    xchg ax, [di+2]
    mov [di], ax
sort_ordered:
    add di, 2
    dec bx
    jnz sort_compare
    pop cx
    loop sort_pass
sort_done:
    ret
sort_words ENDP
END
