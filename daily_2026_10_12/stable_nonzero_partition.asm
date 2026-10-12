; Stable partition of a byte buffer by zero/nonzero value.
; Input: DS:SI = buffer, CX = length.
; Output: buffer begins with original nonzero bytes, then zero bytes.
; Clobbers: AX, BX, DX, DI, BP, flags.
stable_nonzero_partition:
    push si
    mov di, si
    xor bx, bx
    xor dx, dx
    jcxz .finish
.scan_nonzero:
    mov al, [si]
    inc si
    or al, al
    jz .skip_nonzero
    mov [di], al
    inc di
    inc bx
.skip_nonzero:
    loop .scan_nonzero
    mov bp, cx
    mov cx, bx
    add si, cx
    mov cx, bp
.finish:
    pop si
    ret
