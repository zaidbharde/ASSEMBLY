; Compute a Fletcher-16 checksum over bytes.
; Input: DS:SI = buffer, CX = length.
; Output: DX = (sum2 << 8) | sum1, both modulo 255.
; Clobbers: AX, BX, DI, flags.
fletcher16:
    xor ax, ax
    xor bx, bx
    jcxz .pack
.loop:
    xor ah, ah
    mov al, [si]
    inc si
    add bl, al
    cmp bl, 255
    jb .sum2
    sub bl, 255
.sum2:
    add bh, bl
    cmp bh, 255
    jb .next
    sub bh, 255
.next:
    loop .loop
.pack:
    mov dl, bh
    mov dh, bl
    ret
