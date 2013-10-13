;=============PPONY, PRINT A SIMPLE PONY SPLASH-PAGE                        11OKT13
;             OR ANY OTHER 16 COLOUR PIXEL-ARRAY GIVEN.
org 100h

segment .code
;;PROCESS CLI TO GET INPUT NAME
    xor ch,ch
    mov cl, byte [0080h]    ;;GET LENGTH OF PARAMETERS.
    cmp cx,0000h            ;;IS OUR LEN ZERO? IF SO PRINT HELP AND EXIT.
    jz exit_help

    mov bx,0081h            ;;put PSP Parameters address into bx
    xor di,di               ;;zero di.

process_cli:
    mov al,[bx]             ;;get first character
    cmp al,"/"              ;;are we a /?
    jz exit_help            ;;WE CHEAT HERE! We only have one possible switch for this, so if there is a switch, we display help.
    cmp al,20h              ;;are we an ignorable space?
    jnz .input              ;;IF not, we are a part of the filename.
    loop process_cli
.input:
    inc bx
    mov al,[bx]             ;;get next character
    cmp al,20h              ;;make sure it is not a space
    jz open_file            ;;exit if it is
    mov [filename+di],al    ;;put it into memory
    inc di                  ;;increment writing address
    loop .input             ;;WE IGNORE PRETTY MUCH ALL CLI EXCEPT /? and FILENAME

    mov byte [filename+di],00h   ;;Null terminate our filename.

;;OPEN AND READ THE FILE INTO BUFFER
open_file:
    mov ah,3dh              ;;DOS2+ OPEN EXISTING FILE
    mov al,00h
    mov dx,filename         ;;POINT TO FILENAME LABEL.
    mov cl,00h
    int 21h                 ;;DO IT, RETURN INTO AX.
    jc exit                 ;;C FLAG SET MEANS ERROR OCCURRED
    mov bx,ax               ;;COPY FILE HANDLE RETURN FROM AX INTO BX

    mov ah,3fh              ;;READ FROM FILE OR DEVICE (DOS2+)
    mov dx,buffer           ;;PUT BUFFER ADDRESS INTO DX
    mov cx,0FA0h            ;;PUT MAXIMUM LENGTH OF BUFFER.
    int 21h                 ;;DO IT. RETURN RESULT TO AX.
    jc exit                 ;;C FLAG SET MEANS ERROR OCCURRED
    mov cx,ax               ;;PUT LENGTH READ INTO COUNTER.

    mov ah,3eh              ;;CLOSE THE FILE
    int 21h

;;MOVE THE CURSOR BEFORE WE DRAW
    mov ax,cx               ;;Copy CX into AX for division
;    push cx                 ;;PROTECT CX
    mov bl,50h              ;;put screen width into bl
    div bl                  ;;divide by screen length.

    mov ah,02h              ;;MOVE CURSOR
    xor bh,bh               ;;PAGE NUMBER?
    mov dh,al               ;;ROW NUMBER FROM DIVISION
    xor dl,dl
    int 10h                 ;;execute

;    pop cx                  ;;RETRIEVE CX
    mov bx,buffer           ;;PUT THE BUFFER LABEL ADDRESS INTO BX.
    mov ax,0b800h           ;;put video memory segment into ax.
    mov es,ax               ;;put video memory segment into ES
    xor di,di               ;;zero DI for use with thing.
    mov al,0dbh             ;;put a block character into al for printing.

draw_loop:                  ;;X Y = ( row * 160 ) + ( clmn * 2 )
    mov dl,[bx]             ;;GET ATTRIBUTE FROM BUFFER
    inc bx                  ;;INCREMENT ADDRESS
    mov [es:di],al          ;;PRINT CHARACTER FIRST
    inc di                  ;;INCREMENT LOCATION.
    mov [es:di],dl          ;;PRINT ATTRIBUTE OF CHARACTER.
    inc di                  ;;INCREMENT LOCATION.
    loop draw_loop          ;;DEC LOOP CX
;;END_LOOP

    xor al,al               ;;0 THE ERRORLEVEL IF WE HIT HERE.
exit:
    mov ah,4ch
    int 21h
exit_help:
    mov bx,msghlp
    mov ah,02h
.prnt:
    mov dl,[bx]
    inc bx
    or dl,dl
    jnz .prnt

    mov ax,4c00h
    int 21h

segment .data
msghlp:     db  "Displays a 16 colour pixel array on screen.",0dh,0ah,09h,"ppony [path]"

segment .bss
filename:   resb 127        ;;reserve space for a full path filename.
buffer:     resb 4000