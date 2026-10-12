; Find a byte in a bounded buffer.
; Input: DS:SI = buffer, CX = byte count, AL = target.
; Output: ZF=1 and SI points at the match, or ZF=0 when absent.
; Clobbers: CX, flags. Preserves AX except for flags.
find_byte_bounded:
    jcxz .not_found
    push ax
    cld
.scan:
    cmp [si], al
    je .found
    inc si
    loop .scan
.not_found:
    pop ax
    or cx, cx
    ret
.found:
    pop ax
    cmp al, al
    ret
