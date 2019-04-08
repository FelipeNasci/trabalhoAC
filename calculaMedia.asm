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
output  db ? , 0ah, 0h              ; String seguida de nova linha e fim_de_string
input   db ? , 0ah, 0h              ; String seguida de nova linha e fim_de_string
write_count dw 0                    ; Variavel para armazenar caracteres escritos na console
write_c dw 0

vazio   db " ", 0ah, 0h

aprovado    db " ** APROVADO ** ", 0ah, 0h
reprovado   db " ** REPROVADO ** ", 0ah, 0h


;-------    HANDLES   -----------
chaveSaida   dd 0
chaveEntrada dd 0

;--------------------------------
nNotas  dd 3                        ;   Quantidade de notas

nota1   dd 10
nota2   dd 10
nota3   dd 10

soma    dd 0                        ;   Soma das notas
media   dd 0                        ;   media das notas

.code
start:

    push STD_OUTPUT_HANDLE          ;   Capturando handle de saida
    call GetStdHandle
    mov chaveSaida, eax             ;   colocando o handle de saida em um endereco de memoria

    push STD_INPUT_HANDLE           ;   Capturando handle de entrada
    call GetStdHandle
    mov chaveEntrada, eax           ;   colocando o handle de entrada em um endereco de memoria

    ;Zerar registradores
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx


    ;   Captura nota 1
    
    invoke ReadConsole, chaveEntrada, addr input, sizeof input, addr write_c, NULL


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


    invoke atodw, addr input
    mov nota1, eax
    ;invoke WriteConsole, chaveSaida, addr input, sizeof input, addr write_count, NULL


        FUNCAO_SOMA:
            mov eax, nota1
            add eax, nota2
            add eax, nota3
            mov soma, eax

        FUNCAO_MEDIA:
            mov eax, soma
            div nNotas
            mov media, eax

    cmp media, 7
    jge APROVADO
    jmp REPROVADO

        APROVADO:    
            invoke WriteConsole, chaveSaida, addr aprovado, sizeof aprovado, addr write_count, NULL
            jmp FIM_A_R
        REPROVADO:
            invoke WriteConsole, chaveSaida, addr reprovado, sizeof reprovado, addr write_count, NULL
            jmp FIM_A_R
        FIM_A_R:


    invoke dwtoa, media, addr output
    invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
    invoke ExitProcess, 0

;################   NAO ENTRA AQUI POR ENQUANTO ################



    
;    invoke atodw, offset numero         ;   String para numero - O conteudo vai para eax
;    add eax, 10
;    invoke dwtoa, eax, offset numero    ;   Numero para String, o conteudo de eax vai para o end. de memoria da string

    
end start
