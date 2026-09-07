; Convert packed BCD in AL to binary, rejecting invalid nibbles.
; Input: AL = two decimal digits, e.g. 42h.
; Output: AL = binary value; CF set if either digit exceeds nine.
.MODEL SMALL
.CODE
packed_bcd_to_bin PROC
    push bx
    mov ah, al
    and al, 0Fh
    mov dl, al
    cmp dl, 9
    ja bcd_invalid
    and ah, 0F0h
    mov bl, 16
    shr ah, 1
    shr ah, 1
    shr ah, 1
    shr ah, 1
    cmp ah, 9
    ja bcd_invalid
    mov bh, ah
    mov al, bh
    mov bl, 10
    mul bl
    add al, dl
    clc
    pop bx
    ret
bcd_invalid:
    stc
    pop bx
    ret
packed_bcd_to_bin ENDP
END
