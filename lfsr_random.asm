; 16-bit maximal-length Fibonacci LFSR pseudo-random generator.
; Call lfsr_seed once, then lfsr_next for each value.
.MODEL SMALL
.DATA
lfsr_state DW 1
.CODE
lfsr_seed PROC
    or ax, ax
    jnz lfsr_seed_ok
    mov ax, 1
lfsr_seed_ok:
    mov lfsr_state, ax
    ret
lfsr_seed ENDP
lfsr_next PROC
    mov ax, lfsr_state
    mov dx, ax
    and dx, 1
    shr ax, 1
    or dx, dx
    jz lfsr_no_feedback
    xor ax, 0B400h
lfsr_no_feedback:
    mov lfsr_state, ax
    ret
lfsr_next ENDP
END
