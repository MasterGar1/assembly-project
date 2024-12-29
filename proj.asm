masm
model	small
stack	256
.data
; Заделяме буфер за съобщението
handle	  dw 0 
message    db 200 dup ('$')
len_mes = $ - message
point_mes dd message
read_len  dw 0

; Обичайните неща за файлове ;)
filename	db	'crypt.txt', 0
point_fname	dd	filename

; Ключ за алгоритъм 3. Дълъг е 200 символа
super_secret_encoding_key_that_you_definitely_cannot_see_because_it_is_now_off_screen db 'A9Fj#k2X7z&3dN5y8L1pQb0WmR6@t%I*4Z!VoC^hUo+9J3wTzL2SxP8Q1M0G5V@rN3uYbF!K7WzF9XqDkJ0g3^B2otE6Z$*R5n1Yv8CqL2Tj7Hw+pI0x@3s+Y9oX4KQzU5FmB6P@W3dQ1A%J7R2TzL*o8M9V0G6bNwC3hZ!5tXyWmP7j8LkQf3Z1Y5@t9V0I7J6P+L2b'


; Пазим колко сме криптирали
current_encryption db 0
; Съобщения за потребителя
info 		  db "Please use 1 to encrypt or 2 to decrypt! Type 0 to exit!$"
invalid_input db "Illegal command.$"
enc_error     db "Can't encrypt further!$"
dec_error     db "Can't decrypt further!$"
enc_lvl       db "Current Encryption level is $"
end_prog      db "Program halted! $"
head_message  db "Message: $"
read_error    db "Error while reading file!$"
write_error   db "Error while writing file!$"
empty_error   db "File can't be empty!$"
sep           db "---------------------------------------------------------$"
.code
main:
	mov	ax, @data
	mov	ds, ax
	xor ax, ax
	call read_message
	call input_parser
	jmp exit

; --- Algorithm 1 ---
; Разместваме буквите в съобщението по следния начин:
; ecs(message[i]) = message[l >> 1 + l % 2 + i],
; където l = len(message), 0 <= i <= l >> 1
; Лесно се вижда, че ecs(ecs(message[i])) = message[i]
; Note: Името идва от това, че бутаме началото в средата
enc_mid_shuffle proc
	xor si, si
	xor di, di
	mov cx, read_len
	shr cx, 1
	mov di, cx
	jnc ecs
	inc di
	ecs:
		mov dl, message[si]
		mov dh, message[di]
		mov message[si], dh
		mov message[di], dl
		xor dx, dx
		inc si
		inc di
	loop ecs
	ret
enc_mid_shuffle endp

dec_mid_shuffle proc
	call enc_mid_shuffle
	ret
dec_mid_shuffle endp

; --- Algorithm 2 ---
; Обхождаме съобщението, сменяйки всеки символ по следния начин:
;                   | message[i] + 7, ако message[i] e четно
; emc(message[i]) = |                                         ,
;                   | message[i] - 7, иначе
; където 0 <= i < len(message)
; Нека забележим, че emc(emc(message[i])) = message[i], защото:
; Ако 'б.о.о.' message[i] четно
; => emc(emc(message[i])) = emc(message[i] + 7) = ...
; Но message[i] + 7 e нечетно (нечетно + четно = нечетно)
; => ... = (message[i] + 7) - 7 = message[i]
; Note: Името идва от това, че алгоритъма е близък до
; шифър на Цезър, само че с малко странности...
enc_odd_caesar proc
	xor si, si
	mov cx, read_len

	emc:
		xor ax, ax
		mov al, message[si]
		mov dl, al
		and dl, 1
		jz ev
		add al, 7
		jmp nxt
		ev:
		sub al, 7
		nxt:
		; ax mod 256 - magic
		and ax, 0FFh
		mov message[si], al
		inc si
	loop emc
	ret
enc_odd_caesar endp

dec_odd_caesar proc
	call enc_odd_caesar
	ret
dec_odd_caesar endp

; --- Algorithm 3 ---
; В този алгоритъм използваме ключ с прекалено дълго име така, че нека положим key = super_secret_...
; Ключа е дълъг 200 символа, защото това е максималната дължина на message.
; Обхождаме низа като заменяме message[i] със следната функция:
; ekd(message[i]) = (256 + key[i] - message[i]) % 256,
; като 0 <= i < len(message)
; Да забележим, че ekd(ekd(message[i])) = message[i]!
; Ще покажем това с няколко преобразувания:
; 'б.о.о.' нека key[i] - message[i] > 0 (в другия случай е аналогично)
; => (256 + key[i] - message[i]) % 256 = key[i] - message[i]
; => ekd(ekd(message[i])) = ekd(key[i] - message[i]) =
; = (256 + key[i] - key[i] + message[i]) % 256 = message[i]
; И така виждаме, че ekd(ekd(message[i])) = message[i] :)
; Note: Името е тривиално следствие от това, което прави алгоритъма
enc_key_diff proc
	xor si, si
	xor dx, dx
	mov cx, read_len
	ekd:
		mov ax, 0FFh
		mov dl, super_secret_encoding_key_that_you_definitely_cannot_see_because_it_is_now_off_screen[si]
		add ax, dx
		mov dl, message[si]
		sub ax, dx
		and ax, 0FFh
		mov message[si], al
		inc si
	loop ekd
	ret
enc_key_diff endp

dec_key_diff proc
	call enc_key_diff
	ret
dec_key_diff endp

; Четец
read_message proc
	; open file
	mov	al, 02h 
	lds	dx, point_fname 
	mov	ah, 3dh 
	int	21h
	jc rd_err
	mov handle, ax
	; read file
	mov bx, handle
	mov ah, 3fh
	mov cx, len_mes
	lds dx, point_mes
	int 21h
	jc rd_err
	; calculate read message length
	mov read_len, ax
	cmp ax, 0
	je ety_err
	; close file
	mov bx, handle
	mov ah, 3eh
	int 21h
	jc rd_err
	ret
	rd_err:
	mov ah, 09h
    lea dx, read_error
    int 21h
	jmp exit
	ret
	ety_err:
	mov ah, 09h
    lea dx, empty_error
    int 21h
	jmp exit
	ret
read_message endp
	
; Писец
write_message proc
	call print_message
	; create file - we want to erase the previous one if there is such
	xor	cx, cx
	lds	dx, point_fname
	mov	ah, 3Ch
	int	21h
	jc wr_err
	; open file
	mov	al, 02h 
	lds	dx, point_fname 
	mov	ah, 3Dh 
	int	21h
	jc wr_err
	mov handle, ax
	; write to file
	mov	bx, handle 
	mov	cx, read_len
	lds	dx, point_mes
	mov	ah, 40h 
	int	21h
	jc wr_err
	; close file
	mov bx, handle
	mov ah, 3Eh
	int 21h
	jc wr_err
	ret
	wr_err:
	mov ah, 09h
    lea dx, write_error
    int 21h
	jmp exit
	ret
write_message endp

; Входен четец
input_parser proc
	begin:
	; Окраса
	call new_line
	mov ah, 09h
	lea dx, info
	int 21h
	call new_line
	mov ah, 02h
	mov dl, '>'
	int 21h
	; Четене
	mov ah, 01h
	int 21h
	; Изход
	ext:
	cmp al, 30h
	je end_program
	; Криптиране
	encr:
	cmp al, 31h
	jne decr
	call encrypt
	jmp begin
	; Декриптиране
	decr:
	cmp al, 32h
	jne inval
	call decrypt
	jmp begin
	inval:
	call new_line
	mov ah, 09h
	lea dx, invalid_input
	int 21h
	jmp begin

	end_program:
	call new_line
	mov ah, 09h
	lea dx, end_prog
	int 21h
	ret
input_parser endp

; Нов ред
new_line proc
	mov ah, 02h
    mov dl, 0Dh
    int 21h

    mov dl, 0Ah
    int 21h
    ret
new_line endp

; Разделител
seperate proc
	call new_line
	mov ah, 09h
	lea dx, sep
	int 21h
	ret
seperate endp

; Принтер
print_message proc
	call new_line
	mov ah, 09h
	lea dx, head_message
	int 21h
	mov ah, 09h
	lea dx, message
	int 21h
	ret
print_message endp

print_enc_level proc
	call new_line
	mov ah, 09h
	lea dx, enc_lvl
	int 21h
	mov ah, 02h
	mov dl, current_encryption
	add dl, 30h
	int 21h
	ret
print_enc_level endp

encrypt proc
	mov bl, current_encryption
	inc bl
	ealg1:
	cmp bl, 1
	jne ealg2
	call enc_mid_shuffle
	jmp enc_end
	ealg2:
	cmp bl, 2
	jne ealg3
	call enc_odd_caesar
	jmp enc_end
	ealg3:
	cmp bl, 3
	jne enc_err
	call enc_key_diff
	jmp enc_end
	enc_err:
	call new_line
	mov ah, 09h
	lea dx, enc_error
	int 21h
	jmp enc_ext
	enc_end:
	mov current_encryption, bl
	call seperate
	call print_enc_level
	call write_message
	call seperate
	enc_ext:
	ret
encrypt endp

decrypt proc
	mov bl, current_encryption
	dalg1:
	cmp bl, 1
	jne dalg2
	call dec_mid_shuffle
	jmp dec_end
	dalg2:
	cmp bl, 2
	jne dalg3
	call dec_odd_caesar
	jmp dec_end
	dalg3:
	cmp bl, 3
	jne dec_err
	call dec_key_diff
	jmp dec_end
	dec_err:
	call new_line
	mov ah, 09h
	lea dx, dec_error
	int 21h
	jmp dec_ext
	dec_end:
	dec bl
	mov current_encryption, bl
	call seperate
	call print_enc_level
	call write_message
	call seperate
	dec_ext:
	ret
decrypt endp
	
exit:
	mov	ax,4c00h	
	int	21h
end main
