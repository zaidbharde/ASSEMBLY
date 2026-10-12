; Sort an array of unsigned 16-bit words in ascending order.
; Input: DS:SI = array, CX = number of words.
; Output: array sorted in place.
; Clobbers: AX, BX, DX, DI, flags.
insertion_sort_u16:
    cmp cx, 1
    jbe .done
    mov di, si
    add di, 2
    dec cx
.outer:
    mov ax, [di]
    mov bx, di
.inner:
    cmp bx, si
    je .place
    cmp [bx-2], ax
    jbe .place
    mov dx, [bx-2]
    mov [bx], dx
    sub bx, 2
    jmp .inner
.place:
    mov [bx], ax
    add di, 2
    loop .outer
.done:
    ret
