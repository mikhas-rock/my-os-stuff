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
	mov sp, main ; align the top of the stack to before the bootloader address
	cld
	sti

	int 0x13 ; Reset disks;  ax must be 0 (that have been set in a couple of instructions before)
	
	mov si, MESSAGE
	call println
	mov dx, 0x1234
	call printh
	
	mov dx, 0xCE0F
	call printh
	
	mov dx, 0x0001
	call printh
	
	call sleep
	call sleep
	call sleep
	call shutdown

	jmp $

; Write String to console then goes to the next line
; SI - String Stream to write
println:
	; Printing a character
	; http://www.ctyme.com/intr/rb-0106.htm
	push ax
	call print
	mov ah, 0x0e ; Teletype Output
	mov al, 0x0d ; CR
	int 0x10 ; Video Services
	mov al, 0x0a ; LF
	int 0x10 ; Video Services
	pop ax
	ret

; Write String to console
; SI - String Stream to write
print:
	; Printing a character
	; http://www.ctyme.com/intr/rb-0106.htm
	push ax
	mov ah, 0x0e ; Teletype Output
	.charLoop:
		lodsb ; Load address on SI to AL and increment SI
		or al, al ; Checking end of string as marked by a 0
		je .return ; Reach the end of the string		
		int 0x10 ; Video Services
		jmp .charLoop
	.return:
		pop ax
		ret
		
; Write an Hexadecimal string to the console
; DX - The Value to be printed
printh:
	pusha
	mov ah, 0x0e ; Teletype Output
	mov al, "0"
	int 0x10
	mov al, "x"
	int 0x10
	
	mov cx, 16
	.charLoop:
		sub cx, 4
		mov bx, dx
		shr bx, cl
		and bx, 0x000f	
		mov al, [bx + HEX_CHAR_TABLE]
		int 0x10 ; Video Services
		or cx, cx
		jne .charLoop
	
	mov al, 0x0d ; CR
	int 0x10 ; Video Services
	mov al, 0x0a ; LF
	int 0x10 ; Video Services
	popa
	ret
	
HEX_CHAR_TABLE db "0123456789ABCDEF"
	
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
