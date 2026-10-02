; Encode a 32-bit unsigned integer as a compact little-endian varint.
; Inputs:  RDI = destination buffer, ESI = unsigned value
; Output: RAX = number of bytes written (1..5)
; Clobbers: RCX, RDX, R8D

global varint_encode_u32
section .text
varint_encode_u32:
    xor     eax, eax
    mov     ecx, esi
.next:
    mov     edx, ecx
    and     edx, 0x7f
    shr     ecx, 7
    test    ecx, ecx
    jz      .last
    or      edx, 0x80
    mov     [rdi + rax], dl
    inc     rax
    jmp     .next
.last:
    mov     [rdi + rax], dl
    inc     rax
    ret
