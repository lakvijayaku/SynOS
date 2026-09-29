; =============================================================================
; SynOS boot sector
; =============================================================================
;
; When an x86 PC powers on, the BIOS (the firmware built into the motherboard)
; copies the first 512-byte sector of the boot disk into memory at address
; 0x7c00 and jumps to it. At that moment the CPU is in 16-bit "real mode", and
; this file is the very first SynOS code that runs.
;
; What this boot sector does, in order:
;   1. Sets the segment registers and stack to known values, because the BIOS
;      makes no promises about what they contain.
;   2. Saves the boot drive number the BIOS passes in DL.
;   3. Clears the screen and prints a status message.
;   4. Reads the loader (sectors 2-3 of the boot disk) into memory at 0x7e00,
;      right after this boot sector.
;   5. Jumps to the loader, passing the boot drive in DL, or prints 'E' and
;      halts if the read failed.
;   6. Halt loop: used only on the error path; on success the loader never
;      returns here.
;
; Real-mode memory map (the parts that matter here):
;   0x00000 - 0x004ff   Interrupt Vector Table and BIOS data - never overwrite
;   0x00500 - 0x07bff   Free; the stack grows down through here from 0x7c00
;   0x07c00 - 0x07dff   This boot sector (512 bytes)
;   0x07e00 - 0x081ff   The loader (2 sectors), loaded by this code
;
; Real-mode addressing: physical address = segment * 16 + offset.
; Every memory access ([...]) uses a segment register, usually DS.
; =============================================================================

[org 0x7c00]                    ; Tell the assembler this code will be loaded at 0x7c00, so every label gets an address counted from there

start:
    jmp 0x0000:main             ; Far jump: sets CS (Code Segment) to 0 and IP (Instruction Pointer) to main; some BIOSes start us at 0x07c0:0x0000, which is the same byte but breaks our labels, which assume CS = 0

; -----------------------------------------------------------------------------
; Step 1 and 2: build a known execution environment
; -----------------------------------------------------------------------------
main:
    cli                         ; Disable hardware interrupts: an interrupt during setup would use a half-built stack
    cld                         ; Clear the direction flag so string instructions move forward through memory (increasing addresses)

    xor ax, ax                  ; Set AX (Accumulator) to 0; XOR-ing a register with itself always gives 0
    mov ds, ax                  ; Copy AX into DS (Data Segment); segment registers cannot be loaded with a number directly, only from another register
    mov [boot_drive], dl        ; Save the boot drive number (passed by the BIOS in DL) into memory; this must come after DS = 0, or the byte lands at the wrong address
    mov es, ax                  ; Copy AX into ES (Extra Segment); int 0x13 uses ES:BX as the address to load the sector to
    mov ss, ax                  ; Copy AX into SS (Stack Segment)
    mov bh, al                  ; Set BH (the high byte of BX) to 0: the display page that BIOS teletype output prints to
    mov sp, 0x7c00              ; Set SP (Stack Pointer) to 0x7c00; the stack grows downward, into free memory below this code

    sti                         ; Re-enable hardware interrupts now that the stack is valid

; -----------------------------------------------------------------------------
; Step 3: clear the screen and print the status message
; -----------------------------------------------------------------------------
    mov ah, 0x00                ; BIOS video function 0x00: Set Video Mode (AH, the high byte of AX, selects the function)
    mov al, 0x03                ; Mode 0x03: 80x25 color text mode; setting a mode also clears the screen
    int 0x10                    ; Call BIOS video services (interrupt 0x10)

    mov si, task_outcome        ; SI (Source Index) = the ADDRESS of the message (no brackets: we want the address, not the bytes stored there)
    call print_string           ; Push the return address onto the stack and jump to print_string; its ret brings us back to the next line

; -----------------------------------------------------------------------------
; Step 4: read the loader into memory with BIOS disk service int 0x13, AH = 0x02
; -----------------------------------------------------------------------------
    mov ah, 0x02                ; BIOS disk function 0x02: Read Sectors
    mov al, 2                   ; Number of sectors to read: the loader's size (1024 bytes = 2 sectors); must match the padding in loader.asm
    mov ch, 0                   ; Cylinder 0
    mov cl, 2                   ; Start at sector 2 (CHS sector numbers start at 1; sector 1 is this boot sector)
    mov dh, 0                   ; Head 0
    mov bx, 0x7e00              ; ES:BX = 0x0000:0x7e00 is where the sector goes, directly after this boot sector; BX must not change until int 0x13 returns
    int 0x13                    ; Call BIOS disk services; on failure it sets the carry flag (CF)
    mov bh, 0                   ; BX is no longer needed as the buffer address, so set BH back to display page 0 for printing; mov does not change flags, so CF survives for jc

; -----------------------------------------------------------------------------
; Step 5: report the result
; -----------------------------------------------------------------------------
    jc disk_error               ; Jump if Carry: CF = 1 means the read failed
    mov dl, [boot_drive]        ; Pass the boot drive to the loader in DL; int 0x13 does not promise to preserve DL, so reload it from memory
    jmp 0x7e00                  ; Hand control to the loader; a near jmp changes only IP, so CS stays 0
; -----------------------------------------------------------------------------
; Step 6: stop the CPU
; -----------------------------------------------------------------------------
halt_system:
    cli                         ; Disable hardware interrupts so they cannot wake the CPU

.halt:                          ; Local label (belongs to halt_system) marking the halt loop
    hlt                         ; Halt the CPU until the next interrupt
    jmp .halt                   ; A non-maskable interrupt (NMI) can still wake the CPU, so jump back and halt again

; -----------------------------------------------------------------------------
; print_string: print a zero-terminated string using BIOS teletype output
; Input:    SI = address of the first character; BH = display page (0)
; Modifies: AX, SI
; Placed after the halt loop so the CPU can only reach it through call.
; -----------------------------------------------------------------------------
print_string:
    mov al, [si]                ; Load the byte at address SI into AL (the low byte of AX)
    inc si                      ; Advance SI to the next character

    cmp al, 0                   ; Check for the zero terminator that marks the end of the string (cmp sets the Zero Flag if equal)
    je .done                    ; Jump if Equal (Zero Flag set): the string is finished

    mov ah, 0x0e                ; BIOS video function 0x0e: Teletype Output (prints the character in AL and advances the cursor)
    int 0x10                    ; Call BIOS video services to print the character
    jmp print_string            ; Repeat for the next character

.done:
    ret                         ; Pop the return address pushed by call and jump back to the caller

; -----------------------------------------------------------------------------
; disk_error: print 'E' and halt; reached only through jc after a failed read
; -----------------------------------------------------------------------------
disk_error:
    mov ax, 0x0e45              ; One 16-bit move sets both halves of AX: AH = 0x0e (Teletype Output) and AL = 0x45 (ASCII 'E')
    int 0x10                    ; Print the 'E'
    jmp halt_system             ; Stop the CPU

; -----------------------------------------------------------------------------
; Data: bytes, not instructions; the CPU must never run into this region
; -----------------------------------------------------------------------------
boot_drive: db 0                ; Boot drive number, saved from DL at startup (for example 0x80 = first hard disk)
task_outcome: db 'Established a good execution environment after BIOS handed over control', 13, 10, 0   ; db = define bytes; 13, 10 = carriage return + line feed (move to the start of the next line); 0 marks the end of the string

times 510-($-$$) db 0           ; Pad with zeros up to byte 510; $ is the current address, $$ is the start of this section
dw 0xaa55                       ; Boot signature in bytes 510-511 (stored little-endian as 0x55, 0xaa); the BIOS only boots sectors that end with it
