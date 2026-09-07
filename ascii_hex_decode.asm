; Decode one ASCII hexadecimal character into a nibble.
; Input: AL = 0-9, A-F, or a-f. Output: AL nibble, CF on error.
.MODEL SMALL
.CODE
hex_char_value PROC
    cmp al, '0'
    jb hex_error
    cmp al, '9'
    jbe hex_digit
    cmp al, 'A'
    jb hex_lower_check
    cmp al, 'F'
    jbe hex_upper
hex_lower_check:
    cmp al, 'a'
    jb hex_error
    cmp al, 'f'
    ja hex_error
    sub al, 'a' - 10
    clc
    ret
hex_upper:
    sub al, 'A' - 10
    clc
    ret
hex_digit:
    sub al, '0'
    clc
    ret
hex_error:
    xor al, al
    stc
    ret
hex_char_value ENDP
END
