;========================================================================16OKT13WIN
;=PBINGEN Version 2. PX Count version
;================================================================================== 
org 100h

segment .code
;================PERFORM CLI
cli_main:
        mov si,0080             ;use source index for most of our cli.
        lodsb
        cmp al,0
        jz .no_arg
.m_l:
        lodsb
        cmp al,20h              ;skip spaces
        jz .m_l

        cmp al,'/'
        jz .switch

        cmp al,0dh
        jz .done

        jmp .input              ;[filename]
.switch:
        lodsb
        cmp al,'o'
        jz .output

        cmp al,'?'
        jz exit_help
        jmp exit
.file:
        stosb
        lodsb
        cmp al,20h              ;test against our only delim.
        jz .f_done

        cmp al,0dh              ;if we hit 0d we are at the end
        jz .done

        jmp .file
.output:
        mov di,newfile
        inc si              ;skip "o "
        lodsb
        jmp .file
.input:
        mov di,filename
        jmp .file
.f_done:
        xor al,al
        stosb
        jmp .m_l
.no_arg:
        ;?
.done:

;================OPEN THE FILE AND READ IT TO BUFFER.
open_file:
        call dump_arg
        call dump_buf
        mov ax,3d00h            ;OPEN FILE WITH 00 ACCESS,(SHOULD BE READ ONLY)
        mov dx,filename
        int 21h
        jc exit                 ;C FLAG MEANs ERROR.
        mov bx,ax               ;PUT FILE HANDLE IN BX

        mov ax,3f00h            ;READ FILE.
        mov cx,0fa0h            ;4000 byte buffer sets maximum read.
        mov dx,file_buffer      ;give function the address to our buffer.
        int 21h
        jc exit

        mov ax,3e00h            ;CLOSE FILE
        int 21h
        jc  exit                ;If we fail to close the file? Uh...

;================CONFIRM THE FILE
;CX CONTAINS BYTES READ, WE NEED THAT FOR AFTER.
;No we don't.
        cmp word [file_buffer],"BM"     ;4D42h
        jnz exit_bmp            ;This is not a BMP file. EXIT NOW.
        ;CHECK PX/BYTE CRAP HERE, WE ONLY WANT 4BPP

;=================SET UP FOR LOOP.
        ;GET OUR PADDED LINE PX LEN
        xor dx,dx                               ;Clear DX for our DIVision
        mov ax, word [file_buffer+0022h]        ;Put size of array into AX (BYTE)
        shl ax,01h                              ;Multiply AX by two. BYTE -> PX
        div word [file_buffer+0016h]            ;Get LINE+PAD by Dividing SIZE W/ HEIGHT
        mov word [line_len_padded],ax           ;Store our line len with pad.

        ;GET OUR LINE PX LEN AND PADDING LEN
        mov dx, word [file_buffer+0012h]        ;Get width of image in PX from BMP header.
        sub ax,dx
        mov word [padding_len],ax               ;Put padding len into memory PX
        mov word [line_len],dx                  ;Put line length into memory PX

        ;GET OUR SCREEN-WIDTH PADDING SIZE (screenWidthCol - lineWPadPx)
        ;;THE NATURE OF THIS IS TO CREATE 80COLLUMN IMAGES. THERE'S NO ENDLINE CHAR FOR DRAWER TO PROCESS.
        mov cx,0050h                            ;put screenwidthcol in cx
        sub cx,dx                               ;subtract line_len
        mov word [eighty_pad],cx                ;store result as eightypads

        ;GET OFFSET TO PIXEL ARRAY
        mov bx, word [file_buffer+000ah]        ;Get pixel array offset from BMP header
        mov cx, word [file_buffer+0022h]        ;Get BYTE size of pixel array!
            ;^IDEA move ENTIRE address into BX.

        ;SET UP COUNTERS FOR LOOP
        mov dx, word [line_len]                 ;get line length in px
                                                ;We're getting line_len from further up. Delete?
        xor di,di                               ;Clean di register before us, otherwise errors might occurr.
;=================LOOP BEGIN, PROCESS ONE BYTE AT THE TIME
;                 BUT THE ELEMENTS PROCESSED ARE COUNTED AS PIXELS.
process_loop:
        mov al,[file_buffer+bx] ;get byte from pixel array
        inc bx                  ;increment read address.
        mov ah,al               ;copy byte into ah
        shr ah,04h              ;shift four bytes to put high into low nibble
        and al,0fh              ;and out high nibble and keep low nibble.

        mov [outp_buffer+di],ah ;write high nibble into new file
        inc di                  ;incremenet writing address by one byte
        dec dx                  ;decrement line_lenght in pixels.
        jz  .eighty_pad         ;are we out of pixels?
        mov [outp_buffer+di],al ;write low nibble into new file.
        inc di                  ;increment writing address by one byte.
        dec dx                  ;decrement line_length in pixels
        jz  .eighty_pad         ;are we out of pixels?

        loop process_loop       ;loop back if we still have bytes left to read.
        jmp write_file          ;jump to file write
.eighty_pad:
        mov dx,[line_len]
        mov ax,[padding_len]    ;get pad length in px.
        shr ax,01h              ;divide to get raw byte integers. (Hopefully rounded down)
        cmp ax,00h              ;if we don't have any padding, we don't need eighty pad.
        jz  process_loop        ;CX does not need to be decremented as there are NO PADDED BYTES.
        add bx,ax               ;increment bx by bytes
        sub cx,ax               ;decrement cx by bytes
        mov ax,[eighty_pad]     ;put eighty pad PX into ax
.eighty_pad_loop:
        mov byte [outp_buffer+di],00h   ;move 0x00 into our new file to pad to eighty columns wide
        inc di                  ;increment writing address.
        dec ax                  ;decrement eighty pad counter
        jnz .eighty_pad_loop    ;if we are not at zero, loop.
        loop process_loop       ;are there bytes left to read?

write_file:
        mov ah,3ch
        mov dx,newfile
        mov cx,0000h
        int 21h
        jc exit
        mov bx,ax

        mov ah,40h
        mov cx,di
        mov dx,outp_buffer
        int 21h
        jc exit

        mov ah,3eh
        int 21h

        xor al,al
exit:
        mov ah,02h
        mov dl,al
        int 21h
        mov ah,4ch
        int 21h
exit_help:
        mov ah,02h
        mov dl,"A"
        int 21h

        mov ax,4ca0h
        int 21h
exit_bmp:
        mov ax,4c66h
        int 21h

;debug.
dump_arg:
        mov si,0081h
.lp:
        lodsb
        mov ah,02h
        or al,al
        jz .done
        mov dl,al
        int 21h
        jmp .lp
.done:
        mov dl,0dh
        int 21h
        mov dl,0ah
        int 21h
        ret

dump_buf:
        mov bx,filename
        mov ah,02h
        mov dl,41h
        int 21h
.fl:
        mov dl,[bx]
        inc bx
        or dl,dl
        jz .nx
        int 21h
        jmp .fl
.nx:
        mov dl,0dh
        int 21h
        mov dl,0ah
        int 21h
        mov dl,42h
        int 21h
        mov bx,newfile
.nf:
        mov dl,[bx]
        inc bx
        or dl,dl
        jz .dn
        int 21h
        jmp .nf
.dn:
        mov dl,43h
        int 21h
        ret
segment .data
eighty_pad:     dw 0000h
line_len        dw 0000h
line_len_padded dw 0000h
padding_len     dw 0000h

segment .bss
filename:       resb 127
newfile:        resb 127
file_buffer:    resb 4000
outp_buffer:    resb 4000