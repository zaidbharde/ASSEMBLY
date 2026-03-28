;================================================================
;  ZAID VIRTUAL CPU SYSTEM v2.0 - COMPLETE FIXED VERSION
;  Build:  tasm project.asm
;          tlink project.obj
;          project.exe
;================================================================

.MODEL SMALL
.STACK 512

;================================================================
;                      CONSTANTS
;================================================================
TOKEN_SIZE      EQU 32
MAX_TOKENS      EQU 10
LINE_SIZE       EQU 256
VAR_NAME_SIZE   EQU 16
VAR_ENTRY_SIZE  EQU 18
MAX_VARS        EQU 26
MAX_STRINGS     EQU 16
STRING_SIZE     EQU 64
VCPU_MEM_SIZE   EQU 2048
BYTECODE_SIZE   EQU 1024
VCPU_STACK_BASE EQU 0100h

;================================================================
;                 VIRTUAL CPU OPCODES
;================================================================
OP_NOP          EQU 00h
OP_HLT          EQU 01h
OP_SYSCALL      EQU 02h
OP_LOAD_IMM     EQU 10h
OP_LOAD_VAR     EQU 11h
OP_STORE_VAR    EQU 12h
OP_ADD          EQU 20h
OP_SUB          EQU 21h
OP_MUL          EQU 22h
OP_DIV          EQU 23h
OP_PRINT_STR    EQU 61h

; System Call Numbers (renamed to avoid conflicts)
SC_PRINT_NUM    EQU 01h
SC_PRINT_STR    EQU 02h
SC_PRINT_NL     EQU 04h
SC_EXIT         EQU 0FFh

;================================================================
;                      DATA SEGMENT
;================================================================
.DATA

exit_flag       DB 0
error_flag      DB 0

input_buffer    DB LINE_SIZE DUP(0)
line_buffer     DB LINE_SIZE DUP(0)
token_buffer    DB TOKEN_SIZE * MAX_TOKENS DUP(0)
token_count     DW 0

; Virtual CPU State
vcpu_R0         DW 0
vcpu_R1         DW 0
vcpu_R2         DW 0
vcpu_R3         DW 0
vcpu_SP         DW VCPU_STACK_BASE + 0FEh
vcpu_BP         DW 0
vcpu_IP         DW 0
vcpu_FLAGS      DW 0
vcpu_running    DB 0
vcpu_error      DB 0
vcpu_memory     DB VCPU_MEM_SIZE DUP(0)

; Assembler Data
bytecode_buf    DB BYTECODE_SIZE DUP(0)
bytecode_len    DW 0
bytecode_ptr    DW 0

var_table       DB MAX_VARS * VAR_ENTRY_SIZE DUP(0)
var_count       DW 0

string_table    DB MAX_STRINGS * STRING_SIZE DUP(0)
string_count    DW 0

current_line    DW 0

; Command Keywords
cmd_set         DB 'set', 0
cmd_add         DB 'add', 0
cmd_sub         DB 'sub', 0
cmd_mul         DB 'mul', 0
cmd_div         DB 'div', 0
cmd_print       DB 'print', 0
cmd_exit        DB 'exit', 0
cmd_reset       DB 'reset', 0
cmd_debug       DB 'debug', 0
cmd_regs        DB 'regs', 0
cmd_help        DB 'help', 0
kw_and          DB 'and', 0
kw_equals       DB '=', 0

; Messages
msg_welcome     DB 13, 10
                DB '========================================', 13, 10
                DB '   ZAID VIRTUAL CPU SYSTEM v1.0', 13, 10
                DB '========================================', 13, 10
                DB ' Commands: set, add, sub, mul, div,', 13, 10
                DB '           print, exit, regs, debug', 13, 10
                DB '========================================', 13, 10, '$'

msg_prompt      DB 13, 10, 'ZAID> ', '$'
msg_ok          DB 'OK', 13, 10, '$'
msg_bye         DB 'Goodbye!', 13, 10, '$'
msg_reset_ok    DB 'Reset done.', 13, 10, '$'
msg_newline     DB 13, 10, '$'

msg_err_syntax  DB 'Syntax Error', 13, 10, '$'
msg_err_undef   DB 'Undefined variable', 13, 10, '$'
msg_err_divzero DB 'Division by zero', 13, 10, '$'
msg_err_overflow DB 'Table overflow', 13, 10, '$'
msg_err_invalid DB 'Invalid command', 13, 10, '$'
msg_err_opcode  DB 'Invalid opcode', 13, 10, '$'

msg_dbg_tokens  DB '--- Tokens ---', 13, 10, '$'
msg_dbg_vars    DB '--- Variables ---', 13, 10, '$'
msg_dbg_regs    DB '--- Registers ---', 13, 10, '$'
msg_dbg_bc      DB '--- Bytecode (', '$'
msg_dbg_bytes   DB ' bytes) ---', 13, 10, '$'

msg_r0          DB 'R0=', '$'
msg_r1          DB ' R1=', '$'
msg_r2          DB ' R2=', '$'
msg_r3          DB ' R3=', '$'

msg_help        DB 13, 10
                DB 'set <var> <val>        - Set variable', 13, 10
                DB 'add <a> and <b> = <c>  - Add', 13, 10
                DB 'sub <a> and <b> = <c>  - Subtract', 13, 10
                DB 'mul <a> and <b> = <c>  - Multiply', 13, 10
                DB 'div <a> and <b> = <c>  - Divide', 13, 10
                DB 'print <var>            - Print value', 13, 10
                DB 'print(<text>)          - Print text', 13, 10
                DB 'exit                   - Exit', 13, 10
                DB 'regs                   - Show registers', 13, 10
                DB 'debug                  - Debug info', 13, 10
                DB '$'

;================================================================
;                      CODE SEGMENT
;================================================================
.CODE

;================================================================
; MAIN
;================================================================
main PROC
    mov ax, @data
    mov ds, ax
    mov es, ax
    cld
    
    call vcpu_init
    
    mov ah, 09h
    lea dx, msg_welcome
    int 21h

main_loop:
    mov ah, 09h
    lea dx, msg_prompt
    int 21h
    
    call read_line
    
    lea si, line_buffer
    cmp BYTE PTR [si], 0
    je main_loop
    
    call tokenize
    
    cmp WORD PTR [token_count], 0
    je main_loop
    
    call process_command
    
    cmp BYTE PTR [exit_flag], 1
    je main_exit
    
    jmp main_loop

main_exit:
    mov ah, 09h
    lea dx, msg_bye
    int 21h
    
    mov ax, 4C00h
    int 21h
main ENDP

;================================================================
; VCPU_INIT
;================================================================
vcpu_init PROC
    push ax
    push cx
    push di
    
    xor ax, ax
    mov WORD PTR [vcpu_R0], ax
    mov WORD PTR [vcpu_R1], ax
    mov WORD PTR [vcpu_R2], ax
    mov WORD PTR [vcpu_R3], ax
    mov WORD PTR [vcpu_BP], ax
    mov WORD PTR [vcpu_IP], ax
    mov WORD PTR [vcpu_FLAGS], ax
    mov WORD PTR [vcpu_SP], VCPU_STACK_BASE + 0FEh
    mov BYTE PTR [vcpu_running], 0
    mov BYTE PTR [vcpu_error], 0
    mov BYTE PTR [exit_flag], 0
    mov BYTE PTR [error_flag], 0
    
    lea di, vcpu_memory
    mov cx, VCPU_MEM_SIZE
    xor al, al
    rep stosb
    
    lea di, bytecode_buf
    mov cx, BYTECODE_SIZE
    rep stosb
    mov WORD PTR [bytecode_len], 0
    mov WORD PTR [bytecode_ptr], 0
    
    lea di, var_table
    mov cx, MAX_VARS * VAR_ENTRY_SIZE
    rep stosb
    mov WORD PTR [var_count], 0
    
    lea di, string_table
    mov cx, MAX_STRINGS * STRING_SIZE
    rep stosb
    mov WORD PTR [string_count], 0
    
    pop di
    pop cx
    pop ax
    ret
vcpu_init ENDP

;================================================================
; READ_LINE
;================================================================
read_line PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    lea di, line_buffer
    mov cx, LINE_SIZE
    xor al, al
    rep stosb
    
    lea dx, input_buffer
    mov BYTE PTR [input_buffer], LINE_SIZE - 2
    mov ah, 0Ah
    int 21h
    
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    
    lea si, input_buffer + 2
    lea di, line_buffer
    xor ch, ch
    mov cl, BYTE PTR [input_buffer + 1]
    
    jcxz rl_done
    
rl_copy:
    lodsb
    cmp al, 13
    je rl_skip
    cmp al, 10
    je rl_skip
    stosb
    loop rl_copy
    jmp rl_done
    
rl_skip:
    loop rl_copy
    
rl_done:
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
; TOKENIZE
;================================================================
tokenize PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    lea di, token_buffer
    mov cx, TOKEN_SIZE * MAX_TOKENS
    xor al, al
    rep stosb
    
    mov WORD PTR [token_count], 0
    lea si, line_buffer

tok_next:
    mov ax, WORD PTR [token_count]
    cmp ax, MAX_TOKENS
    jl tok_continue
    jmp tok_done
    
tok_continue:
tok_skip_ws:
    mov al, BYTE PTR [si]
    cmp al, 0
    jne tok_not_end
    jmp tok_done
tok_not_end:
    cmp al, ' '
    je tok_do_skip
    cmp al, 9
    je tok_do_skip
    jmp tok_check_paren
    
tok_do_skip:
    inc si
    jmp tok_skip_ws

tok_check_paren:
    cmp al, '('
    jne tok_normal
    inc si
    jmp tok_paren_content

tok_normal:
    mov ax, WORD PTR [token_count]
    mov bx, TOKEN_SIZE
    mul bx
    lea di, token_buffer
    add di, ax
    xor cx, cx

tok_copy:
    mov al, BYTE PTR [si]
    
    cmp al, 0
    je tok_end_token
    cmp al, ' '
    je tok_end_token
    cmp al, 9
    je tok_end_token
    cmp al, '('
    je tok_end_token
    cmp al, ')'
    je tok_skip_paren
    cmp al, '='
    jne tok_not_eq
    
    cmp cx, 0
    je tok_store_eq
    jmp tok_end_token
    
tok_store_eq:
    mov BYTE PTR [di], al
    inc di
    inc cx
    inc si
    jmp tok_end_token
    
tok_not_eq:
    cmp cx, TOKEN_SIZE - 1
    jge tok_skip_ch
    mov BYTE PTR [di], al
    inc di
    inc cx
    
tok_skip_ch:
    inc si
    jmp tok_copy

tok_skip_paren:
    inc si
    jmp tok_end_token

tok_paren_content:
    mov ax, WORD PTR [token_count]
    mov bx, TOKEN_SIZE
    mul bx
    lea di, token_buffer
    add di, ax
    xor cx, cx

tok_paren_loop:
    mov al, BYTE PTR [si]
    cmp al, 0
    je tok_end_token
    cmp al, ')'
    je tok_paren_end
    cmp cx, TOKEN_SIZE - 1
    jge tok_paren_sk
    mov BYTE PTR [di], al
    inc di
    inc cx
tok_paren_sk:
    inc si
    jmp tok_paren_loop

tok_paren_end:
    inc si

tok_end_token:
    mov BYTE PTR [di], 0
    cmp cx, 0
    jne _t1
    jmp tok_next
_t1:
    inc WORD PTR [token_count]
    jmp tok_next


tok_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
tokenize ENDP

;================================================================
; GET_TOKEN
;================================================================
get_token PROC
    push bx
    push dx
    mov bx, TOKEN_SIZE
    mul bx
    lea si, token_buffer
    add si, ax
    pop dx
    pop bx
    ret
get_token ENDP

;================================================================
; STRCMP
;================================================================
strcmp PROC
    push ax
    push bx
    push si
    push di

strcmp_loop:
    mov al, BYTE PTR [si]
    mov bl, BYTE PTR [di]
    cmp al, bl
    jne strcmp_neq
    cmp al, 0
    je strcmp_eq
    inc si
    inc di
    jmp strcmp_loop

strcmp_eq:
    xor ax, ax
    cmp ax, ax
    jmp strcmp_ret

strcmp_neq:
    mov ax, 1
    cmp ax, 0

strcmp_ret:
    pop di
    pop si
    pop bx
    pop ax
    ret
strcmp ENDP

;================================================================
; PROCESS_COMMAND
;================================================================
process_command PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov WORD PTR [bytecode_ptr], 0
    mov BYTE PTR [error_flag], 0
    
    xor ax, ax
    call get_token
    
    ; Check commands using trampolines for far jumps
    lea di, cmd_help
    call strcmp
    jne pc_not_help
    jmp pc_help
pc_not_help:
    
    lea di, cmd_regs
    call strcmp
    jne pc_not_regs
    jmp pc_regs
pc_not_regs:
    
    lea di, cmd_debug
    call strcmp
    jne pc_not_debug
    jmp pc_debug
pc_not_debug:
    
    lea di, cmd_reset
    call strcmp
    jne pc_not_reset
    jmp pc_reset
pc_not_reset:
    
    lea di, cmd_exit
    call strcmp
    jne pc_not_exit
    jmp pc_exit_cmd
pc_not_exit:
    
    lea di, cmd_set
    call strcmp
    jne pc_not_set
    jmp pc_set
pc_not_set:
    
    lea di, cmd_add
    call strcmp
    jne pc_not_add
    jmp pc_add
pc_not_add:
    
    lea di, cmd_sub
    call strcmp
    jne pc_not_sub
    jmp pc_sub
pc_not_sub:
    
    lea di, cmd_mul
    call strcmp
    jne pc_not_mul
    jmp pc_mul
pc_not_mul:
    
    lea di, cmd_div
    call strcmp
    jne pc_not_div
    jmp pc_div
pc_not_div:
    
    lea di, cmd_print
    call strcmp
    jne pc_not_print
    jmp pc_print
pc_not_print:
    
    jmp pc_invalid

;--- HELP ---
pc_help:
    mov ah, 09h
    lea dx, msg_help
    int 21h
    jmp pc_done

;--- REGS ---
pc_regs:
    call show_registers
    jmp pc_done

;--- DEBUG ---
pc_debug:
    call debug_all
    jmp pc_done

;--- RESET ---
pc_reset:
    call vcpu_init
    mov ah, 09h
    lea dx, msg_reset_ok
    int 21h
    jmp pc_done

;--- EXIT ---
pc_exit_cmd:
    mov BYTE PTR [exit_flag], 1
    jmp pc_done

;--- SET ---
pc_set:
    cmp WORD PTR [token_count], 3
    je pc_set_ok
    jmp pc_syntax
pc_set_ok:
    mov ax, 1
    call get_token
    call get_or_create_var
    jnc pc_set_ok2
    jmp pc_overflow
pc_set_ok2:
    mov bl, al
    
    mov ax, 2
    call get_token
    call parse_number
    
    push bx
    mov bx, ax
    
    mov al, OP_LOAD_IMM
    call emit_byte
    xor al, al
    call emit_byte
    mov ax, bx
    call emit_word
    
    pop bx
    
    mov al, OP_STORE_VAR
    call emit_byte
    mov al, bl
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    call execute_bytecode
    
    cmp BYTE PTR [error_flag], 0
je _pc1
jmp pc_done
_pc1:

    mov ah, 09h
    lea dx, msg_ok
    int 21h
    jmp pc_done

;--- ADD ---
pc_add:
    call do_math_op
    mov al, OP_ADD
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    call emit_byte
    call finish_math
    jmp pc_done

;--- SUB ---
pc_sub:
    call do_math_op
    mov al, OP_SUB
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    call emit_byte
    call finish_math
    jmp pc_done

;--- MUL ---
pc_mul:
    call do_math_op
    mov al, OP_MUL
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    call emit_byte
    call finish_math
    jmp pc_done

;--- DIV ---
pc_div:
    call do_math_op
    mov al, OP_DIV
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    call emit_byte
    call finish_math
    jmp pc_done

;--- PRINT ---
pc_print:
    cmp WORD PTR [token_count], 2
    je pc_print_ok
    jmp pc_syntax
pc_print_ok:
    mov ax, 1
    call get_token
    
    push si
    call find_variable
    pop si
    jc pc_print_str
    
    ; Print variable
    push ax
    mov al, OP_LOAD_VAR
    call emit_byte
    pop ax
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    mov al, OP_SYSCALL
    call emit_byte
    mov al, SC_PRINT_NUM
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    mov al, OP_SYSCALL
    call emit_byte
    mov al, SC_PRINT_NL
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    jmp pc_print_run

pc_print_str:
    call store_string
    push ax
    
    mov al, OP_PRINT_STR
    call emit_byte
    pop ax
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    mov al, OP_SYSCALL
    call emit_byte
    mov al, SC_PRINT_NL
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte

pc_print_run:
    call execute_bytecode
    jmp pc_done

;--- ERRORS ---
pc_syntax:
    mov ah, 09h
    lea dx, msg_err_syntax
    int 21h
    jmp pc_done

pc_overflow:
    mov ah, 09h
    lea dx, msg_err_overflow
    int 21h
    jmp pc_done

pc_invalid:
    mov ah, 09h
    lea dx, msg_err_invalid
    int 21h

pc_done:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
process_command ENDP

;================================================================
; DO_MATH_OP - Validate and emit load for math operations
;================================================================
do_math_op PROC
    push ax
    push bx
    push si
    push di
    
    cmp WORD PTR [token_count], 6
    jne dmo_bad
    
    mov ax, 2
    call get_token
    lea di, kw_and
    call strcmp
    jne dmo_bad
    
    mov ax, 4
    call get_token
    lea di, kw_equals
    call strcmp
    jne dmo_bad
    
    ; Load var1 to R0
    mov ax, 1
    call get_token
    call find_variable
    jc dmo_undef
    mov bl, al
    
    mov al, OP_LOAD_VAR
    call emit_byte
    mov al, bl
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    ; Load var2 to R1
    mov ax, 3
    call get_token
    call find_variable
    jc dmo_undef
    mov bl, al
    
    mov al, OP_LOAD_VAR
    call emit_byte
    mov al, bl
    call emit_byte
    mov al, 1
    call emit_byte
    xor al, al
    call emit_byte
    
    jmp dmo_ret

dmo_bad:
    mov ah, 09h
    lea dx, msg_err_syntax
    int 21h
    mov BYTE PTR [error_flag], 1
    jmp dmo_ret

dmo_undef:
    mov ah, 09h
    lea dx, msg_err_undef
    int 21h
    mov BYTE PTR [error_flag], 1

dmo_ret:
    pop di
    pop si
    pop bx
    pop ax
    ret
do_math_op ENDP

;================================================================
; FINISH_MATH - Store result and execute
;================================================================
finish_math PROC
    push ax
    push bx
    push si
    
    cmp BYTE PTR [error_flag], 0
    jne fm_ret
    
    mov ax, 5
    call get_token
    call get_or_create_var
    jc fm_err
    mov bl, al
    
    mov al, OP_STORE_VAR
    call emit_byte
    mov al, bl
    call emit_byte
    xor al, al
    call emit_byte
    call emit_byte
    
    call execute_bytecode
    
    cmp BYTE PTR [error_flag], 0
    jne fm_ret
    
    mov ah, 09h
    lea dx, msg_ok
    int 21h
    jmp fm_ret

fm_err:
    mov ah, 09h
    lea dx, msg_err_overflow
    int 21h

fm_ret:
    pop si
    pop bx
    pop ax
    ret
finish_math ENDP

;================================================================
; EMIT_BYTE
;================================================================
emit_byte PROC
    push bx
    push di
    mov bx, WORD PTR [bytecode_ptr]
    lea di, bytecode_buf
    add di, bx
    mov BYTE PTR [di], al
    inc WORD PTR [bytecode_ptr]
    pop di
    pop bx
    ret
emit_byte ENDP

;================================================================
; EMIT_WORD
;================================================================
emit_word PROC
    push bx
    push di
    mov bx, WORD PTR [bytecode_ptr]
    lea di, bytecode_buf
    add di, bx
    mov WORD PTR [di], ax
    add WORD PTR [bytecode_ptr], 2
    pop di
    pop bx
    ret
emit_word ENDP

;================================================================
; GET_OR_CREATE_VAR
;================================================================
get_or_create_var PROC
    push bx
    push cx
    push dx
    push di
    
    push si
    call find_variable
    pop si
    jnc gocv_ret
    
    mov cx, WORD PTR [var_count]
    cmp cx, MAX_VARS
    jge gocv_full
    
    mov ax, cx
    mov bx, VAR_ENTRY_SIZE
    mul bx
    lea di, var_table
    add di, ax
    
    mov cx, VAR_NAME_SIZE - 1
gocv_copy:
    lodsb
    cmp al, 0
    je gocv_pad
    mov BYTE PTR [di], al
    inc di
    dec cx
    jnz gocv_copy
    
gocv_pad:
    xor al, al
gocv_pad_lp:
    mov BYTE PTR [di], al
    inc di
    dec cx
    jns gocv_pad_lp
    
    mov ax, WORD PTR [var_count]
    inc WORD PTR [var_count]
    clc
    jmp gocv_ret
    
gocv_full:
    stc
    
gocv_ret:
    pop di
    pop dx
    pop cx
    pop bx
    ret
get_or_create_var ENDP

;================================================================
; FIND_VARIABLE
;================================================================
find_variable PROC
    push bx
    push cx
    push di
    
    mov cx, WORD PTR [var_count]
    cmp cx, 0
    je fv_notfound
    
    lea di, var_table
    xor bx, bx

fv_loop:
    push cx
    push si
    push di

fv_cmp:
    mov al, BYTE PTR [si]
    mov ah, BYTE PTR [di]
    cmp al, ah
    jne fv_next
    cmp al, 0
    je fv_match
    inc si
    inc di
    jmp fv_cmp

fv_next:
    pop di
    pop si
    pop cx
    add di, VAR_ENTRY_SIZE
    inc bx
    loop fv_loop
    jmp fv_notfound

fv_match:
    pop di
    pop si
    pop cx
    mov ax, bx
    clc
    jmp fv_ret

fv_notfound:
    stc

fv_ret:
    pop di
    pop cx
    pop bx
    ret
find_variable ENDP

;================================================================
; STORE_STRING
;================================================================
store_string PROC
    push bx
    push cx
    push di
    
    mov ax, WORD PTR [string_count]
    cmp ax, MAX_STRINGS
    jge ss_ovf
    
    push ax
    mov bx, STRING_SIZE
    mul bx
    lea di, string_table
    add di, ax
    
    mov cx, STRING_SIZE - 1
ss_copy:
    lodsb
    cmp al, 0
    je ss_end
    mov BYTE PTR [di], al
    inc di
    dec cx
    jnz ss_copy
    
ss_end:
    mov BYTE PTR [di], 0
    inc WORD PTR [string_count]
    pop ax
    jmp ss_ret
    
ss_ovf:
    xor ax, ax
    
ss_ret:
    pop di
    pop cx
    pop bx
    ret
store_string ENDP

;================================================================
; PARSE_NUMBER
;================================================================
parse_number PROC
    push bx
    push cx
    push dx
    
    xor ax, ax
    mov cx, 10

pn_loop:
    mov bl, BYTE PTR [si]
    cmp bl, '0'
    jb pn_done
    cmp bl, '9'
    ja pn_done
    
    mul cx
    sub bl, '0'
    xor bh, bh
    add ax, bx
    inc si
    jmp pn_loop
    
pn_done:
    pop dx
    pop cx
    pop bx
    ret
parse_number ENDP

;================================================================
; EXECUTE_BYTECODE
;================================================================
execute_bytecode PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    mov ax, WORD PTR [bytecode_ptr]
    cmp ax, 0
    jne exec_start
    jmp exec_ret
    
exec_start:
    mov WORD PTR [bytecode_len], ax
    mov WORD PTR [vcpu_IP], 0
    mov BYTE PTR [vcpu_running], 1
    mov BYTE PTR [vcpu_error], 0

exec_loop:
    cmp BYTE PTR [vcpu_running], 0
    jne exec_cont
    jmp exec_ret
exec_cont:
    mov bx, WORD PTR [vcpu_IP]
    cmp bx, WORD PTR [bytecode_len]
    jl exec_fetch
    jmp exec_halt
    
exec_fetch:
    lea si, bytecode_buf
    add si, bx
    mov al, BYTE PTR [si]
    
    ; Dispatch opcodes
    cmp al, OP_NOP
    jne ex_not_nop
    jmp exec_nop
ex_not_nop:
    cmp al, OP_HLT
    jne ex_not_hlt
    jmp exec_halt
ex_not_hlt:
    cmp al, OP_SYSCALL
    jne ex_not_sys
    jmp exec_syscall
ex_not_sys:
    cmp al, OP_LOAD_IMM
    jne ex_not_li
    jmp exec_load_imm
ex_not_li:
    cmp al, OP_LOAD_VAR
    jne ex_not_lv
    jmp exec_load_var
ex_not_lv:
    cmp al, OP_STORE_VAR
    jne ex_not_sv
    jmp exec_store_var
ex_not_sv:
    cmp al, OP_ADD
    jne ex_not_add
    jmp exec_add
ex_not_add:
    cmp al, OP_SUB
    jne ex_not_sub
    jmp exec_sub
ex_not_sub:
    cmp al, OP_MUL
    jne ex_not_mul
    jmp exec_mul
ex_not_mul:
    cmp al, OP_DIV
    jne ex_not_div
    jmp exec_div
ex_not_div:
    cmp al, OP_PRINT_STR
    jne ex_not_ps
    jmp exec_prt_str
ex_not_ps:
    jmp exec_error

exec_nop:
    add WORD PTR [vcpu_IP], 4
    jmp exec_loop

exec_halt:
    mov BYTE PTR [vcpu_running], 0
    jmp exec_ret

exec_syscall:
    mov al, BYTE PTR [si+1]
    
    cmp al, SC_PRINT_NUM
    jne ex_sys_not_pn
    mov ax, WORD PTR [vcpu_R0]
    call print_number
    jmp exec_next
ex_sys_not_pn:
    cmp al, SC_PRINT_NL
    jne ex_sys_not_nl
    mov ah, 02h
    mov dl, 13
    int 21h
    mov dl, 10
    int 21h
    jmp exec_next
ex_sys_not_nl:
    cmp al, SC_EXIT
    je _e1
    jmp exec_next
_e1:
    mov BYTE PTR [vcpu_running], 0
    jmp exec_ret


exec_load_imm:
    mov al, BYTE PTR [si+1]
    mov bx, WORD PTR [si+2]
    
    cmp al, 0
    jne eli_n0
    mov WORD PTR [vcpu_R0], bx
    jmp exec_next
eli_n0:
    cmp al, 1
    jne eli_n1
    mov WORD PTR [vcpu_R1], bx
    jmp exec_next
eli_n1:
    cmp al, 2
    jne eli_n2
    mov WORD PTR [vcpu_R2], bx
    jmp exec_next
eli_n2:
    mov WORD PTR [vcpu_R3], bx
    jmp exec_next

exec_load_var:
    mov al, BYTE PTR [si+1]
    mov cl, BYTE PTR [si+2]
    
    xor ah, ah
    shl ax, 1
    mov bx, ax
    lea di, vcpu_memory
    add di, bx
    mov ax, WORD PTR [di]
    
    cmp cl, 0
    jne elv_n0
    mov WORD PTR [vcpu_R0], ax
    jmp exec_next
elv_n0:
    cmp cl, 1
    jne elv_n1
    mov WORD PTR [vcpu_R1], ax
    jmp exec_next
elv_n1:
    cmp cl, 2
    jne elv_n2
    mov WORD PTR [vcpu_R2], ax
    jmp exec_next
elv_n2:
    mov WORD PTR [vcpu_R3], ax
    jmp exec_next

exec_store_var:
    mov al, BYTE PTR [si+1]
    mov cl, BYTE PTR [si+2]
    
    cmp cl, 0
    jne esv_n0
    mov bx, WORD PTR [vcpu_R0]
    jmp esv_store
esv_n0:
    cmp cl, 1
    jne esv_n1
    mov bx, WORD PTR [vcpu_R1]
    jmp esv_store
esv_n1:
    cmp cl, 2
    jne esv_n2
    mov bx, WORD PTR [vcpu_R2]
    jmp esv_store
esv_n2:
    mov bx, WORD PTR [vcpu_R3]

esv_store:
    xor ah, ah
    shl ax, 1
    mov di, ax
    lea ax, vcpu_memory
    add di, ax
    mov WORD PTR [di], bx
    jmp exec_next

exec_add:
    mov ax, WORD PTR [vcpu_R0]
    add ax, WORD PTR [vcpu_R1]
    mov WORD PTR [vcpu_R0], ax
    jmp exec_next

exec_sub:
    mov ax, WORD PTR [vcpu_R0]
    sub ax, WORD PTR [vcpu_R1]
    mov WORD PTR [vcpu_R0], ax
    jmp exec_next

exec_mul:
    mov ax, WORD PTR [vcpu_R0]
    mov bx, WORD PTR [vcpu_R1]
    mul bx
    mov WORD PTR [vcpu_R0], ax
    mov WORD PTR [vcpu_R1], dx
    jmp exec_next

exec_div:
    mov bx, WORD PTR [vcpu_R1]
    cmp bx, 0
    jne exec_div_ok
    mov ah, 09h
    lea dx, msg_err_divzero
    int 21h
    mov BYTE PTR [error_flag], 1
    mov BYTE PTR [vcpu_running], 0
    jmp exec_ret
    
exec_div_ok:
    mov ax, WORD PTR [vcpu_R0]
    xor dx, dx
    div bx
    mov WORD PTR [vcpu_R0], ax
    mov WORD PTR [vcpu_R1], dx
    jmp exec_next

exec_prt_str:
    mov al, BYTE PTR [si+1]
    xor ah, ah
    call print_str_idx
    jmp exec_next

exec_error:
    mov ah, 09h
    lea dx, msg_err_opcode
    int 21h
    mov BYTE PTR [error_flag], 1
    mov BYTE PTR [vcpu_running], 0
    jmp exec_ret

exec_next:
    add WORD PTR [vcpu_IP], 4
    jmp exec_loop

exec_ret:
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
execute_bytecode ENDP

;================================================================
; PRINT_NUMBER
;================================================================
print_number PROC
    push ax
    push bx
    push cx
    push dx
    
    mov bx, 10
    xor cx, cx
    
    cmp ax, 0
    jne pnum_lp
    mov ah, 02h
    mov dl, '0'
    int 21h
    jmp pnum_ret
    
pnum_lp:
    cmp ax, 0
    je pnum_pr
    xor dx, dx
    div bx
    push dx
    inc cx
    jmp pnum_lp
    
pnum_pr:
    cmp cx, 0
    je pnum_ret
    pop dx
    add dl, '0'
    mov ah, 02h
    int 21h
    dec cx
    jmp pnum_pr
    
pnum_ret:
    pop dx
    pop cx
    pop bx
    pop ax
    ret
print_number ENDP

;================================================================
; PRINT_STR_IDX
;================================================================
print_str_idx PROC
    push ax
    push bx
    push si
    
    mov bx, STRING_SIZE
    mul bx
    lea si, string_table
    add si, ax
    
psi_lp:
    lodsb
    cmp al, 0
    je psi_ret
    mov ah, 02h
    mov dl, al
    int 21h
    jmp psi_lp
    
psi_ret:
    pop si
    pop bx
    pop ax
    ret
print_str_idx ENDP

;================================================================
; SHOW_REGISTERS
;================================================================
show_registers PROC
    push ax
    push dx
    
    mov ah, 09h
    lea dx, msg_dbg_regs
    int 21h
    
    lea dx, msg_r0
    int 21h
    mov ax, WORD PTR [vcpu_R0]
    call print_number
    
    lea dx, msg_r1
    int 21h
    mov ax, WORD PTR [vcpu_R1]
    call print_number
    
    lea dx, msg_r2
    int 21h
    mov ax, WORD PTR [vcpu_R2]
    call print_number
    
    lea dx, msg_r3
    int 21h
    mov ax, WORD PTR [vcpu_R3]
    call print_number
    
    lea dx, msg_newline
    int 21h
    
    pop dx
    pop ax
    ret
show_registers ENDP

;================================================================
; DEBUG_ALL
;================================================================
debug_all PROC
    push ax
    push bx
    push cx
    push dx
    push si
    push di
    
    ; Tokens
    mov ah, 09h
    lea dx, msg_dbg_tokens
    int 21h
    
    mov cx, WORD PTR [token_count]
    xor bx, bx
    
da_tok:
    cmp cx, 0
    je da_vars
    
    mov ah, 02h
    mov dl, '['
    int 21h
    mov dl, bl
    add dl, '0'
    int 21h
    mov dl, ']'
    int 21h
    mov dl, ' '
    int 21h
    
    mov ax, bx
    call get_token
    
da_prt_tok:
    lodsb
    cmp al, 0
    je da_tok_nl
    mov ah, 02h
    mov dl, al
    int 21h
    jmp da_prt_tok
    
da_tok_nl:
    mov ah, 09h
    lea dx, msg_newline
    int 21h
    inc bx
    dec cx
    jmp da_tok
    
da_vars:
    mov ah, 09h
    lea dx, msg_dbg_vars
    int 21h
    
    mov cx, WORD PTR [var_count]
    cmp cx, 0
    je da_bc
    
    lea di, var_table
    xor bx, bx
    
da_var:
    cmp cx, 0
    je da_bc
    
    mov si, di
da_pname:
    lodsb
    cmp al, 0
    je da_peq
    mov ah, 02h
    mov dl, al
    int 21h
    jmp da_pname
    
da_peq:
    mov ah, 02h
    mov dl, '='
    int 21h
    
    mov ax, bx
    shl ax, 1
    push di
    lea di, vcpu_memory
    add di, ax
    mov ax, WORD PTR [di]
    pop di
    
    call print_number
    
    mov ah, 09h
    lea dx, msg_newline
    int 21h
    
    add di, VAR_ENTRY_SIZE
    inc bx
    dec cx
    jmp da_var
    
da_bc:
    mov ah, 09h
    lea dx, msg_dbg_bc
    int 21h
    
    mov ax, WORD PTR [bytecode_ptr]
    call print_number
    
    lea dx, msg_dbg_bytes
    int 21h
    
    mov cx, WORD PTR [bytecode_ptr]
    cmp cx, 0
    je da_ret
    
    lea si, bytecode_buf
    xor bx, bx
    
da_bc_lp:
    cmp bx, cx
    jge da_ret
    
    lodsb
    call print_hex_byte
    
    mov ah, 02h
    mov dl, ' '
    int 21h
    
    inc bx
    jmp da_bc_lp
    
da_ret:
    mov ah, 09h
    lea dx, msg_newline
    int 21h
    
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ax
    ret
debug_all ENDP

;================================================================
; PRINT_HEX_BYTE
;================================================================
print_hex_byte PROC
    push ax
    push cx
    push dx
    
    mov ah, al
    mov cl, 4
    shr al, cl
    
    cmp al, 10
    jb phb_d1
    add al, 'A' - 10
    jmp phb_p1
phb_d1:
    add al, '0'
phb_p1:
    mov dl, al
    push ax
    mov ah, 02h
    int 21h
    pop ax
    
    mov al, ah
    and al, 0Fh
    cmp al, 10
    jb phb_d2
    add al, 'A' - 10
    jmp phb_p2
phb_d2:
    add al, '0'
phb_p2:
    mov dl, al
    mov ah, 02h
    int 21h
    
    pop dx
    pop cx
    pop ax
    ret
print_hex_byte ENDP

;================================================================
END main
