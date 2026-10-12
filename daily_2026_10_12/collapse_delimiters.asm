; Collapse repeated delimiter bytes in place.
; Input: DS:SI = buffer, CX = length, AL = delimiter.
; Output: CX = new length, SI restored to buffer start.
; Clobbers: AX, BX, DX, DI, flags.
collapse_delimiters:
    push si
    mov di, si
    xor bx, bx
    xor dx, dx
    jcxz .done
.next:
    mov dl, [si]
    inc si
    cmp dl, al
    jne .keep
    cmp bx, 0
    je .keep
    dec cx
    loop .next
    jmp .done
.keep:
    mov [di], dl
    inc di
    inc bx
    loop .next
.done:
    mov cx, bx
    pop si
    ret
