;      ____ ___ ____  _   _ _____ ____         
;    / ___|_ _|  _ \| | | | ____|  _ \        
;    | |    | || |_) | |_| |  _| | |_) |       
;    | |___ | ||  __/|  _  | |___|  _ <        
;     \____|___|_|   |_| |_|_____|_| \_\       
;                   ( _ )                      
;                   / _ \/\                    
;                  | (_>  <                    
; ____  _____ ____ _\___/\/  _   _ _____ ____  
;|  _ \| ____/ ___|_ _|  _ \| | | | ____|  _ \ 
;| | | |  _|| |    | || |_) | |_| |  _| | |_) |
;| |_| | |__| |___ | ||  __/|  _  | |___|  _ < 
;|____/|_____\____|___|_|   |_| |_|_____|_| \_\
;==============================================================================
;____  ____   ___   ____ ____      _    __  __ _____ ____  
;|  _ \|  _ \ / _ \ / ___|  _ \    / \  |  \/  | ____|  _ \ 
;| |_) | |_) | | | | |  _| |_) |  / _ \ | |\/| |  _| | | | |
;|  __/|  _ <| |_| | |_| |  _ <  / ___ \| |  | | |___| |_| |
;|_|   |_| \_\\___/ \____|_|_\_\/_/   \_\_|  |_|_____|____/ 
;                      | __ ) \ / /                         
;                      |  _ \\ V /                          
;                      | |_) || |                           
;                 _____|____/ |_|_ ____                     
;                |__  /  / \  |_ _|  _ \                    
;                  / /  / _ \  | || | | |                   
;                 / /_ / ___ \ | || |_| |                   
;           ___ _/____/_/___\_\___|____/   __               
;          |_ _| \ | |  ( _ ) / _ \ ( _ ) / /_              
;           | ||  \| |  / _ \| | | |/ _ \| '_ \             
;           | || |\  | | (_) | |_| | (_) | (_) |            
;          |___|_| \_|  \___/ \___/ \___/ \___/             

;==============================================================================
.MODEL SMALL
.STACK 100h

.DATA
    ; Welcome and Menu Messages
    welcome     DB 0Dh, 0Ah, '========================================', 0Dh, 0Ah
                DB '    CIPHER & DECIPHER SYSTEM', 0Dh, 0Ah
                DB '    8086 Assembly Language Project', 0Dh, 0Ah
                DB '========================================', 0Dh, 0Ah, '$'
    
    menu        DB 0Dh, 0Ah, 'SELECT AN ALGORITHM:', 0Dh, 0Ah
                DB '  [1] Caesar Cipher (Shift by 3)', 0Dh, 0Ah
                DB '  [2] Vigenere-style Cipher (Dual Key)', 0Dh, 0Ah
                DB '  [3] Stack-based Cipher (Reverse)', 0Dh, 0Ah
                DB '  [4] Exit Program', 0Dh, 0Ah
                DB 'Enter choice: $'
    
    operation   DB 0Dh, 0Ah, 'SELECT OPERATION:', 0Dh, 0Ah
                DB '  [C] Cipher (Encrypt)', 0Dh, 0Ah
                DB '  [D] Decipher (Decrypt)', 0Dh, 0Ah
                DB 'Enter choice: $'
    
    input_msg   DB 0Dh, 0Ah, 'Enter a text you want to ENCRYPT/DECRYPT: $'
    result_msg  DB 0Dh, 0Ah, 'Result: $'
    error_msg   DB 0Dh, 0Ah, 'Invalid choice! Try again.', 0Dh, 0Ah, '$'
    exit_msg    DB 0Dh, 0Ah, 'Thank you for using Cipher System!', 0Dh, 0Ah, '$'
    newline     DB 0Dh, 0Ah, '$'
    
    ; Data storage
    input_buf   DB 100 DUP('$')    ; Input buffer
    output_buf  DB 100 DUP('$')    ; Output buffer
    choice      DB ?                ; Menu choice
    op_choice   DB ?                ; Operation choice (C/D)
    
    ; Vigenere keys
    key1        DB 5                ; First key (shift by 5)
    key2        DB 7                ; Second key (shift by 7)

.CODE
MAIN PROC
    MOV AX, @DATA
    MOV DS, AX
    
    ; Display welcome screen
    LEA DX, welcome
    CALL PRINT_STRING
    
MENU_LOOP:
    ; Display menu
    LEA DX, menu
    CALL PRINT_STRING
    
    ; Get menu choice
    CALL GET_CHAR
    MOV choice, AL
    
    ; Print newline
    LEA DX, newline
    CALL PRINT_STRING
    
    ; Check choice
    CMP choice, '1'
    JE CAESAR_SELECTED
    CMP choice, '2'
    JE VIGENERE_SELECTED
    CMP choice, '3'
    JE STACK_SELECTED
    CMP choice, '4'
    JE EXIT_PROGRAM
    
    ; Invalid choice
    LEA DX, error_msg
    CALL PRINT_STRING
    JMP MENU_LOOP

CAESAR_SELECTED:
    CALL GET_OPERATION
    CALL GET_INPUT
    CALL CAESAR_CIPHER
    CALL DISPLAY_RESULT
    JMP MENU_LOOP

VIGENERE_SELECTED:
    CALL GET_OPERATION
    CALL GET_INPUT
    CALL VIGENERE_CIPHER
    CALL DISPLAY_RESULT
    JMP MENU_LOOP

STACK_SELECTED:
    CALL GET_OPERATION
    CALL GET_INPUT
    CALL STACK_CIPHER
    CALL DISPLAY_RESULT
    JMP MENU_LOOP

EXIT_PROGRAM:
    LEA DX, exit_msg
    CALL PRINT_STRING
    MOV AH, 4Ch
    INT 21h
    
MAIN ENDP

; ===== UTILITY PROCEDURES =====

PRINT_STRING PROC
    ; DX = address of string
    MOV AH, 09h
    INT 21h
    RET
PRINT_STRING ENDP

GET_CHAR PROC
    ; Returns character in AL
    MOV AH, 01h
    INT 21h
    RET
GET_CHAR ENDP

GET_OPERATION PROC
    LEA DX, operation
    CALL PRINT_STRING
    
    CALL GET_CHAR
    MOV op_choice, AL
    
    ; Convert to uppercase if lowercase
    CMP AL, 'c'
    JNE CHECK_D_LOWER
    MOV op_choice, 'C'
    JMP OP_DONE
    
CHECK_D_LOWER:
    CMP AL, 'd'
    JNE OP_DONE
    MOV op_choice, 'D'
    
OP_DONE:
    LEA DX, newline
    CALL PRINT_STRING
    RET
GET_OPERATION ENDP

GET_INPUT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    
    LEA DX, input_msg
    CALL PRINT_STRING
    
    ; Clear input buffer
    LEA SI, input_buf
    MOV CX, 100
CLEAR_INPUT:
    MOV BYTE PTR [SI], '$'
    INC SI
    LOOP CLEAR_INPUT
    
    ; Read input
    LEA SI, input_buf
    MOV CX, 0               ; Counter for characters
    
READ_LOOP:
    MOV AH, 01h
    INT 21h
    
    CMP AL, '$'             ; Check for terminator
    JE INPUT_DONE
    CMP AL, 0Dh             ; Check for Enter key
    JE INPUT_DONE
    
    MOV [SI], AL
    INC SI
    INC CX
    CMP CX, 99              ; Prevent buffer overflow
    JL READ_LOOP
    
INPUT_DONE:
    MOV BYTE PTR [SI], '$'  ; Null terminate
    
    POP SI
    POP CX
    POP BX
    POP AX
    RET
GET_INPUT ENDP

DISPLAY_RESULT PROC
    PUSH DX
    
    LEA DX, result_msg
    CALL PRINT_STRING
    
    LEA DX, output_buf
    CALL PRINT_STRING
    
    LEA DX, newline
    CALL PRINT_STRING
    
    POP DX
    RET
DISPLAY_RESULT ENDP

; ===== CAESAR CIPHER =====
CAESAR_CIPHER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    
    LEA SI, input_buf
    LEA DI, output_buf
    MOV CX, 0               ; Character counter
    
CAESAR_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
    JE CAESAR_DONE
    
    ; Check if uppercase letter
    CMP AL, 'A'
    JL CAESAR_NO_CHANGE
    CMP AL, 'Z'
    JLE CAESAR_UPPER
    
    ; Check if lowercase letter
    CMP AL, 'a'
    JL CAESAR_NO_CHANGE
    CMP AL, 'z'
    JLE CAESAR_LOWER
    
CAESAR_NO_CHANGE:
    MOV [DI], AL
    JMP CAESAR_NEXT

CAESAR_UPPER:
    SUB AL, 'A'             ; Convert to 0-25
    
    CMP op_choice, 'C'
    JE CAESAR_ENCRYPT_U
    
    ; Decrypt (shift -3)
    SUB AL, 3
    JGE CAESAR_U_DONE
    ADD AL, 26              ; Wrap around
    JMP CAESAR_U_DONE
    
CAESAR_ENCRYPT_U:
    ; Encrypt (shift +3)
    ADD AL, 3
    CMP AL, 26
    JL CAESAR_U_DONE
    SUB AL, 26              ; Wrap around
    
CAESAR_U_DONE:
    ADD AL, 'A'
    MOV [DI], AL
    JMP CAESAR_NEXT

CAESAR_LOWER:
    SUB AL, 'a'             ; Convert to 0-25
    
    CMP op_choice, 'C'
    JE CAESAR_ENCRYPT_L
    
    ; Decrypt (shift -3)
    SUB AL, 3
    JGE CAESAR_L_DONE
    ADD AL, 26              ; Wrap around
    JMP CAESAR_L_DONE
    
CAESAR_ENCRYPT_L:
    ; Encrypt (shift +3)
    ADD AL, 3
    CMP AL, 26
    JL CAESAR_L_DONE
    SUB AL, 26              ; Wrap around
    
CAESAR_L_DONE:
    ADD AL, 'a'
    MOV [DI], AL

CAESAR_NEXT:
    INC SI
    INC DI
    INC CX
    JMP CAESAR_LOOP

CAESAR_DONE:
    MOV BYTE PTR [DI], '$'
    
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
CAESAR_CIPHER ENDP

; ===== VIGENERE CIPHER =====
VIGENERE_CIPHER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    
    LEA SI, input_buf
    LEA DI, output_buf
    MOV CX, 0               ; Position counter (for even/odd)
    
VIG_LOOP:
    MOV AL, [SI]
    CMP AL, '$'
JNE VIG_CONTINUE
JMP VIG_DONE

VIG_CONTINUE:

    
    ; Check if letter
    CMP AL, 'A'
    JL VIG_NO_CHANGE
    CMP AL, 'Z'
    JLE VIG_UPPER
    CMP AL, 'a'
    JL VIG_NO_CHANGE
    CMP AL, 'z'
    JLE VIG_LOWER
    
VIG_NO_CHANGE:
    MOV [DI], AL
    JMP VIG_NEXT

VIG_UPPER:
    SUB AL, 'A'
    
    ; Determine key based on position (even=key1, odd=key2)
    MOV BL, CL
    AND BL, 1
    CMP BL, 0
    JE VIG_USE_KEY1_U
    
    ; Use key2
    MOV BL, key2
    JMP VIG_APPLY_KEY_U
    
VIG_USE_KEY1_U:
    MOV BL, key1
    
VIG_APPLY_KEY_U:
    CMP op_choice, 'C'
    JE VIG_ENCRYPT_U
    
    ; Decrypt
    SUB AL, BL
    JGE VIG_U_DONE
    ADD AL, 26
    JMP VIG_U_DONE
    
VIG_ENCRYPT_U:
    ADD AL, BL
    CMP AL, 26
    JL VIG_U_DONE
    SUB AL, 26
    
VIG_U_DONE:
    ADD AL, 'A'
    MOV [DI], AL
    JMP VIG_NEXT

VIG_LOWER:
    SUB AL, 'a'
    
    ; Determine key based on position
    MOV BL, CL
    AND BL, 1
    CMP BL, 0
    JE VIG_USE_KEY1_L
    
    MOV BL, key2
    JMP VIG_APPLY_KEY_L
    
VIG_USE_KEY1_L:
    MOV BL, key1
    
VIG_APPLY_KEY_L:
    CMP op_choice, 'C'
    JE VIG_ENCRYPT_L
    
    ; Decrypt
    SUB AL, BL
    JGE VIG_L_DONE
    ADD AL, 26
    JMP VIG_L_DONE
    
VIG_ENCRYPT_L:
    ADD AL, BL
    CMP AL, 26
    JL VIG_L_DONE
    SUB AL, 26
    
VIG_L_DONE:
    ADD AL, 'a'
    MOV [DI], AL

VIG_NEXT:
    INC SI
    INC DI
    INC CX
    JMP VIG_LOOP

VIG_DONE:
    MOV BYTE PTR [DI], '$'
    
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
VIGENERE_CIPHER ENDP

; ===== STACK CIPHER =====
STACK_CIPHER PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
    
    ; Count characters and push to stack
    LEA SI, input_buf
    MOV CX, 0
    
STACK_COUNT:
    MOV AL, [SI]
    CMP AL, '$'
    JE STACK_PUSH_START
    INC SI
    INC CX
    JMP STACK_COUNT
    
STACK_PUSH_START:
    ; Push all characters onto stack
    LEA SI, input_buf
    MOV BX, CX              ; Save count
    
STACK_PUSH_LOOP:
    CMP CX, 0
    JE STACK_POP_START
    MOV AL, [SI]
    PUSH AX                 ; Push character
    INC SI
    DEC CX
    JMP STACK_PUSH_LOOP
    
STACK_POP_START:
    ; Pop characters (reversed) and apply cipher
    LEA DI, output_buf
    MOV CX, BX              ; Restore count
    
STACK_POP_LOOP:
    CMP CX, 0
    JE STACK_DONE
    
    POP AX                  ; Pop character
    
    ; Apply simple XOR cipher with position
    MOV BL, CL
    AND BL, 0Fh             ; Use lower 4 bits as key
    
    CMP op_choice, 'C'
    JE STACK_XOR
    
    ; For decrypt, same XOR (symmetric)
STACK_XOR:
    XOR AL, BL
    
    MOV [DI], AL
    INC DI
    DEC CX
    JMP STACK_POP_LOOP
    
STACK_DONE:
    MOV BYTE PTR [DI], '$'
    
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
STACK_CIPHER ENDP

END MAIN

;==============================================================================
;
;           _____ _   _ ____                    
;          | ____| \ | |  _ \                   
;          |  _| |  \| | | | |                  
;          | |___| |\  | |_| |                  
;          |_____|_| \_|____/                   
;               / _ \|  ___|                    
;              | | | | |_                       
;              | |_| |  _|                      
; ____  ____   _\___/|_|_ ____      _    __  __ 
;|  _ \|  _ \ / _ \ / ___|  _ \    / \  |  \/  |
;| |_) | |_) | | | | |  _| |_) |  / _ \ | |\/| |
;|  __/|  _ <| |_| | |_| |  _ <  / ___ \| |  | |
;|_|   |_| \_\\___/ \____|_| \_\/_/   \_\_|  |_|
