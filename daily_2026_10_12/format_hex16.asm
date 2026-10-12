; Format AX as four uppercase hexadecimal characters.
; Input: AX = value, DS:DI = destination buffer of at least 4 bytes.
; Output: four ASCII digits at [DI..DI+3].
; Clobbers: AX, BX, CX, DX, flags.
format_hex16:
    mov bx, ax
    mov cx, 4
.next_digit:
    rol bx, 4
    mov dl, bl
    and dl, 0fh
    cmp dl, 10
    jb .numeric
    add dl, 'A' - 10
    jmp .store
.numeric:
    add dl, '0'
.store:
    mov [di], dl
    inc di
    loop .next_digit
    ret
