; Saturating signed 16-bit addition.
; Input: AX = left operand, BX = right operand.
; Output: AX = sum clamped to -32768..32767, OF reflects raw overflow.
; Clobbers: flags only besides AX.
saturating_add_i16:
    add ax, bx
    jno .done
    js .negative_overflow
    mov ax, 7fffh
    ret
.negative_overflow:
    mov ax, 8000h
.done:
    ret
