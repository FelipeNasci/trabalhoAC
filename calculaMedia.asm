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
output db " ", 0ah, 0h              ; String seguida de nova linha e fim_de_string
write_count dw 0                    ; Variavel para armazenar caracteres escritos na console

aprovado    db " ** APROVADO ** ", 0ah, 0h
reprovado   db " ** REPROVADO ** ", 0ah, 0h


;-------    HANDLES   -----------
chaveSaida   dd 0

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

    ;Zerar registradores
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx

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


    invoke dwtoa, media, offset output
    invoke WriteConsole, chaveSaida, addr output, sizeof output, addr write_count, NULL
    invoke ExitProcess, 0
  
end start
