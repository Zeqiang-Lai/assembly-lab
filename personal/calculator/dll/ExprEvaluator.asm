;https://stackoverflow.com/questions/14317477/creating-dll-using-masm32?tdsourcetag=s_pctim_aiomsg
; -------------------------------------------
; Build this DLL with the provided MAKEIT.BAT
; -------------------------------------------


include \masm32\include\masm32rt.inc
include \masm32\include\windows.inc

MAX_LEN			EQU	100
MAX_FUNC_LEN	EQU 10

TOK_NUM		EQU		0
TOK_MULTI	EQU		1
TOK_DIV		EQU		2
TOK_PLUS	EQU		3
TOK_MINUS	EQU		4
TOK_LPAREN	EQU		5
TOK_RPAREN	EQU		6
TOK_FUNC	EQU		7
TOK_NEG		EQU		8
TOK_SIN		EQU		9
TOK_COS		EQU		10
TOK_TAN		EQU		11

SUCCESS			 EQU	0
UNMATCHED_PAREN  EQU	1
INVALID_EXPR	 EQU	2
INVALID_CHAR	 EQU	3
DIVIDED_ZERO	 EQU	4
UNSUPPORTED_FUNC EQU	5
EXPR_TOO_LONG	 EQU	6

.data?
	hInstance dd ?

.data

eans	qword	?

expr	db	MAX_LEN dup(?)

post_expr	dword MAX_LEN dup(?)
parsed		dword 0
; Keep an eye on the size of p!
p			db	  0, 2, 2, 1, 1, 0, 0, 4, 3, 4, 4, 4
; Local var for parse
pstack		dword	MAX_LEN dup(?)
ptop		dword	0

; Local var for evaluate
estack		qword	MAX_LEN dup(?)
etop		dword	0

t_len	dword		0
tokens	dword		MAX_LEN dup(?)
values	qword		MAX_LEN dup(0)

; TODO: change it to local var
func_name	db	MAX_FUNC_LEN dup(?)

name_cos	db	"cos", 0
name_sin	db	"sin", 0
name_tan	db	"tan", 0

num_ten			dword	10
num_zero_double qword 0

.code
LibMain proc instance:DWORD,reason:DWORD,unused:DWORD 
	.if reason == DLL_PROCESS_ATTACH
		mrm hInstance, instance       ; copy local to global
		mov eax, TRUE                 ; return TRUE so DLL will start
    .elseif reason == DLL_PROCESS_DETACH
    .elseif reason == DLL_THREAD_ATTACH
    .elseif reason == DLL_THREAD_DETACH
    .endif
    ret
LibMain endp

Init proc
	mov dword ptr [t_len], 0
	mov dword ptr [etop], 0
	mov dword ptr [ptop], 0
	mov dword ptr [parsed], 0
	mov dword ptr [t_len], 0
	ret
Init endp

Tokenize_number proc C idx:dword
	local base:qword, divider:qword, tmp:dword

	; base = 10
	fild dword ptr [num_ten]
	fstp qword ptr [base]

	; edx = expr[idx]
	xor edx, edx
	mov ebx, [idx]
	mov esi, [ebx]
	movzx edx, byte ptr [expr+esi]

	; value = 0
	fldz
dowhile_start:
	fmul qword ptr [base]
	sub edx, '0'
	mov [tmp], edx
	fiadd dword ptr [tmp]
	inc esi
	movzx edx, byte ptr [expr+esi]
	push edx
	invoke crt_isdigit, dl
	pop edx
	cmp eax, 0
	jne dowhile_start

end_dowhile:
	cmp edx, '.'
	jne endif_

	;divider = 0.1
	fld1
	fdiv qword ptr [base]
	fstp qword ptr [divider]

	inc esi
	movzx edx, byte ptr [expr+esi]

start_while:
	push edx
	invoke crt_isdigit, dl 
	pop edx
	cmp eax, 0
	je endif_
	
	sub edx, '0'
	mov [tmp], edx

	fld qword ptr [divider]
	fimul dword ptr [tmp]
	fstp dword ptr [tmp]
	fadd dword ptr [tmp]
	fld qword ptr [divider]
	fdiv qword ptr [base]
	fstp qword ptr [divider]

	inc esi	
	movzx edx, byte ptr [expr+esi]
	jmp start_while

endif_:
	mov ebx, [idx]
	mov [ebx], esi
	mov esi, [t_len]
	mov dword ptr [tokens+esi*4], TOK_NUM
	fstp qword ptr [values+esi*8]
	inc esi
	mov [t_len], esi

	mov eax, SUCCESS
	ret
Tokenize_number endp

Tokenize_func proc C idx:dword
	xor edx, edx
	mov ebx, [idx]
	mov esi, [ebx]
	movzx edx, byte ptr [expr+esi]
	
	mov edi, 0
beginwhile:
	invoke crt_isalpha, edx
	cmp eax, 0
	je endwhile
	mov [func_name+edi], dl
	inc edi
	cmp edi, MAX_FUNC_LEN
	jae l_fail
	inc esi
	movzx edx, byte ptr [expr+esi]
	jmp beginwhile
endwhile:
	mov [ebx], esi
	mov byte ptr [func_name+edi], 0
	
	mov edi, [t_len]
	invoke crt_strcmp, offset func_name, offset name_sin
	cmp eax, 0
	jne cmp_cos
	mov dword ptr [tokens+edi*4], TOK_SIN
	jmp l_success
cmp_cos:
	invoke crt_strcmp, offset func_name, offset name_cos
	cmp eax, 0
	jne cmp_tan
	mov dword ptr [tokens+edi*4], TOK_COS
	jmp l_success
cmp_tan:
	invoke crt_strcmp, offset func_name, offset name_tan
	cmp eax, 0
	jne l_fail
	mov dword ptr [tokens+edi*4], TOK_TAN
	jmp l_success
l_success:
	mov eax, SUCCESS
	inc dword ptr [t_len]
	jmp lreturn
l_fail:
	mov eax, UNSUPPORTED_FUNC
lreturn:
	ret
Tokenize_func endp

Tokenize_operator proc C idx:dword
	xor edx, edx
	mov ebx, [idx]
	mov esi, [ebx]
	movzx edx, byte ptr [expr+esi]
	
	mov edi, [t_len]
lplus:
	cmp edx, '+'
	jne lminus
	mov dword ptr [tokens+edi*4], TOK_PLUS
	jmp lsuccess
lminus:
	cmp edx, '-'
	jne lmulti
	cmp esi, 0
	je l_neg
	dec esi
	movzx eax, byte ptr [expr+esi]
	invoke crt_ispunct, eax
	cmp eax, 0
	je l_else
l_neg:
	mov dword ptr [tokens+edi*4], TOK_NEG
l_else:
	mov dword ptr [tokens+edi*4], TOK_MINUS
l_end:
	jmp lsuccess
lmulti:
	cmp edx, '*'
	jne ldiv
	mov dword ptr [tokens+edi*4], TOK_MULTI
	jmp lsuccess
ldiv:
	cmp edx, '/'
	jne llparen
	mov dword ptr [tokens+edi*4], TOK_DIV
	jmp lsuccess
llparen:
	cmp edx, '('
	jne lrparen
	mov dword ptr [tokens+edi*4], TOK_LPAREN
	jmp lsuccess
lrparen:
	cmp edx, ')'
	jne ldefault
	mov dword ptr [tokens+edi*4], TOK_RPAREN
	jmp lsuccess
ldefault:
	mov eax, INVALID_CHAR
	ret
lsuccess:
	mov ebx, [idx]
	inc dword ptr [ebx]
	inc dword ptr [t_len]
	mov eax, SUCCESS
	ret
Tokenize_operator endp

Tokenize proc
	local cur_ch, idx, status, len_expr : dword
	mov [cur_ch], 0 ;;;
	mov dword ptr [idx], 0
	mov dword ptr [status], SUCCESS

	invoke crt_strlen, offset expr
	mov [len_expr], eax

startwhile:
	mov esi, [idx]
	cmp esi, len_expr
	jae endwhile
	movzx edx, byte ptr [expr+esi]	; edx = ch

	invoke crt_isdigit, dl
	cmp eax, 0
	je l_func
	invoke Tokenize_number, addr idx 
	jmp startwhile

l_func:
	invoke crt_isalpha, edx
	cmp eax, 0
	je l_operator
	invoke Tokenize_func, addr idx
	mov [status], eax
	cmp eax, SUCCESS
	jne endwhile
	jmp startwhile

l_operator:
	invoke Tokenize_operator, addr idx
	mov [status], eax
	cmp eax, SUCCESS
	jne endwhile
	jmp startwhile

endwhile:
	mov eax, [status]
	ret
Tokenize endp

Less proc C op1:dword, op2:dword
	push esi
	push edx
	push edi
	push ebx

	mov esi, dword ptr [op1]
	mov edi, dword ptr [tokens+esi*4]
	movzx edx, byte ptr [p+edi]
	
	mov esi, dword ptr [op2]
	mov edi, dword ptr [tokens+esi*4]
	movzx ebx, byte ptr [p+edi]

	cmp edx, ebx
	jb  ltrue
	mov eax, FALSE
	jmp lret
ltrue:
	mov eax, TRUE
lret:
	pop ebx
	pop edi
	pop edx
	pop esi
	ret
Less endp

Check proc C idx:dword, type_:dword
	push esi
	push edx
	push ebx

	mov esi, dword ptr [idx]
	mov edx, dword ptr [tokens+esi*4]
	mov ebx, dword ptr [type_]
	cmp edx, ebx
	je ltrue
	mov eax, FALSE
	jmp lret
ltrue:
	mov eax, TRUE
lret:
	pop ebx
	pop edx
	pop esi
	ret
Check endp

Parse proc
	mov dword ptr [ptop], 0
	mov esi, 0
beginfor:
	cmp esi, dword ptr [t_len]
	jae endfor
	mov edx, dword ptr [tokens+esi*4]
	cmp edx, TOK_NUM
	jne llparen
	mov edi, [parsed]
	mov dword ptr [post_expr+edi*4], esi
	inc dword ptr [parsed]
	jmp nextfor
llparen:
	cmp edx, TOK_LPAREN
	jne lrparen
	mov edi, [ptop]
	mov dword ptr [pstack+edi*4], esi
	inc dword ptr [ptop]
	jmp nextfor
lrparen:
	cmp edx, TOK_RPAREN
	jne loperator
beginwhile1:
	cmp dword ptr [ptop], 0
	jbe endwhile1
	mov edi, [ptop]
	dec edi
	mov ebx, dword ptr [pstack+edi*4]
	invoke Check, ebx, TOK_LPAREN
	cmp eax, TRUE
	je endwhile1
	mov edi, [parsed]
	mov dword ptr [post_expr+edi*4], ebx
	inc dword ptr [parsed]
	dec dword ptr [ptop]
	jmp beginwhile1
endwhile1:
	cmp dword ptr [ptop], 0
	jne endif1
	mov eax, UNMATCHED_PAREN
	jmp lret
endif1:
	dec dword ptr [ptop]
	jmp nextfor
loperator:
	cmp dword ptr [ptop], 0
	je lopif
	mov edi, [ptop]
	dec edi
	mov ebx, dword ptr [pstack+edi*4]
	invoke Less, ebx, esi
	cmp eax, TRUE
	jne lopelse
lopif:
	mov edi, [ptop]
	mov dword ptr [pstack+edi*4], esi
	inc dword ptr [ptop]
	jmp nextfor
lopelse:
beginwhile2:
	cmp dword ptr [ptop], 0
	je endwhile2
	mov edi, [ptop]
	dec edi
	mov ebx, dword ptr [pstack+edi*4]
	invoke Less, ebx, esi
	cmp eax, TRUE
	je endwhile2
	mov edi, [parsed]
	mov dword ptr [post_expr+edi*4], ebx
	inc dword ptr [parsed]
	dec dword ptr [ptop]
	jmp beginwhile2
endwhile2:
	mov edi, [ptop]
	mov dword ptr [pstack+4*edi], esi
	inc dword ptr [ptop]
nextfor:
	inc esi
	jmp beginfor
endfor:
beginwhile3:
	cmp dword ptr [ptop], 0
	jbe endwhile3
	mov edi, [ptop]
	dec edi
	mov ebx, [pstack+edi*4]
	mov edi, [parsed]
	mov dword ptr [post_expr+edi*4], ebx
	inc dword ptr [parsed]
	dec dword ptr [ptop]
	jmp beginwhile3
endwhile3:
	mov eax, SUCCESS
lret:
	ret
Parse endp

Evaluate_ proc
	local op1:qword, op2:qword, result:qword
	mov esi, 0
beginfor:
	cmp esi, dword ptr [parsed]
	jae endfor
	mov edi, dword ptr [post_expr+esi*4]
	mov edx, dword ptr [tokens+edi*4]
	cmp edx, TOK_LPAREN
	je lunmatched
	cmp edx, TOK_RPAREN
	je lunmatched
l_num:
	cmp edx, TOK_NUM
	jne l_neg
	mov edi, [post_expr+esi*4]
	fld qword ptr [values+edi*8]
	mov edi, [etop]
	fstp qword ptr estack[edi*8]
	inc dword ptr [etop]
	jmp nextfor
l_neg:
	cmp edx, TOK_NEG
	jne l_sin
	mov edi, [etop]
	cmp edi, 1
	jb linvalid
	dec edi
	fld qword ptr [estack+edi*8]
	fchs
	fstp qword ptr [estack+edi*8]
	jmp nextfor
l_sin:
	cmp edx, TOK_SIN
	jne l_cos
	mov edi, [etop]
	cmp edi, 1
	jb linvalid
	dec edi
	fld qword ptr [estack+edi*8]
	fstp qword ptr [op1]
	push edi
	invoke crt_sin, qword ptr op1
	pop edi
	fstp qword ptr [estack+edi*8]
	jmp nextfor
l_cos:
	cmp edx, TOK_COS
	jne l_tan
	mov edi, [etop]
	cmp edi, 1
	jb linvalid
	dec edi
	fld qword ptr [estack+edi*8]
	fstp qword ptr [op1]
	push edi
	invoke crt_cos, qword ptr op1
	pop edi
	fstp qword ptr [estack+edi*8]
	jmp nextfor
l_tan:
	cmp edx, TOK_TAN
	jne l_binary
	mov edi, [etop]
	cmp edi, 1
	jb linvalid
	dec edi
	fld qword ptr [estack+edi*8]
	fstp qword ptr [op1]
	push edi
	invoke crt_tan, qword ptr op1
	pop edi
	fstp qword ptr [estack+edi*8]
	jmp nextfor
l_binary:
	cmp dword ptr [etop], 2
	jb linvalid
	mov edi, [etop]
	sub edi, 2
	fld qword ptr [estack+edi*8]
	fstp qword ptr [op1]
	inc edi
	fld qword ptr [estack+edi*8]
	fstp qword ptr [op2]
	sub dword ptr [etop], 2
lcase_multi:
	cmp edx, TOK_MULTI
	jne lcase_div
	fld qword ptr [op1]
	fmul qword ptr [op2]
	fstp qword ptr [result]
	jmp endswitch
lcase_div:
	cmp edx, TOK_DIV
	jne lcase_plus
	fld qword ptr [op2]
	fcomp qword ptr [num_zero_double]
	fstsw ax
	sahf
	je lzero
	fld qword ptr [op1]
	fdiv qword ptr [op2]
	fstp qword ptr [result]
	jmp endswitch
lcase_plus:
	cmp edx, TOK_PLUS
	jne lcase_minus
	fld qword ptr [op1]
	fadd qword ptr [op2]
	fstp qword ptr [result]
	jmp endswitch
lcase_minus:
	fld qword ptr [op1]
	fsub qword ptr [op2]
	fstp qword ptr [result]
	jmp endswitch
endswitch:
	mov edi, [etop]
	fld qword ptr [result]
	fstp qword ptr [estack+edi*8]
	inc dword ptr [etop]
	jmp nextfor
nextfor:
	inc esi
	jmp beginfor
endfor:
	fld qword ptr [estack]
	fstp qword ptr [eans]
	jmp lsuccess
lzero:
	mov eax, DIVIDED_ZERO
	jmp lret
linvalid:
	mov eax, INVALID_EXPR
	jmp lret
lunmatched:
	mov eax, UNMATCHED_PAREN
	jmp lret
lsuccess:
	mov eax, SUCCESS
	jmp lret
lret:
	ret
Evaluate_ endp


; C prototype:
;	int Evaluate(char* exprs, double* ans)
; Parameters:
;	exprs	-	address of the expression string.
;	ans_	-	pointer to double to store the result in. 
; Return:
;	return 0 if success, otherwise error code.
Evaluate proc C exprs:dword, elen:dword
	local status:dword
	invoke Init
	pusha 
	
	cmp dword ptr [elen], MAX_LEN
	jae llong
	mov esi, 0
	mov ebx, [exprs]
lcopy:
	xor edx, edx
	mov dl, byte ptr [ebx+esi]
	mov byte ptr [expr+esi], dl
	inc esi
	cmp esi, dword ptr [elen]
	jb lcopy
	xor edx, edx
	mov dl, 0
	mov byte ptr [expr+esi], dl

	invoke Tokenize
	mov dword ptr [status], eax
	cmp eax, SUCCESS
	jne lret

	invoke Parse
	mov dword ptr [status], eax
	cmp eax, SUCCESS
	jne lret

	invoke Evaluate_
	mov dword ptr [status], eax
	jmp lret
	
llong:
	mov eax, EXPR_TOO_LONG
lret:
	popa
	mov eax, dword ptr [status]
	;invoke crt_strlen, offset expr
	ret
Evaluate endp

GetResult proc C
	fld qword ptr [eans]
	ret
GetResult endp 

end LibMain