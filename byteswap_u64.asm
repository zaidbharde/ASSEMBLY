; x86-64 System V routine: reverse the byte order of a 64-bit word.
; Input: RDI = value. Output: RAX = byte-swapped value.
section .text
global byteswap_u64
byteswap_u64:
    mov rax, rdi
    bswap rax
    ret

; Example: 0x1122334455667788 becomes 0x8877665544332211.
