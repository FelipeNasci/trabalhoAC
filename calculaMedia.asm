.386
.model flat,stdcall
option casemap:none

include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

include \masm32\include\masm32.inc
includelib \masm32\lib\masm32.lib

.data

;-------    STRINGS   -----------

output	db ? , 0ah, 0h              ; String seguida de nova linha e fim_de_string
input   db ? , 0ah, 0h              ; String seguida de nova linha e fim_de_string
write_count dd 0                    ; Variavel para armazenar caracteres escritos na console
write_c dd 0

texto   db 0Dh, 0Ah, 'Insira o numero de notas: ', 0
texto2  db "Insira uma nota " , 0h

;-------    HANDLES   -----------
chaveSaida   dd 0
chaveEntrada dd 0

nNotas	dd 3
cont	dd ?

nota	real8 0.0						;   variavel auxiliar que armazena uma nota inserida
soma	real8 0.0						;   Soma das notas
media	real8 0.0						;   media das notas
nNotasf	real8 3.0
.code  
start:

	call OBTER_HANDLES
	call RESET_REG
	
									;   Obtem o numero de notas e atribui o valor para nNotas

    invoke WriteConsole, chaveSaida, addr texto, sizeof texto, addr write_count, NULL
    invoke ReadConsole, chaveEntrada, addr input, sizeof input + 1, addr write_c, NULL
	
    call REMOVE_LIXO				;	Remove caracteres invalidos do console
    call OBTER_VALOR				;	Insere a quantidade de notas na pilha
    pop nNotas						;	Atribui a quant de notas para nNotas	

	mov cont, 0   					;	zera o contador

        ENQUANTO_HOUVER_NOTAS:

            invoke WriteConsole, chaveSaida, addr texto2, sizeof texto2, addr write_count, NULL
            invoke ReadConsole, chaveEntrada, addr input, sizeof input + 1, addr write_c, NULL

			invoke StrToFloat, addr [input], addr [nota]
			call FUNCAO_SOMA
			
			    ;	finit                            ;reset fpu stacks to default
				;	fld    dword ptr [single_value2] ;single_value2 to fpu stack(st1)
				;	fld    dword ptr [single_value1] ;single_value1 to fpu stack(st0)
				;	fcom                             ;compare st0 with st1
				;	fstsw  ax                        ;ax := fpu status register
						
            inc cont
            mov ebx, nNotas
            cmp cont, ebx
            jl ENQUANTO_HOUVER_NOTAS
            
        FIM_ENQUANTO_HOUVER_NOTAS:

		
	call FUNCAO_MEDIA
	
    invoke FloatToStr, [media], addr [output]
    invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
    
	invoke ExitProcess, 0

;##########################   FUNCOES ##########################

;********************** SOMA AS NOTAS   ****************************

    FUNCAO_SOMA PROC
                        
		fld nota					;	add nota na pilha da FPU
		fld soma					;	add soma na pilha da FPU
		fadd						;	soma + nota
		fstp soma					;	soma = soma + nota

		fld nota					;	Empilha nota novamente na FPU

        ret
    FUNCAO_SOMA ENDP
	
;********************** MEDIA DAS NOTAS   **************************

    FUNCAO_MEDIA PROC

		finit
		fld soma			;	empilha soma
		fld nNotasf			;	empilha quantidade de notas
		fdiv				;	soma / nNotas
		fstp media			;	media = soma / nNotas

        ret

    FUNCAO_MEDIA ENDP	

;********************** REMOVE DA STRING O QUE NAO EH NUMERO    *****

    REMOVE_LIXO PROC

        mov esi, offset input                       ; Armazenar apontador da string em esi
        proximo:
            mov al, [esi]                           ; Mover caracter atual para al
            inc esi                                 ; Apontar para o proximo caracter
            cmp al, 48                              ; Verificar se menor que ASCII 48 - FINALIZAR
            jl terminar
            cmp al, 58                              ; Verificar se menor que ASCII 58 - CONTINUAR
            jl proximo
        terminar:
            dec esi                                 ; Apontar para caracter anterior
            xor al, al                              ; 0 ou NULL
            mov [esi], al                           ; Inserir NULL logo apos o termino do numero

        ret

    REMOVE_LIXO ENDP


;********************** OBTEM ENTRADA DE NUMERO INTEIRO DO USUARIO  *******************

    OBTER_VALOR PROC
    
        invoke atodw, addr input
        pop ebx                     	;   guarda endereco de retorno
        push eax                    	;   armazena uma nota na pilha
        push ebx                    	;   realoca endereco de retorno
        ret

    OBTER_VALOR ENDP


;********************** OBTER HANDLES  *******************

    OBTER_HANDLES PROC
    
        pop ebx                     	;   guarda endereco de retorno
        
        push STD_OUTPUT_HANDLE          ;   Capturando handle de saida
        call GetStdHandle
        mov chaveSaida, eax             ;   colocando o handle de saida em um endereco de memoria

        push STD_INPUT_HANDLE           ;   Capturando handle de entrada
        call GetStdHandle
        mov chaveEntrada, eax

        push ebx                    	;   realoca endereco de retorno
        ret

    OBTER_HANDLES ENDP


;********************** ZERA OS REGISTRADORES  *******************

    RESET_REG PROC
    
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
        xor edx, edx
		
		finit							;	Reseta FPU

        ret
    RESET_REG ENDP

end start
