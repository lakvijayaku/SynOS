; =============================================================================
; SynOS loader
; =============================================================================
;
; The boot sector reads this file (sectors 2-3 of the boot disk) into memory
; at 0x7e00 and jumps here. Unlike the boot sector, the loader is not limited
; to 512 bytes, so the rest of the boot process will grow here.
;
; What the loader does, in order:
;   1. Saves the boot drive number passed in DL.
;   2. Prints a message stored in its second sector; seeing it proves both
;      sectors were loaded, not just the first.
;   3. Halts the CPU.
;
; Expects (set up by the boot sector, not repeated here):
;   CS = DS = ES = SS = 0, a valid stack below 0x7c00, DL = boot drive
;
; Labels do not cross files: this file is assembled separately from
; boot_sector.asm, so it needs its own print_string and halt loop.
;
; Size: exactly 2 sectors (1024 bytes). The boot sector's sector count
; (AL before int 0x13) must match this.
; =============================================================================

[bits 16]                       ; Assemble 16-bit instructions: the CPU is still in real mode
[org 0x7e00]                    ; The boot sector loads this file at 0x7e00, so labels are counted from there

start:
    mov [boot_drive], dl        ; Save the boot drive number handed over in DL before anything overwrites it
    mov bh, 0                   ; Display page 0 for BIOS teletype output (set here rather than trusting the boot sector's value)
    mov si, task_outcome        ; SI = address of the message, which lives in the second sector of this file
    call print_string           ; Print it
    jmp halt_system             ; Nothing left to do yet

; -----------------------------------------------------------------------------
; halt_system: stop the CPU permanently
; -----------------------------------------------------------------------------
halt_system:
    cli                         ; Disable hardware interrupts so they cannot wake the CPU

.halt:
    hlt                         ; Halt the CPU until the next interrupt
    jmp .halt                   ; A non-maskable interrupt (NMI) can still wake the CPU, so halt again


; -----------------------------------------------------------------------------
; print_string: print a zero-terminated string using BIOS teletype output
; Input:    SI = address of the first character; BH = display page (0)
; Modifies: AX, SI
; -----------------------------------------------------------------------------
print_string:
    mov al, [si]                ; Load the byte at address SI into AL
    inc si                      ; Advance SI to the next character

    cmp al, 0                   ; Zero terminator = end of string
    je .done

    mov ah, 0x0e                ; BIOS video function 0x0e: Teletype Output (prints AL)
    int 0x10                    ; Call BIOS video services
    jmp print_string            ; Repeat for the next character

.done:
    ret                         ; Return to the caller

; -----------------------------------------------------------------------------
; Data
; -----------------------------------------------------------------------------
boot_drive: db 0                ; Boot drive number, saved from DL on entry

times 512-($-$$) db 0           ; Pad to the end of sector 1 (byte 512), so the message below starts in sector 2

task_outcome: db 'Successfully stored DL and read from two sectors', 13, 10, 0   ; Stored in sector 2: printing it proves sector 2 was loaded

times 1024-($-$$) db 0          ; Pad to exactly 1024 bytes (2 sectors); $-$$ counts from the start of the file, not the sector
