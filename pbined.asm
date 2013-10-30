;========================================================================16OKT13WIN
;=A small editor to create images for ppony to display.
;==================================================================================
org 100h

segment .code
;===            PROCESS OUR PARAMETERS

;===            SET OUR SEGMENTS TO DRAW
        mov ax,0b800h
        mov es,ax               ;es is now our window into vga.
;===            INITIALIZE AND SET UP

;===            DRAW OUR SCREEN.
        call cls                ;Clear the screen and forget our old screen.
        mov al,18h              ;row 0x18
        xor bx,bx               ;column 0
        mov cx,50h              ;THESE SHOULD ALL BE FACTORS OF SCREEN SIZE. < better idea to this.
        call draw_line
        ;PRINT A NEUTRAL LINE WITH A SET OF CHARACTERS IN 0-F DISPLAYING THEIR COLOURS.

        mov bx,[crsr_pos]       ;Load bx with our initial cursor position.
                                ;Try to keep BX alive so that we can avoid memory calls when doing cursor movement stuff.
        mov al,041h
        mov ah,6fh
        mov word [es:bx],ax       ;put in our cursor.
;===            PREPARE FOR MAINLOOP.

;===            MAIN LOOP
main_l:
       ; jmp exit
;===            Get key
        mov ah,07h              ;Direct character input.
        int 21h
;===            Define key
        cmp al,00h              ;We got an extended key.
        je .ex
        jmp main_l
.ex:
        int 21h                 ;ah=07h
        cmp al,2dh              ;ALT X
        je  .altx
        cmp al,48h              ;arrow up.
        je  .up
        cmp al,50h
        je .down
        cmp al,4bh
        je .left
        cmp al,4dh
        je .right
        jmp main_l
;===            Executions.
.up:
;-(160)
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        sub bx,0a0h                     ;-160 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.down:
;+(160)
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        add bx,0a0h                     ;-160 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.left:
;-2
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        sub bx,02h                      ;-160 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.right:
;+2
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        add bx,02h                      ;-160 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.altx:
        jmp exit ;temp
;===            Process Key
        jmp main_l
exit:
        mov ax,4c00h
        int 21h
;===            CALLS
;
;TAKES AL BX AS X/Y ON WHERE TO DRAW
;TAKES CX TO SAY HOW LONG A LINE TO DRAW
;PS: Should be lined in such a way that we can change character.
draw_line:
        ;check if line is longer than screen, if so alter cx (or alter cx dumbly)
        ;^y? This should always use factors of screenwidth, or dumbly programmed.
        ;this check would protect against programmer mistakes, not configurations.
        mov ah,0a0h             ;160
        mul ah                  ;ROW * 160 -> ax
        shl bx,01h              ;CLMN * 2
        add bx,ax               ;(row*160)+(clmn*2)

        mov ah,07h              ;colour in ah.
        mov al,0dbh             ;character in al
.lp:
        mov word [es:bx],ax     ;print for ammount in cx
        inc bx
        inc bx                  ;unsure if add bx,02h is faster or not.
        loop .lp
        ret
;;CLEAR SCREEN
;;DESTROYS bx,cx
cls:
        xor bx,bx
        mov cx,0780h
        shl cx,01h
.lp:
        mov word [es:bx],0000h
        inc bx
        loop .lp
        ret
segment .data
u_cursor:       dw      0000h   ;colour and character under cursor (for future chr)
crsr_pos:       dw      07d0h   ;our initial cursor position, and subsequently our new positions if it is ever needed.
segment .bss