; kernel.asm
[BITS 16]
[ORG 0x1000]

; Kernel code
START:
    ; Set up video mode and screen
    mov ah, 0x00
    mov al, 0x03          ; 80x25 Text mode
    int 0x10              ; BIOS Video Interrupt

    ; Print prompt
    mov si, prompt
    call print_string

    ; Initialize input buffer
    mov di, input_buffer
    mov byte [di], 0      ; Clear input buffer

    ; Main loop
main_loop:
    ; Wait for key press
    mov ah, 0x00          ; BIOS keyboard interrupt (read key)
    int 0x16              ; AL = ASCII code, AH = scan code
    mov ah, 0x0E          ; BIOS Teletype function (print character)
    mov bl, al            ; Save character for further use

    ; Handle Enter key
    cmp al, 0x0D          ; Enter key
    je process_input

    ; Handle Backspace key
    cmp al, 0x08          ; Backspace key
    je handle_backspace

    ; Store character in buffer and echo it
    mov [di], bl          ; Store character in buffer
    inc di                ; Move buffer pointer
    int 0x10              ; Print character
    jmp main_loop         ; Repeat

handle_backspace:
    ; Remove last character from buffer
    dec di                ; Move buffer pointer back
    mov ah, 0x0E          ; BIOS Teletype function (print character)
    mov al, ' '           ; Print space to erase character
    int 0x10              ; Print character
    mov al, 0x08          ; Move cursor back
    int 0x10              ; Print character
    jmp main_loop         ; Repeat

process_input:
    ; Null-terminate the input buffer
    mov byte [di], 0

    ; Print newline and carriage return before printing the command result
    mov al, 0x0A          ; Linefeed
    int 0x10              ; Print character
    mov al, 0x0D          ; Carriage return
    int 0x10              ; Print character

    ; Process the input command
    mov si, input_buffer  ; Point SI to the start of the input buffer
    call parse_command

    ; Clear the input buffer by resetting DI and using REP STOSB
    mov di, input_buffer
    mov cx, 128           ; Buffer size
    xor al, al            ; Clear value
    rep stosb             ; Fill buffer with zeros

    ; Print prompt on a new line after the command output
    mov al, 0x0A          ; Linefeed to move to a new line
    int 0x10              ; Print character
    mov al, 0x0D          ; Carriage return to move to the beginning of the line
    int 0x10              ; Print character
    mov si, prompt
    call print_string

    ; Reset buffer pointer
    mov di, input_buffer

    ; Continue loop
    jmp main_loop

parse_command:
    ; Compare input with known commands
    mov cx, 4            ; Length of "echo"
    mov di, input_buffer
    mov si, command_echo
    repe cmpsb
    je execute_echo

    mov cx, 3            ; Length of "cls"
    mov di, input_buffer
    mov si, command_cls
    repe cmpsb
    je execute_cls

    mov cx, 8            ; Length of "printmem"
    mov di, input_buffer
    mov si, command_printmem
    repe cmpsb
    je execute_printmem

    ; Handle unknown command
    mov si, newline      ; Newline for invalid command
    call print_string
    mov si, unknown_command
    call print_string
    mov si, newline      ; Newline for prompt
    call print_string
    ret

execute_echo:
    ; Print the rest of the input buffer
    mov si, input_buffer + 5  ; Skip "echo " (5 characters)
    call print_string

    ; Print newline after echo output
    mov al, 0x0A          ; Linefeed
    int 0x10              ; Print character
    mov al, 0x0D          ; Carriage return
    int 0x10              ; Print character

    ret

execute_cls:
    ; Clear screen (80x25 text mode)
    mov ah, 0x06          ; Scroll up function
    mov al, 0x00          ; Clear the entire screen
    mov bh, 0x07          ; Attribute (light gray on black)
    mov cx, 0x0000        ; Top left corner of screen
    mov dx, 0x184F        ; Bottom right corner of screen (80x25)
    int 0x10              ; BIOS Video Interrupt

    ; Move cursor to top-left corner
    mov ah, 0x02          ; Set cursor position function
    mov bh, 0x00          ; Page number
    mov dh, 0x00          ; Row (0-based)
    mov dl, 0x00          ; Column (0-based)
    int 0x10              ; BIOS Video Interrupt

    ret

execute_printmem:
    ; Print memory content from 0x1000 to 0x1100
    mov cx, 0x0100        ; Number of bytes to print (256 bytes)
    mov si, 0x1000        ; Start address
printmem_loop:
    push cx               ; Save CX
    call print_mem_address
    mov cl, [si]          ; Get byte from memory
    call print_hex_byte   ; Print byte as hex
    mov al, ' '           ; Space separator
    call print_char
    pop cx                ; Restore CX
    inc si                ; Next byte
    loop printmem_loop    ; Repeat for next byte

    ; Print newline after memory dump
    mov al, 0x0A          ; Linefeed
    int 0x10              ; Print character
    mov al, 0x0D          ; Carriage return
    int 0x10              ; Print character

    ret

print_mem_address:
    ; Print address in hexadecimal format
    mov ah, 0x0E          ; BIOS Teletype function
    ; Convert address to hexadecimal string and print
    ; Assumes address is in SI
    mov al, [si+1]        ; High byte of address
    call print_hex_nibble
    mov al, [si]          ; Low byte of address
    call print_hex_nibble
    ret

print_hex_byte:
    ; Print byte in hexadecimal format
    mov ah, 0x0E          ; BIOS Teletype function
    call print_hex_nibble  ; High nibble
    call print_hex_nibble  ; Low nibble
    ret

print_hex_nibble:
    ; Convert AL to hex and print
    and al, 0x0F          ; Mask to low nibble
    cmp al, 9
    jbe hex_digit
    add al, 'A' - 10      ; Convert to 'A'-'F'
    jmp done_hex_digit

hex_digit:
    add al, '0'           ; Convert to '0'-'9'

done_hex_digit:
    int 0x10              ; Print character
    ret

print_string:
    ; Print string pointed to by SI
print_char:
    lodsb                 ; Load byte at DS:SI into AL
    cmp al, 0             ; Check for null terminator
    je done_printing      ; If end of string, return
    mov ah, 0x0E          ; BIOS Teletype function
    int 0x10              ; Print character
    jmp print_char        ; Repeat for next character
done_printing:
    ret

prompt db 'MyOS> $'
input_buffer times 128 db 0  ; Buffer for user input
command_echo db 'echo', 0
command_cls db 'cls', 0
command_printmem db 'printmem', 0
unknown_command db 'Invalid command', 0
newline db 0x0A, 0x0D, 0
