%include "asm_io.inc"

segment .data
c_num1 db "12345", 0
c_num2 db "123", 0
num1   times  200 db 0
num2   times  200 db 0
result times  400 db 0
len1   dd 0
len2   dd 0
segment .text
    global asm_main
asm_main:
    enter   0,0               ; setup routine
    pusha

    mov ebx, c_num1
    call strlen
    mov [len1], ecx

    mov ebx, c_num2
    call strlen
    mov [len2], ecx
    
    push c_num1
    push num1
    push dword [len1]
    call convert
    pop eax
    pop eax
    pop eax

    push c_num2
    push num2
    push dword [len2]
    call convert
    pop eax
    pop eax
    pop eax

;   for(int i=0; i<len1; ++i) {
;        for(int j=0; j<len2; ++j) {
;           result[i+j] += num1[i] * num2[j];
;            result[i+j+1] += result[i+j] / 10;
;            result[i+j] %= 10;
;        }
;   }

    mov esi, 0
outerloop:
    cmp esi, [len1]
    je end_outer_loop
    mov edi, 0
innerloop:
    cmp edi, [len2]
    je end_inner_loop
    
    ; num1[i] * num2[j]
    xor eax, eax
    mov al, [num1+esi]
    mul byte [num2+edi]

    ; result[i+j]
    mov ebx, esi
    add ebx, edi
    xor edx, edx
    mov dl, [result+ebx]

    ; +=
    add dl, al
    mov [result+ebx], dl
    
    ; result[i+j] / 10;
    xor eax, eax
    xor edx, edx
    mov al, [result+ebx]
    mov ecx, 10
    div ecx

    ; result[i+j] %= 10;
    mov [result+ebx], dl

    ; result[i+j+1]
    inc ebx
    xor edx, edx
    mov dl, [result+ebx]
    
    ; += 
    add dl, al
    mov [result+ebx], dl

    inc edi
    jmp innerloop
end_inner_loop:
    inc esi
    jmp outerloop
end_outer_loop:

    mov ecx, 400
find_first:
    dec ecx
    cmp byte [result+ecx], 0
    je find_first
    inc ecx

print_result:
    dec ecx
    xor eax, eax
    mov al, [result+ecx]
    call print_int
    cmp ecx, 0
    jne print_result

    popa
    mov     eax, 0            ; return back to C
    leave                     
    ret

; compute the length of a string
; ebx: string base
; ecx: length
strlen:                     
    xor ecx, ecx
while:                        
    mov dl, [ebx+ecx]
    cmp dl, 0
    je endwhile
    inc ecx    
    jmp while
endwhile:    
    ret  

; convert a number string to a array of number 
; in a reverse order.
; the addresses of two array are stored in stack.
; top -> bottom
; c_num, num, len

convert:
    push ebp
    mov ebp, esp
    xor esi, esi
    mov ecx, [ebp+8]
for:
    cmp esi, ecx
    je endfor

    ; dl = c_num[len-i-1] - '0'
    mov ebx, [ebp+16]
    add ebx, ecx
    sub ebx, esi
    sub ebx, 1
    xor edx, edx
    mov dl, [ebx]
    sub dl, '0'
    
    ; num[i] = dl
    mov ebx, [ebp+12]
    mov [ebx+esi], dl

    inc esi
    jmp for
endfor:
    mov esp, ebp
    pop ebp
    ret