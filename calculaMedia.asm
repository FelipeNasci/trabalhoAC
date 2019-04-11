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

output  db 10 dup(0)									;	String seguida de nova linha e fim_de_string
write_count dd 0										;	Variavel para armazenar caracteres escritos na console
input   db 10 dup(0)									;	String seguida de nova linha e fim_de_string
write_c dd 0
_str	db 10 dup(0)
write_str	dd 0

bemVindo db "Bem vindo ao sistema de notas!", 0ah
texto   db "Insira o numero de notas da disciplina: ", 0h
texto2  db "Insira uma nota " , 0h
texto3  db "Insira o nome do aluno ", 0h
texto4  db 0ah, 0ah, "Deseja inserir notas de um novo aluno? 's' = Sim 'n' = Nao ", 0h
texto5  db 0ah, 0ah, "** Voce esta digitando uma nota fora dos limites, por favor, tente novamente ** ", 0ah, 0h

aprovado  db " estah ** APROVADO ** com media = " , 0h
reprovado db " estah ** REPROVADO ** com media = " , 0h
final	    db " estah em ** FINAL ** precisando de " , 0h

aluno   db  30 dup(0)

;-------    HANDLES   -----------
chaveSaida   dd 0
chaveEntrada dd 0

;-------    CONSTANTES   -----------

_dez    real8 10.0
_sete   real8 7.0
_cinco	real8 5.0
_quatro real8 4.0
_pQuatro real8 0.4
_pSeis	real8 0.6
_zero   real8 0.0

_reset  real8 0.0
incr    real8 1.0

;-------    VARIAVEIS   -----------
nNotas  real8 3.0
cont    real8 0.0

nota	real8 0.0									;   variavel auxiliar que armazena uma nota inserida
soma	real8 0.0									;   Soma das notas
media	real8 0.0									;   media das notas

len		dd 0
contChar	dd 0

.code  
start:

	call OBTER_HANDLES
	
            invoke WriteConsole, chaveSaida, addr bemVindo, sizeof bemVindo, addr write_count, NULL

	WHILE_TRUE:
	
		call RESET_REG							;	RESETA REGISTRADOS E VARIAVEIS A CADA LOOP

		invoke WriteConsole, chaveSaida, addr texto3, sizeof texto3, addr write_count, NULL	;	imprime na tela
		invoke ReadConsole, chaveEntrada, addr aluno, sizeof aluno, addr write_c, NULL

										;   Obtem o numero de notas e atribui o valor para nNotas

		invoke WriteConsole, chaveSaida, addr texto, sizeof texto, addr write_count, NULL	;	imprime na tela
		invoke ReadConsole, chaveEntrada, addr input, sizeof input, addr write_c, NULL	;	Captura o dado pelo teclado
		invoke StrToFloat, addr [input], addr [nNotas]
		

			ENQUANTO_HOUVER_NOTAS:

                        call INC_CONT							;	incrementa cont

				invoke WriteConsole, chaveSaida, addr texto2, sizeof texto2, addr write_count, NULL	
				invoke ReadConsole, chaveEntrada, addr input, sizeof input, addr write_c, NULL
				invoke StrToFloat, addr [input], addr [nota]		;	Converte o dado recebido para float

                        call VALIDA_NOTA			

				call FUNCAO_SOMA

				call COMPARA_CONT_nNOTAS				;	compara se cont eh menor que nNotas
				ja    FIM_ENQUANTO_HOUVER_NOTAS				;	Se maior -> break
				jb    ENQUANTO_HOUVER_NOTAS				;	Se menor -> cont++
				jz    FIM_ENQUANTO_HOUVER_NOTAS				;	Se igual -> break
				
			FIM_ENQUANTO_HOUVER_NOTAS:
			
		call FUNCAO_MEDIA
		
		call LIMPA_SAIDA							;	EVITA LIXO DE MEMORIA EM OUTPUT

		call DECIDE_APROVACAO

			APROVADO:

				invoke FloatToStr, [media], addr [output]
                        invoke WriteConsole, chaveSaida, addr aluno, sizeof aluno, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr aprovado, sizeof aprovado, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
				jmp FIM_A_P_F
			
			REPROVADO:

				invoke FloatToStr, [media], addr [output]
                        invoke WriteConsole, chaveSaida, addr aluno, sizeof aluno, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr reprovado, sizeof reprovado, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
				jmp FIM_A_P_F

			FINAL:

				call CALCULA_FINAL

				invoke FloatToStr, [media], addr [output]
                        invoke WriteConsole, chaveSaida, addr aluno, sizeof aluno, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr final, sizeof final, addr write_count, NULL
				invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
				jmp FIM_A_P_F
			   
			FIM_A_P_F:
			
			invoke WriteConsole, chaveSaida, addr texto4, sizeof texto4, addr write_count, NULL	;	imprime na tela
			invoke ReadConsole, chaveEntrada, addr input, sizeof input, addr write_c, NULL
			
			cmp input, 115                                           ;   Compara se input == 's'
			je WHILE_TRUE
				
    FIM_WHILE_TRUE:
	invoke ExitProcess, 0

;##########################   FUNCOES ##########################

;********************** SOMA AS NOTAS   ****************************

    FUNCAO_SOMA PROC
                        
		fld nota					;	add nota na pilha da FPU
		fld soma					;	add soma na pilha da FPU
		fadd						;	soma + nota
		fstp soma					;	soma = soma + nota

        ret
    FUNCAO_SOMA ENDP
	
;********************** MEDIA DAS NOTAS   **************************

    FUNCAO_MEDIA PROC

		finit
		fld soma			;	empilha soma
		fld nNotas			;	empilha quantidade de notas
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


;********************** RESETA REGISTRADORES E VARIAVEIS  *******************

    RESET_REG PROC

        fld _reset
        fstp cont

        fld _reset
        fstp nNotas
        
        fld _reset
        fstp nota

        fld _reset
        fstp soma
		
	  fld _reset
        fstp media
		
        xor eax, eax
        xor ebx, ebx
        xor ecx, ecx
        xor edx, edx
		
        finit						;	Reseta FPU

        ret
    RESET_REG ENDP
	

;********************** INCREMENTA O CONTADOR  *******************

    INC_CONT PROC
    
		fld cont				;	add cont na pilha da FPU
		fld incr				;	add soma na pilha da FPU
		fadd					;	cont + 1
		fstp cont				;	soma = cont + 1

		ret
	INC_CONT ENDP

;********************** COMPARA SE CONT < nNOTAS  *******************	
	
	COMPARA_CONT_nNOTAS PROC
    
		fld cont				;	empilha cont na FPU
		fcom  nNotas   				;	Compara com nNotas
		fstsw ax        			;	Se der erro Copia o resultado para ax
		fwait           			;	Garante que a instrucao foi completada
		sahf            			;	Transfere a condicao para uma flag da cpu

		fstp cont				;	desempilha cont
		
		ret
	COMPARA_CONT_nNOTAS ENDP
	
;********************** COMPARA SE NOTA  *******************	
	
	COMPARA_MEDIA PROC
    
		fcom  media	;	Compara com nNotas
		fstsw ax        ;	Copia o resultado para ax
		fwait           ;	Garante que a instrucao foi completada
		sahf            ;	Transfere a condicao para uma flag da cpu
		
		ret
	COMPARA_MEDIA ENDP	
	
;********************** DECIDE SE APROVADO / REPROVADO / FINAL  *******************	
	
	DECIDE_APROVACAO PROC

		pop ebx					;	desempilha endereco de retorno, 
							;	pois nunca chegara em ret
    
		fld _sete				;	empilha 7.0
		call COMPARA_MEDIA			;	compara 7.0 com media
		fstp _sete

		jb    APROVADO				;	Se 7 < media -> APROVADO
		jz    APROVADO				;	Se 7 == media -> APROVADO

		fld _quatro				;	empilha 4.0
		call COMPARA_MEDIA			;	compara 4.0 com media 
		fstp _quatro

		ja    REPROVADO				;	Se 4 > media -> FINAL
		jb    FINAL				;	Se 4 < media -> REPROVADO
		jz    FINAL				;	Se 4 == media -> FINAL
		
		push ebx
		ret
	DECIDE_APROVACAO ENDP	
	
	
;********************** LIMPA STRING  *******************	
	
	LIMPA_SAIDA PROC
		
		pop ebx					;	guarda o endereco de retorno								;	desempilha endereco de retorno, 
		
		mov eax, 0
		mov contChar, eax			;	ZERA O CONTADOR DE CARACTERES
		
		mov eax, sizeof output			;	TAMANHO DE OUTPUT
		mov len, eax
		
		mov esi, offset output			;	PONTEIRO PARA OUTPUT

		ENQUANTO_MENOR_TAMANHO:
			
			xor al, al
			mov [esi], al
			inc esi
			
			inc contChar
			mov eax, len
			cmp contChar, eax
			jl ENQUANTO_MENOR_TAMANHO
			
		FIM_ENQUANTO_MENOR_TAMANHO:
	
		push ebx
		ret
	LIMPA_SAIDA ENDP		
	
	
	;********************** CALCULA QUANTO O ALUNO PRECISA OBTER NA PROVA FINAL  *******************	
	
	CALCULA_FINAL PROC
		

		fld media
		fld _pSeis
		fmul
		fstp media		;	media * 0.6
		
		fld _cinco
		fld media
		fsub 
		fstp media		;	( media * 0.6 - 5 )
		
		fld media
		fld _pQuatro
		fdiv
		fstp media		;	( media * 0.6 + 5 ) / 0.4
		
		
		ret
	CALCULA_FINAL ENDP

	;********************** VERIFICA 0 <= nota <= 10  *******************	
	
	VALIDA_NOTA PROC
		

		fld nota
		fcom _dez	;	Compara com nNotas
		fstsw ax        ;	Copia o resultado para ax
		fwait           ;	Garante que a instrucao foi completada
		sahf            ;	Transfere a condicao para uma flag da cpu
		fstp nota

            ja    INVALIDO                      ;   Se nota > 10

            fld nota
            fcom _zero
		fstsw ax        ;	Copia o resultado para ax
		fwait           ;	Garante que a instrucao foi completada
		sahf            ;	Transfere a condicao para uma flag da cpu
            fstp nota

		jb    INVALIDO				;	Se nota < 0
	
            ret

		INVALIDO:
                invoke WriteConsole, chaveSaida, addr texto5, sizeof texto5, addr write_count, NULL

                ; CONTADOR DECREMENTA

                fld cont
                fld incr
                fsub
		    fstp cont

            pop ebx
            jmp ENQUANTO_HOUVER_NOTAS


           
	VALIDA_NOTA ENDP
	
	
	end start
