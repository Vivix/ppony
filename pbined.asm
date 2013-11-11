;========================================================================30OKT13WIN
;=A small editor to create images for ppony to display.
;==================================================================================
org 100h

segment .code
;===            PROCESS OUR PARAMETERS

;===            SET OUR SEGMENTS TO DRAW
        mov ax,0b800h
        mov es,ax               ;es is now our window into vga.

;===            INITIALIZE AND SET UP
;       TODO: Check blinkbit status.
        mov ax,1003h            ;Disable blink bit for dosbox.
        xor bl,bl
        int 10h

;===            DRAW OUR SCREEN.
        call cls                ;Clear the screen and forget our old screen.

        call draw_status        ;Draw our base screen (Status line)

        mov bx,[crsr_pos]       ;Load bx with our initial cursor position.
                                ;Try to keep BX alive so that we can avoid memory
                                ;calls when doing cursor movement stuff.
        mov al,041h
        mov ah,6fh
        mov word [es:bx],ax       ;put in our cursor.

;===         PREPARE FOR MAINLOOP.

;===         Main loop
main_l:
        mov ah,07h              ;Get and process keyboard input.
        int 21h

        cmp al,00h              ;We got an extended key.
        je .ex                  ;jump to extended key land.

;===            Drawing keys.
        cmp al,31h
        je  .c_one
        cmp al,32h
        je  .c_two
        cmp al,33h
        je  .c_three
        cmp al,34h
        je  .c_four
        jmp main_l

;===            Movement keys.
.ex:
        int 21h                 ;get our extended key
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
        add bx,0a0h                     ;+160 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.left:
;-2
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        sub bx,02h                      ;-2 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.right:
;+2
        mov ax,[u_cursor]               ;load ax
        mov word [es:bx],ax             ;put in the old colour beneath cursor
        add bx,02h                      ;+2 position and then redraw
        mov ax,[es:bx]                  ;load ax
        mov word [u_cursor],ax          ;store our new positions colour for later
        mov word [es:bx],0fdbh          ;draw our new cursor position
        jmp main_l
.altx:
        jmp exit ;temp

.c_one:
        mov word [u_cursor],01dbh       ;place the new colour into under-cursor
        jmp main_l                      ;this makes moving draw it onto the screen
.c_two:
        mov word [u_cursor],02dbh
        jmp main_l
.c_three:
        mov word [u_cursor],03dbh
        jmp main_l
.c_four:
        mov word [u_cursor],04dbh
        jmp main_l

;===            Process Key
exit:
        mov ax,4c00h
        int 21h
;===            CALLS
;
;       DRAW STATUS
;
;   Draws that statusline part of the user interface.
draw_status:
        mov di,0f00h                    ;Initialize our pointer into VGA (es:di) to the right coordinate.

        mov ax,71cfh                    ;Draw our first block.
        stosw

        mov ah,0fh                      ;Initialize the first colour of the colourbar.
        mov al,30h
        mov cx,0ah                      ;we're going to jump after 10 iterations to account for 0x39 9 -> 0x41 A
.cl:                                    ;draw colours 0-A in status bar.
        stosw
        add ah,10h                      ;increment the background colour.
        inc al
        loop .cl

        cmp al,47h                      ;Skip ahead if we're done printing 0-A
        jz  .cl_dn
        sub ah,0fh                      ;Change to black foreground text.
        mov al,41h                      ;skip to 0x41 A
        mov cx,06h
        jmp .cl
.cl_dn:

        mov ax,7020h
        mov cx,07h
.fill1:
        stosw
        loop .fill1

        ;filename
        ret
        ; if modified * (Seperate function for quickly updating this?)

        ;fill in

        ;draw 0-4 selected colours <-
    
        ret

;       CLEAR SCREEN cls
;
;   Destroys cx and bx.
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