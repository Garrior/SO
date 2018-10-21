global proberen
global verhogen
global proberen_time

extern get_os_time

section .text

;edi wskaznik na semafor
;esi value
;r8d -value
proberen:	
        xor r8d, r8d    ;zerowanie
	sub r8d, esi    ;-value
proberen_loop:
        cmp [edi], esi  
	jl proberen_loop    ;aktywne oczekiwanie
	lock add [edi], r8d ;proba atomicznego zmniejszenia semafora
	cmp [edi], dword 0  ;sem == 0?
	jge proberen_exit   ;proba sie powiodla
	lock add [edi], esi ;proba sie nie powiodla, zwracam to co zabralem
	jmp proberen
proberen_exit:
    ret

;edi wskaznik na semafor
;esi value
verhogen:
    lock add [edi], esi
    ret

;rbx czas przed wywolaniem proberen
;rax wynik
proberen_time:
 push rbx       
 push rdi    ;wrzucam rdi i rsi na stos, zeby uniknac jego modyfikacji przez get_os_time
 push rsi
 call get_os_time
 mov rbx, RAX
 pop rsi
 pop rdi
 call proberen
 call get_os_time
 sub RAX, rbx
 pop rbx     ;przywracam rbx do wartosci poczatkowej
 ret


