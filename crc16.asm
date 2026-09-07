; CRC-16/IBM update routine for a byte stream.
; Input: DS:SI buffer, CX byte count, DX initial CRC.
; Output: AX final CRC; preserves SI and CX.
.MODEL SMALL
.CODE
crc16_update PROC
    push bx
    push cx
    push si
    mov ax, dx
    jcxz crc_done
crc_byte:
    xor al, [si]
    inc si
    mov bl, 8
crc_bit:
    shr ax, 1
    jnc crc_no_poly
    xor ax, 0A001h
crc_no_poly:
    dec bl
    jnz crc_bit
    loop crc_byte
crc_done:
    pop si
    pop cx
    pop bx
    ret
crc16_update ENDP
END
