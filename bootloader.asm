[ORG 0x7C00]
[BITS 16]

section .text
global main

main:	
	cli
	jmp 0x0000:AlignSegments ; make sure BIOS put our bootloader in the corret segment	
; Align all segment pointers to 0
AlignSegments:
	xor ax, ax ; zero AX
	mov ss, ax
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov sp, main
	cld
	sti

	int 0x13
	
	mov si, MESSAGE
	call println
	call sleep
	call sleep
	call sleep
	call sleep
	call sleep
	call shutdown

	jmp $

; Write String to console then goes to the next line
; SI - String Stream to write
println:
	push ax
	call print
	mov al, 0x0d ; CR
	call printChar
	mov al, 0x0a ; LF
	call printChar
	pop ax
	ret

; Write String to console
; SI - String Stream to write
print:
	push ax
	.charLoop:
		mov al, [si] ; Setting the char to print on AL
		cmp al, 0 ; Checking end of string as marked by a 0
		je .return ; Reach the end of the string
		call printChar ; Print char at AL
		add si, 1 ; Increase the pointer to get the next char
		jmp .charLoop
	.return:
		pop ax
		ret

; AL - Char to print
printChar:
	push ax
	; Printing a character
	; http://www.ctyme.com/intr/rb-0106.htm
	mov ah, 0x0e ; Teletype Output
	int 0x10 ; Video Services
	pop ax
	ret

; Sleeps for AL * 0.1 second
; AL - 10ths of seconds to sleel
sleep:
	pusha
	mov ah, 0x86 ; Sleep
	mov cx, 0x0001
	mov dx, 0x86a0
	int 0x15
	popa
	ret
	
shutdown:
	; Getting APM Instalation Information
	; http://www.ctyme.com/intr/rb-1394.htm
	mov ax, 0x5300 ; Installation Check
	xor bx, bx ; Device ID = BIOS
	int 0x15
	cmp ax, 0000_0001_0000_0010b ;APM Version 1.2
	jne busyLoop
	mov ax, 0x5307 ;Advanced Power Management
	mov bx, 0x0001 ;Device = All BIOS managed devices
	mov cx, 0x0003 ;State = OFF
	int 0x15
	
	
busyLoop:
	jmp $

MESSAGE db "MY BOOT LOADER", 0
		
;padding
times 510 - ($ - $$) db 0
;magic number
dw 0xAA55
;here we have the 512 bootloader bytes
