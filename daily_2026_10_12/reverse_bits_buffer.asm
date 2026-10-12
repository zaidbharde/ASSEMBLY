; Reverse the bit order of every byte in a buffer.
; Input: DS:SI = buffer, CX = number of bytes.
; Output: transformed buffer in place.
; Clobbers: AX, BX, DX, flags.
reverse_bits_buffer:
    jcxz .done
.byte_loop:
    mov al, [si]
    xor bx, bx
    mov dx, 8
.bit_loop:
    shl al, 1
    rcr bl, 1
    dec dx
    jnz .bit_loop
    mov [si], bl
    inc si
    loop .byte_loop
.done:
    ret
