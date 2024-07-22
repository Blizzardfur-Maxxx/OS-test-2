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

    ; Main loop
main_loop:
    ; Wait for key press
    mov ah, 0x00          ; BIOS keyboard interrupt (read key)
    int 0x16              ; AL = ASCII code, AH = scan code
    mov ah, 0x0E          ; BIOS Teletype function (print character)
    mov al, al            ; AL contains the ASCII code of the pressed key
    int 0x10              ; Print character
    jmp main_loop         ; Repeat

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
