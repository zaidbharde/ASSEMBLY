; Count low and high hexadecimal nibbles in a byte buffer.
; Input: DS:SI = bytes, CX = length, ES:DI = 16-word zeroed histogram.
; Output: histogram[n] incremented for every nibble value 0..15.
; Clobbers: AX, BX, DX, flags.
nibble_histogram:
    jcxz .done
.next_byte:
    mov al, [si]
    inc si
    mov bl, al
    and bx, 000fh
    shl bx, 1
    inc word [es:di+bx]
    mov bl, al
    mov bh, 0
    shr bx, 4
    shl bx, 1
    inc word [es:di+bx]
    loop .next_byte
.done:
    ret
