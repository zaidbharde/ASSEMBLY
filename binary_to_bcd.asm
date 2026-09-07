; Convert unsigned binary in AL to packed BCD (00..99).
; Input: AL in range 0..99. Output: AL packed BCD, CF if out of range.
.MODEL SMALL
.CODE
bin_to_packed_bcd PROC
    cmp al, 99
    ja bcd_range_error
    xor ah, ah
    mov dl, 10
    div dl
    shl al, 1
    shl al, 1
    shl al, 1
    shl al, 1
    or al, ah
    clc
    ret
bcd_range_error:
    stc
    ret
bin_to_packed_bcd ENDP
END
