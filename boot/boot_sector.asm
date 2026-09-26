; SynOS boot sector
;
; The BIOS loads the first 512-byte sector of the boot disk into memory at
; address 0x7c00 and jumps to it. This code sets up a known execution
; environment, prints a status message, and halts the CPU.

[org 0x7c00]                    ; Tell the assembler this code will be loaded at address 0x7c00, so labels resolve to the correct addresses

start:
    jmp 0x0000:main             ; Far jump (segment:offset): sets CS (Code Segment) to 0x0000 and IP (Instruction Pointer) to main, since some BIOSes enter with CS:IP = 0x07c0:0x0000 instead

main:
    cli                         ; Disable hardware interrupts while the segment registers and stack are being set up
    cld                         ; Clear the direction flag so string instructions move forward through memory (increasing addresses)

    xor ax, ax                  ; Set AX (Accumulator) to 0; XOR-ing a register with itself is the standard way to zero it
    mov ds, ax                  ; Copy AX into DS (Data Segment); segment registers cannot be loaded with an immediate value directly
    mov es, ax                  ; Copy AX into ES (Extra Segment)
    mov ss, ax                  ; Copy AX into SS (Stack Segment)
    mov bh, al                  ; Set BH (the high byte of BX) to 0: the display page that BIOS function 0x0e prints to
    mov sp, 0x7c00              ; Set SP (Stack Pointer) to 0x7c00; the stack grows downward, into free memory below this code

    sti                         ; Re-enable hardware interrupts now that the stack is valid

    mov ah, 0x00                ; BIOS video function 0x00: Set Video Mode (AH is the high byte of AX)
    mov al, 0x03                ; Mode 0x03: 80x25 color text mode; setting a mode also clears the screen
    int 0x10                    ; Call BIOS video services (interrupt 0x10)

    mov si, task_outcome        ; Load the address of the zero-terminated message into SI (Source Index)

print_loop:
    mov al, [si]                ; Load the byte at address SI into AL (the low byte of AX)
    inc si                      ; Advance SI to the next character

    cmp al, 0                   ; Check for the zero terminator that marks the end of the string
    je halt_system              ; If found, stop printing

    mov ah, 0x0e                ; BIOS video function 0x0e: Teletype Output (prints the character in AL and advances the cursor)
    int 0x10                    ; Call BIOS video services to print the character

    jmp print_loop              ; Repeat for the next character

halt_system:
    cli                         ; Disable hardware interrupts so they cannot wake the CPU

.halt:                          ; Local label (belongs to halt_system) marking the halt loop
    hlt                         ; Halt the CPU until the next interrupt
    jmp .halt                   ; A non-maskable interrupt (NMI) can still wake the CPU, so jump back and halt again

task_outcome: db 'Established a good execution environment after BIOS handed over control', 0

times 510-($-$$) db 0           ; Pad with zeros up to byte 510; $ is the current address, $$ is the start of this section
dw 0xaa55                       ; Boot signature in bytes 510-511 (stored little-endian as 0x55, 0xaa); the BIOS only boots sectors that end with it
