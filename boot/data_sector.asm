; =============================================================================
; SynOS test data sector
; =============================================================================
;
; This file becomes sector 2 of the disk image. It holds data only, no code:
; the boot sector reads it into memory at 0x7e00 and prints the string below.
; Seeing that string on screen proves the disk read worked.
;
; It needs no [org] because nothing here is executed and no label addresses
; are used. It needs no 0xaa55 signature because only sector 1 (the boot
; sector) is checked by the BIOS.
;
; Build the two-sector disk image:
;   nasm -f bin boot/boot_sector.asm -o boot/boot_sector.bin
;   nasm -f bin boot/data_sector.asm -o boot/data_sector.bin
;   cat boot/boot_sector.bin boot/data_sector.bin > boot/synos.img
; =============================================================================

db 'Sector read success', 0  ; The string the boot sector prints; 13 = carriage return, 10 = line feed, 0 marks the end
times 512-($-$$) db 0        ; Pad with zeros to exactly 512 bytes: one full sector
