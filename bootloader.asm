; bootloader.asm
[BITS 16]
[ORG 0x7C00]

; Bootloader code
START:
    ; Load Kernel from 0x1000
    mov ax, 0x1000        ; Set destination address
    mov ds, ax            ; DS = 0x1000
    mov es, ax            ; ES = 0x1000
    mov bx, 0x1000        ; Source address in the bootloader's memory

    ; Load Kernel into memory
    mov ah, 0x02          ; INT 13h - Read Sectors
    mov al, 1             ; Read 1 sector
    mov ch, 0             ; Cylinder 0
    mov cl, 2             ; Sector 2 (where the kernel starts)
    mov dh, 0             ; Head 0
    mov dl, 0x80          ; Drive 0x80 (First hard disk)
    int 0x13              ; Call BIOS

    ; Check for errors
    jc load_error         ; Jump to error handler if carry flag is set

    ; Jump to Kernel
    jmp 0x1000:0000      ; Jump to 0x1000:0000 where kernel is loaded

load_error:
    ; Error handling code
    mov ah, 0x0E          ; Teletype output function
    mov al, 'E'           ; Print 'E'
    int 0x10              ; Call BIOS
    hlt                  ; Halt CPU

; Fill the rest of the boot sector with zeros
times 510 - ($ - $$) db 0
dw 0xAA55               ; Boot sector signature
