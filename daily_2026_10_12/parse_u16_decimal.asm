; Parse an unsigned decimal string into AX.
; Input: DS:SI = text, CX = length.
; Output: AX = value; CF=1 for invalid input or overflow.
; Clobbers: BX, DX, flags.
parse_u16_decimal:
    xor ax, ax
    xor bx, bx
    jcxz .success
.next:
    mov bl, [si]
    inc si
    cmp bl, '0'
    jb .error
    cmp bl, '9'
    ja .error
    sub bl, '0'
    mov dx, 10
    mul dx
    or dx, dx
    jnz .error
    add ax, bx
    jc .error
    loop .next
.success:
    clc
    ret
.error:
    stc
    ret
