;================================================================
;  ZAID VM - Custom Interpreted Language for 8086
;  Assembler: TASM
;  Mode: DOS Real Mode (.COM or .EXE)
;  
;  Commands Supported:
;    set <var> <number>
;    add <var1> and <var2> = <dest>
;    sub <var1> and <var2> = <dest>
;    mul <var1> and <var2> = <dest>
;    div <var1> and <var2> = <dest>
;    print <var>
;    exit
;
;  Build:  tasm zaidvm.asm
;          tlink zaidvm.obj
;          zaidvm.exe
;================================================================

.MODEL SMALL
.STACK 256

;================================================================
;                      CONSTANTS
;================================================================
TOKEN_SIZE      EQU 32
MAX_TOKENS      EQU 10
LINE_SIZE       EQU 256
VAR_NAME_SIZE   EQU 16
VAR_ENTRY_SIZE  EQU 18          ; 16 bytes name + 2 bytes value
MAX_VARS        EQU 26

;================================================================
;                      DATA SEGMENT
;================================================================
.DATA
    exit_flag DB 0
    ;=== INPUT BUFFERS ===
    input_buffer    DB LINE_SIZE DUP(0)
    line_buffer     DB LINE_SIZE DUP(0)
    
    ;=== TOKEN BUFFER ===
    ; 10 tokens × 32 bytes = 320 bytes
    token_buffer    DB TOKEN_SIZE * MAX_TOKENS DUP(0)
    token_count     DW 0
    
    ;=== VARIABLE TABLE ===
    ; 26 entries × 18 bytes = 468 bytes
    ; Each entry: [name: 16 bytes][value: 2 bytes]
    var_table       DB MAX_VARS * VAR_ENTRY_SIZE DUP(0)
    var_count       DW 0
    
    ;=== COMMAND KEYWORDS ===
cmd_set         DB 'set', 0
cmd_add         DB 'add', 0
cmd_sub         DB 'sub', 0
cmd_mul         DB 'mul', 0
cmd_div         DB 'div', 0
cmd_print       DB 'print', 0
cmd_print_str   DB 'print_str', 0   ; <<< yahin add karo
cmd_exit        DB 'exit', 0
cmd_debug       DB 'debug', 0
kw_and          DB 'and', 0
kw_equals       DB '=', 0

    
    ;=== MESSAGES ===
    msg_welcome     DB '========================================', 13, 10
                    DB '         ZAID VM - Version 1.0          ', 13, 10
                    DB '   Custom Language Interpreter (8086)   ', 13, 10
                    DB '========================================', 13, 10
                    DB 'Commands: set, add, sub, mul, div, print, exit', 13, 10
                    DB 13, 10, '$'
    
    msg_prompt      DB 'ZAID> ', '$'
    msg_ok          DB 'OK', 13, 10, '$'
    msg_bye         DB 'Goodbye!', 13, 10, '$'
    msg_invalid     DB 'Error: Invalid command', 13, 10, '$'
    msg_syntax      DB 'Error: Syntax error', 13, 10, '$'
    msg_undefined   DB 'Error: Undefined variable', 13, 10, '$'
    msg_divzero     DB 'Error: Division by zero', 13, 10, '$'
    msg_overflow    DB 'Error: Variable table full', 13, 10, '$'
    msg_newline     DB 13, 10, '$'
    
    ;=== DEBUG MESSAGES ===
    msg_dbg_header  DB '--- DEBUG: Tokens ---', 13, 10, '$'
    msg_dbg_count   DB 'Token count: ', '$'
    msg_dbg_token   DB 'Token[', '$'
    msg_dbg_end     DB ']: |', '$'
    msg_dbg_pipe    DB '|', 13, 10, '$'
    msg_dbg_hex     DB ' (Hex: ', '$'
    msg_dbg_paren   DB ')', 13, 10, '$'
    msg_dbg_vars    DB '--- DEBUG: Variables ---', 13, 10, '$'

;================================================================
;                      CODE SEGMENT
;================================================================
.CODE

;================================================================
; MAIN - Entry Point
;================================================================
main PROC
    ; Initialize data segment
    mov ax, @data
    mov ds, ax
    mov es, ax
    cld                             ; Clear direction flag
    
    ; Display welcome message
    lea dx, msg_welcome
    mov ah, 09h
    int 21h
    
main_loop:
    ; Display prompt
    lea dx, msg_prompt
    mov ah, 09h
    int 21h
    
    ; Read line from keyboard
    call read_line
    
    ; Check for empty line
    lea si, line_buffer
    cmp BYTE PTR [si], 0
    je main_loop                    ; Skip empty lines
    
    ; Tokenize the input
    call tokenize
    
    ; Check if any tokens found
    cmp WORD PTR [token_count], 0
    je main_loop
    
    ; Parse and execute
    call parse_execute
    
    ; Check for exit flag
    cmp BYTE PTR [exit_flag], 1
    je exit_program
    
    jmp main_loop
    
exit_program:
    lea dx, msg_bye
    mov ah, 09h
    int 21h
    
    mov ah, 4Ch
    xor al, al
    int 21h
main ENDP

;================================================================
; Exit flag (in code segment for simplicity, move to data if needed)
;================================================================
;exit_flag DB 0

;================================================================
; READ_LINE - Read a line from keyboard, clean CR/LF
; Output: line_buffer contains clean null-terminated string
;================================================================
read_line PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Clear line buffer first
    lea di, line_buffer
    mov cx, LINE_SIZE
    xor al, al
    rep stosb
    
    ; Use DOS buffered input
    lea dx, input_buffer
    mov BYTE PTR [input_buffer], LINE_SIZE - 2  ; Max chars
    mov ah, 0Ah
    int 21h
    
    ; Print newline after input
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    
    ; Copy to line_buffer, removing CR/LF
    lea si, input_buffer + 2        ; Actual string starts at offset 2
    lea di, line_buffer
xor cx, cx
mov cl, [input_buffer + 1]

    
    ; If length is 0, we're done
    cmp cx, 0
    je read_done
    
copy_clean:
    lodsb                           ; Get character
    
    ; Skip CR
    cmp al, 13
    je skip_char
    
    ; Skip LF
    cmp al, 10
    je skip_char
    
    ; Store valid character
    stosb
    loop copy_clean
    jmp read_done
    
skip_char:
    loop copy_clean
    
read_done:
    ; Null terminate
    mov BYTE PTR [di], 0
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
read_line ENDP

;================================================================
; TOKENIZE - Split line_buffer into tokens
; Input:  line_buffer contains input string
; Output: token_buffer filled, token_count set
;================================================================
tokenize PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ;=== Clear token buffer ===
    lea di, token_buffer
    mov cx, TOKEN_SIZE * MAX_TOKENS
    xor al, al
    rep stosb
    
    ;=== Initialize ===
    mov WORD PTR [token_count], 0
    lea si, line_buffer
    
next_token:
    ; Check token limit
    mov ax, [token_count]
    cmp ax, MAX_TOKENS
    jge tokenize_done
    
    ;=== Skip whitespace (space, tab, CR, LF) ===
skip_ws:
    mov al, [si]
    
    cmp al, 0                       ; End of string
    je tokenize_done
    
    cmp al, ' '                     ; Space
    je do_skip
    cmp al, 9                       ; Tab
    je do_skip
    cmp al, 13                      ; CR
    je do_skip
    cmp al, 10                      ; LF
    je do_skip
    
    jmp start_token                 ; Found non-whitespace
    
do_skip:
    inc si
    jmp skip_ws
    
start_token:
    ;=== Calculate destination address ===
    ; DI = token_buffer + (token_count × TOKEN_SIZE)
    mov ax, [token_count]
    mov bx, TOKEN_SIZE
    mul bx                          ; AX = offset
    lea di, token_buffer
    add di, ax
    
    xor cx, cx                      ; Character count
    
    ;=== Copy token characters ===
copy_token_char:
    mov al, [si]
    
    ; Check for terminators
    cmp al, 0                       ; NULL
    je end_current_token
    cmp al, ' '                     ; Space
    je end_current_token
    cmp al, 9                       ; Tab
    je end_current_token
    cmp al, 13                      ; CR
    je end_current_token
    cmp al, 10                      ; LF
    je end_current_token
    
    ; Check buffer overflow
    cmp cx, TOKEN_SIZE - 1
    jge skip_overflow
    
    ; *** Copy character ***
    mov [di], al
    inc di
    inc cx
    
skip_overflow:
    inc si
    jmp copy_token_char
    
end_current_token:
    ; Null terminate
    mov BYTE PTR [di], 0
    
    ; Only count if token is not empty
    cmp cx, 0
    je next_token
    
    inc WORD PTR [token_count]
    jmp next_token
    
tokenize_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
tokenize ENDP

;================================================================
; GET_TOKEN - Get pointer to token by index
; Input:  AX = token index (0-based)
; Output: SI = pointer to token string
;================================================================
get_token PROC
    push bx
    push dx
    
    mov bx, TOKEN_SIZE
    mul bx                          ; AX = index × 32
    lea si, token_buffer
    add si, ax
    
    pop dx
    pop bx
    ret
get_token ENDP

;================================================================
; STRCMP - Compare two null-terminated strings
; Input:  SI = string1, DI = string2
; Output: ZF = 1 if equal, ZF = 0 if not equal
;================================================================
strcmp PROC
    push ax
    push si
    push di
    
cmp_loop:
    mov al, [si]
    mov ah, [di]
    
    cmp al, ah
    jne strings_not_equal
    
    cmp al, 0                       ; Both NULL = equal
    je strings_equal
    
    inc si
    inc di
    jmp cmp_loop
    
strings_equal:
    xor ax, ax                      ; Set ZF = 1
    cmp ax, ax
    jmp strcmp_done
    
strings_not_equal:
    xor ax, ax
    inc ax                          ; Set ZF = 0
    cmp ax, 0
    
strcmp_done:
    pop di
    pop si
    pop ax
    ret
strcmp ENDP

;================================================================
; PARSE_EXECUTE - Parse tokens and execute command
;================================================================
parse_execute PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Check for empty input
    cmp WORD PTR [token_count], 0
    jne pd_ok
jmp parse_done
pd_ok:

    
    ; Get first token (command)
    xor ax, ax
    call get_token                  ; SI = command
    
    ;=== Check: exit ===
    lea di, cmd_exit
    call strcmp
    je do_exit
    
    ;=== Check: set ===
    lea di, cmd_set
    call strcmp
    je do_set
    
    ;=== Check: add ===
    lea di, cmd_add
    call strcmp
    je do_add
    
    ;=== Check: sub ===
    lea di, cmd_sub
    call strcmp
   jne sub_ok
jmp do_sub
sub_ok:
    
    ;=== Check: mul ===
    lea di, cmd_mul
    call strcmp
    jne mul_ok
jmp do_mul
mul_ok:

    
    ;=== Check: div ===
    lea di, cmd_div
    call strcmp
    jne div_ok
jmp do_div
div_ok:

    
    ;=== Check: print ===
    lea di, cmd_print
    call strcmp
    jne print_ok
jmp do_print
print_ok:
    ;=== Check: print_str ===
lea di, cmd_print_str
call strcmp
jne ps_ok
jmp do_print_str
ps_ok:



    
    ;=== Check: debug ===
    lea di, cmd_debug
    call strcmp
    jne dbg_ok
jmp do_debug
dbg_ok:

    
    ;=== Unknown command ===
    jmp show_invalid
    
;----------------------------------------------------------------
; EXIT
;----------------------------------------------------------------
do_exit:
    mov BYTE PTR cs:[exit_flag], 1
    jmp parse_done
    
;----------------------------------------------------------------
; SET <var> <number>
;----------------------------------------------------------------
do_set:
    cmp WORD PTR [token_count], 3
   je ok_label
jmp show_syntax_error
ok_label:

    
    ; Get variable name (token 1)
    mov ax, 1
    call get_token
    push si                         ; Save var name pointer
    
    ; Get number (token 2)
    mov ax, 2
    call get_token
    call parse_number               ; AX = value
    
    ; Store variable
    mov bx, ax                      ; BX = value
    pop si                          ; SI = var name
    mov ax, bx
    call set_variable
    
    jmp show_ok
    
;----------------------------------------------------------------
; ADD <var1> and <var2> = <dest>
;----------------------------------------------------------------
do_add:
    call validate_math_syntax
    jnc vms_ok
jmp show_syntax_error
vms_ok:

    
    call get_math_operands          ; BX=val1, CX=val2, DI=dest
    jnc gmo_ok
jmp show_undefined
gmo_ok:

    
    ; Perform addition
    add bx, cx
    mov ax, bx
    mov si, di
    call set_variable
    jmp show_ok
    
;----------------------------------------------------------------
; SUB <var1> and <var2> = <dest>
;----------------------------------------------------------------
do_sub:
    call validate_math_syntax
    jc show_syntax_error
    
    call get_math_operands
    jc show_undefined
    
    ; Perform subtraction
    sub bx, cx
    mov ax, bx
    mov si, di
    call set_variable
    jmp show_ok
    
;----------------------------------------------------------------
; MUL <var1> and <var2> = <dest>
;----------------------------------------------------------------
do_mul:
    call validate_math_syntax
    jc show_syntax_error
    
    call get_math_operands
    jc show_undefined
    
    ; Perform multiplication
    mov ax, bx
    mul cx                          ; DX:AX = result
    mov si, di
    call set_variable
    jmp show_ok
    
;----------------------------------------------------------------
; DIV <var1> and <var2> = <dest>
;----------------------------------------------------------------
do_div:
    call validate_math_syntax
    jc show_syntax_error
    
    call get_math_operands
    jc show_undefined
    
    ; Check for division by zero
    cmp cx, 0
    je show_divzero
    
    ; Perform division
    mov ax, bx
    xor dx, dx
    div cx                          ; AX = quotient
    mov si, di
    call set_variable
    jmp show_ok
    
;----------------------------------------------------------------
; PRINT <var>
;----------------------------------------------------------------
do_print:
    cmp WORD PTR [token_count], 2
    jne show_syntax_error
    
    ; Get variable name
    mov ax, 1
    call get_token
    call get_variable               ; AX = value
    jc show_undefined
    
    ; Print the value
    call print_number
    jmp parse_done
    
;----------------------------------------------------------------
; DEBUG - Show all tokens
;----------------------------------------------------------------
do_debug:
    call debug_show_tokens
    call debug_show_vars
    jmp parse_done
    
;----------------------------------------------------------------
; Error/Success Messages
;----------------------------------------------------------------
show_invalid:
    lea dx, msg_invalid
    mov ah, 09h
    int 21h
    jmp parse_done
    
show_syntax_error:
    lea dx, msg_syntax
    mov ah, 09h
    int 21h
    jmp parse_done
    
show_undefined:
    lea dx, msg_undefined
    mov ah, 09h
    int 21h
    jmp parse_done
    
show_divzero:
    lea dx, msg_divzero
    mov ah, 09h
    int 21h
    jmp parse_done
    
show_ok:
    lea dx, msg_ok
    mov ah, 09h
    int 21h
    
parse_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
parse_execute ENDP
do_print_str PROC
    push ax
    push bx
    push si

    mov bx, 1

ps_loop:
    mov ax, bx
    cmp ax, [token_count]
    jge ps_done

    call get_token

ps_print_chars:
    lodsb
    cmp al, 0
    je ps_space
    mov dl, al
    mov ah, 02h
    int 21h
    jmp ps_print_chars

ps_space:
    mov dl, ' '
    mov ah, 02h
    int 21h

    inc bx
    jmp ps_loop

ps_done:
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    int 21h

    pop si
    pop bx
    pop ax
    ret
do_print_str ENDP


;================================================================
; VALIDATE_MATH_SYNTAX
; Checks: 6 tokens, token[2]="and", token[4]="="
; Output: CF=0 valid, CF=1 invalid
;================================================================
validate_math_syntax PROC
    push ax
    push si
    push di
    
    ; Must have 6 tokens
    cmp WORD PTR [token_count], 6
    jne vms_invalid
    
    ; Token[2] must be "and"
    mov ax, 2
    call get_token
    lea di, kw_and
    call strcmp
    jne vms_invalid
    
    ; Token[4] must be "="
    mov ax, 4
    call get_token
    lea di, kw_equals
    call strcmp
    jne vms_invalid
    
    clc                             ; Valid
    jmp vms_done
    
vms_invalid:
    stc                             ; Invalid
    
vms_done:
    pop di
    pop si
    pop ax
    ret
validate_math_syntax ENDP

;================================================================
; GET_MATH_OPERANDS
; Output: BX = val1, CX = val2, DI = dest name pointer
;         CF=1 if variable not found
;================================================================
get_math_operands PROC
    push ax
    
    ; Get var1 (token 1)
    mov ax, 1
    call get_token
    call get_variable
    jc gmo_error
    mov bx, ax                      ; BX = val1
    
    ; Get var2 (token 3)
    push bx
    mov ax, 3
    call get_token
    call get_variable
    jc gmo_error_pop
    mov cx, ax                      ; CX = val2
    pop bx
    
    ; Get dest name (token 5)
    mov ax, 5
    call get_token
    mov di, si                      ; DI = dest pointer
    
    clc
    jmp gmo_done
    
gmo_error_pop:
    pop bx
gmo_error:
    stc
    
gmo_done:
    pop ax
    ret
get_math_operands ENDP

;================================================================
; SET_VARIABLE - Store value in variable table
; Input:  SI = variable name pointer, AX = value
;================================================================
set_variable PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    push ax                         ; Save value on stack
    
    ; Search for existing variable
    mov cx, [var_count]
    lea di, var_table
    
sv_search:
    cmp cx, 0
    je sv_add_new
    
    ; Compare names
    push cx
    push di
    push si
    
    ; SI already points to search name
    ; DI points to table entry name
    call strcmp
    
    pop si
    pop di
    pop cx
    
    je sv_found
    
    add di, VAR_ENTRY_SIZE          ; Next entry
    dec cx
    jmp sv_search
    
sv_found:
    ; Update existing variable
    pop ax                          ; Restore value
    mov [di + VAR_NAME_SIZE], ax    ; Store at offset 16
    jmp sv_done
    
sv_add_new:
    ; Check if table is full
    cmp WORD PTR [var_count], MAX_VARS
    jge sv_full
    
    ; Calculate new entry address
    mov ax, [var_count]
    mov bx, VAR_ENTRY_SIZE
    mul bx
    lea di, var_table
    add di, ax
    
    ; Copy variable name
    push di                         ; Save entry start
    mov cx, VAR_NAME_SIZE - 1
    
sv_copy_name:
    lodsb
    cmp al, 0
    je sv_name_done
    stosb
    dec cx
    jnz sv_copy_name
    
sv_name_done:
    ; Pad with zeros
    xor al, al
sv_pad:
    stosb
    dec cx
    jns sv_pad
    
    ; Store value
    pop di                          ; Restore entry start
    pop ax                          ; Restore value
    mov [di + VAR_NAME_SIZE], ax
    
    inc WORD PTR [var_count]
    jmp sv_done
    
sv_full:
    pop ax                          ; Clean stack
    lea dx, msg_overflow
    mov ah, 09h
    int 21h
    
sv_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
set_variable ENDP

;================================================================
; GET_VARIABLE - Retrieve value from variable table
; Input:  SI = variable name pointer
; Output: AX = value, CF=1 if not found
;================================================================
get_variable PROC
    push bx
    push cx
    push di
    push si
    
    mov cx, [var_count]
    lea di, var_table
    
gv_search:
    cmp cx, 0
    je gv_not_found
    
    ; Compare names
    push cx
    push di
    push si
    call strcmp
    pop si
    pop di
    pop cx
    
    je gv_found
    
    add di, VAR_ENTRY_SIZE
    dec cx
    jmp gv_search
    
gv_found:
    mov ax, [di + VAR_NAME_SIZE]    ; Get value
    clc
    jmp gv_done
    
gv_not_found:
    stc
    
gv_done:
    pop si
    pop di
    pop cx
    pop bx
    ret
get_variable ENDP

;================================================================
; PARSE_NUMBER - Convert ASCII string to integer
; Input:  SI = pointer to number string
; Output: AX = numeric value
;================================================================
parse_number PROC
    push bx
    push cx
    push dx
    push si
    
    xor ax, ax                      ; Result = 0
    xor bx, bx
    mov cx, 10
    
pn_loop:
    mov bl, [si]
    
    cmp bl, 0
    je pn_done
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    ; result = result * 10 + digit
    mul cx                          ; AX = AX * 10
    sub bl, '0'
    add ax, bx
    
    inc si
    jmp pn_loop
    
pn_done:
    pop si
    pop dx
    pop cx
    pop bx
    ret
parse_number ENDP

;================================================================
; PRINT_NUMBER - Print AX as decimal number
; Input:  AX = number to print
;================================================================
print_number PROC
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx                      ; Digit count
    
    ; Handle zero
    cmp ax, 0
    jne pnum_loop
    
    mov dl, '0'
    mov ah, 02h
    int 21h
    jmp pnum_newline
    
pnum_loop:
    xor dx, dx
    div bx                          ; AX = quotient, DX = remainder
    push dx                         ; Save digit
    inc cx
    cmp ax, 0
    jne pnum_loop
    
pnum_print:
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    loop pnum_print
    
pnum_newline:
    mov dl, 13
    mov ah, 02h
    int 21h
    mov dl, 10
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number ENDP

;================================================================
; DEBUG_SHOW_TOKENS - Display all parsed tokens
;================================================================
debug_show_tokens PROC
    push ax
    push bx
    push cx
    push dx
    push si
    
    ; Print header
    lea dx, msg_dbg_header
    mov ah, 09h
    int 21h
    
    ; Print token count
    lea dx, msg_dbg_count
    mov ah, 09h
    int 21h
    
    mov ax, [token_count]
    call print_number
    
    ; Loop through tokens
    mov cx, [token_count]
    xor bx, bx                      ; Index
    
dst_loop:
    cmp cx, 0
    je dst_done
    
    ; Print "Token["
    lea dx, msg_dbg_token
    mov ah, 09h
    int 21h
    
    ; Print index
    mov dl, bl
    add dl, '0'
    mov ah, 02h
    int 21h
    
    ; Print "]: |"
    lea dx, msg_dbg_end
    mov ah, 09h
    int 21h
    
    ; Get and print token
    mov ax, bx
    call get_token
    
dst_print_chars:
    lodsb
    cmp al, 0
    je dst_end_token
    mov dl, al
    mov ah, 02h
    int 21h
    jmp dst_print_chars
    
dst_end_token:
    ; Print "|" and newline
    lea dx, msg_dbg_pipe
    mov ah, 09h
    int 21h
    
    inc bx
    dec cx
    jmp dst_loop
    
dst_done:
    lea dx, msg_newline
    mov ah, 09h
    int 21h
    
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
debug_show_tokens ENDP

;================================================================
; DEBUG_SHOW_VARS - Display all variables
;================================================================
debug_show_vars PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Print header
    lea dx, msg_dbg_vars
    mov ah, 09h
    int 21h
    
    mov cx, [var_count]
    lea di, var_table
    xor bx, bx
    
dsv_loop:
    cmp cx, 0
    je dsv_done
    
    ; Print variable name
    push cx
    push di
    
    mov si, di
dsv_print_name:
    lodsb
    cmp al, 0
    je dsv_name_done
    mov dl, al
    mov ah, 02h
    int 21h
    jmp dsv_print_name
    
dsv_name_done:
    ; Print " = "
    mov dl, ' '
    mov ah, 02h
    int 21h
    mov dl, '='
    int 21h
    mov dl, ' '
    int 21h
    
    ; Print value
    pop di
    mov ax, [di + VAR_NAME_SIZE]
    call print_number
    
    add di, VAR_ENTRY_SIZE
    pop cx
    dec cx
    jmp dsv_loop
    
dsv_done:
    lea dx, msg_newline
    mov ah, 09h
    int 21h
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
debug_show_vars ENDP

;================================================================
END main
