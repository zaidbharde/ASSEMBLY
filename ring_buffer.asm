; Byte ring-buffer primitives for producer/consumer queues.
; Queue state: head, tail, and count are word-sized.
.MODEL SMALL
.DATA
ring_data DB 64 DUP(0)
ring_head DW 0
ring_tail DW 0
ring_count DW 0
.CODE
ring_reset PROC
    mov ring_head, 0
    mov ring_tail, 0
    mov ring_count, 0
    ret
ring_reset ENDP
ring_push PROC
    cmp ring_count, 64
    jae ring_full
    mov bx, ring_tail
    mov ring_data[bx], al
    inc bx
    cmp bx, 64
    jb ring_store_tail
    xor bx, bx
ring_store_tail:
    mov ring_tail, bx
    inc ring_count
    clc
    ret
ring_full:
    stc
    ret
ring_push ENDP
ring_pop PROC
    cmp ring_count, 0
    je ring_empty
    mov bx, ring_head
    mov al, ring_data[bx]
    inc bx
    cmp bx, 64
    jb ring_store_head
    xor bx, bx
ring_store_head:
    mov ring_head, bx
    dec ring_count
    clc
    ret
ring_empty:
    stc
    ret
ring_pop ENDP
END
