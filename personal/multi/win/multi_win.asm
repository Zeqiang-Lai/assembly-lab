.386
.model flat, stdcall
option casemap:none

includelib	msvcrt.lib

printf	proto c:dword,:vararg
scanf	proto c:dword,:vararg

.data
c_num1 db 200 dup(0)
c_num2 db 200 dup(0)
num1   db 200 dup(0)
num2   db 200 dup(0)
result db 400 dup(0)
len1   dd 0
len2   dd 0

formatS		byte	"%s", 0
formatD		byte	"%d", 0

.code

strlen proc         
; compute the length of a string
; ebx: string base
; ecx: store length here
    xor ecx, ecx
	repea:                        
		mov dl, [ebx+ecx]
		cmp dl, 0
		je done
		inc ecx    
		jmp repea
	done:    
		ret  
strlen endp

convert proc
; convert a number string to a array of number 
; in a reverse order.
; the addresses of two array are stored in stack.
; top -> bottom
; c_num, num, len
    push ebp
    mov ebp, esp
    xor esi, esi
    mov ecx, [ebp+8]
repea:
    cmp esi, ecx
    je done

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
    jmp repea
done:
    mov esp, ebp
    pop ebp
    ret
convert endp

; main program
main	proc
	;###### Input two numbers #######;

	invoke scanf, offset formatS, offset c_num1
	invoke scanf, offset formatS, offset c_num2

	;###### End Input two numbers #######;

	;invoke printf, offset formatS, offset c_num1

	;###### Compute length #######;

	mov ebx, offset c_num1
    call strlen
    mov len1, ecx

	mov ebx, offset c_num2
    call strlen
    mov len2, ecx

	;###### End Compute length #######;

	;###### Convert chat to int #######;

	push offset c_num1
    push offset num1
    push len1
    call convert
    pop eax
    pop eax
    pop eax

    push offset c_num2
    push offset num2
    push len2
    call convert
    pop eax
    pop eax
    pop eax

	;###### End Convert chat to int #######;

	;###### Do the multiplication #######;
	; C code:
	;
	;   for(int i=0; i<len1; ++i) {
	;        for(int j=0; j<len2; ++j) {
	;           result[i+j] += num1[i] * num2[j];
	;            result[i+j+1] += result[i+j] / 10;
	;            result[i+j] %= 10;
	;        }
	;   }

    mov esi, 0
outerloop:
    cmp esi, len1
    je end_outer_loop
    mov edi, 0
innerloop:
    cmp edi, len2
    je end_inner_loop
    
    ; num1[i] * num2[j]
    xor eax, eax
    mov al, [num1+esi]
	mov bl, [num2+edi]
    mul bl

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
	;###### End Do the multiplication #######;

    mov ecx, 400
find_first:
    dec ecx
    cmp [result+ecx], 0
    je find_first
    inc ecx

print_result:
    dec ecx
    xor eax, eax
	mov eax, offset result
	add eax, ecx
	movzx edx, byte ptr [eax]
	push ecx
    invoke printf, offset formatD, edx
	pop ecx
    cmp ecx, 0
    jne print_result

	
	ret
main	endp
end		main

