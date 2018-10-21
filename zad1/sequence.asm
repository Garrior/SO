
section .data
    buffer_size equ 4096
 
section .bss
    permutation_size resb 8
    fd resb 8
    buffer resb 4096
    pattern resb 256
    bytes_read resb 64
    number resb 64
 
section .text
    global _start

_start:
    mov BYTE [number], 1
    pop rax ; get the number of program arguments
    cmp rax, 2 ; check if the number of arguments is equal to 2
    jne _failexit ; exit if not equal
    call _openfile
    mov RCX, 0
    call _fill_pattern
    mov RCX, 1
    call _succdata
    call _setup
    call _read_permutation
    call _closefile
_exit:
    cmp BYTE [number], 0
    jne _failexit
    mov rax, 60
    mov rdi, 0
    syscall

_fill_pattern:
    cmp RCX, 256
    je _fill_pattern_end
    mov BYTE [pattern + RCX], 0
    inc RCX
    jmp _fill_pattern
_fill_pattern_end:
    ret

;R8 - number that should be inside if number was in last permutation
;R10 - number to set in the next permutation
;R9 - buffer index
;RAX - number of bytes read
;R12 - number of bytes read during in the current block
;R13 - flag register for setup
_read_permutation:
    cmp R9, [bytes_read]; check if all of the bytes are already read
    jge _call_succdata; jump to read another batch
    movzx RCX, BYTE [buffer + R9]; load another value to cl
    mov [number], RCX
    cmp RCX, 0; check if the block has ended
    je _endblock
    inc R12
    cmp BYTE [pattern + RCX], R8B; check if that number occured in the last permutation
    jne _failexit
    mov BYTE [pattern + RCX], R10B; change the number of ocurrencies 
    inc R9
    jmp _read_permutation

_call_succdata:
    call _succdata
    jmp _read_permutation

_setup: 
    mov R15, 0
    mov R8B, 0
    mov R12, 0
    mov R10B, 1
    mov R13, 1
    jmp _read_permutation
_after_call:
    mov [permutation_size], R12
    mov R8B, 1
    mov R10B, 2
    mov R12, 0
    ret

_endblock:
    mov R11B, R8B
    mov R8B, R10B
    mov R10B, R11B
    inc R9
    cmp R13, 1
    je _back_to_setup
    cmp R12, [permutation_size]
    jne _failexit
    mov R12, 0
    jmp _read_permutation    
_back_to_setup:
    mov R13, 0
    jmp _after_call

_failexit:
    mov rax, 60
    mov rdi, 1
    syscall

_succdata:
    mov rax, 0
    mov rdi, [fd]
    mov rsi, buffer
    mov rdx, buffer_size
    syscall
    mov rdx, 0
    cmp rdx, rax
    jg _failexit
    je _exitsucc
    mov [bytes_read], RAX
    mov R9, 0
    ret
_exitsucc:
    cmp BYTE [number], 0
    jne _failexit
    jmp _exit

_openfile:

    mov rax, 2
    mov rdi, [rsp+16]
    mov rsi, 2
    mov rdx, 0x0777
    syscall
    mov rdx, 0
    cmp rdx, rax
    jg _failexit
    mov [fd], al
    ret 

_closefile:
    mov rax, 3
    mov rdi, [fd]
    syscall
    mov rdx, 0
    cmp rdx, rax
    jg _failexit
    ret
