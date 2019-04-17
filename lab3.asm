; 1st var

.model small
.stack 100h
.data 
    entrInBsStr db "Enter initial base (2-16, DECIMAL):", 0Dh, 0Ah, '$'
    entrInNumStr db 0Dh, 0Ah, "Enter initial number:",
                 db 0Dh, 0Ah, "(+/- 65535 (dec) is max value for a correct result)",
                 db 0Dh, 0Ah, '$'
    entrNewBsStr db 0Dh, 0Ah, "Enter new base (2-16):",
                 db 0Dh, 0Ah, '$'
    trnslStr db 0Dh, 0Ah, "Translated number:",
             db 0Dh, 0Ah, '$'
    overStr db 0Dh, 0Ah, "Overflow happened!", 0Dh, 0Ah, '$'
    illStr db 0Dh, 0Ah, "Illegal characters!", 0Dh, 0Ah, '$'
    wrongBsStr db 0Dh, 0Ah, "Illegal base!", 0Dh, 0Ah, '$'
    wrongNumStr db 0Dh, 0Ah, "Illegal! Number does not suit the base!", 
               db 0Dh, 0Ah, '$'
    errStr db "Program terminated!", 0Dh, 0Ah, '$'
    emptyStr db 0Dh, 0Ah, "Nothing has been entered!",
	         db 0Dh, 0Ah, '$' 
	simBssStr db 0Dh, 0Ah, "Bases are equal!",
	          db 0Dh, 0Ah, " No need for translation!", 
	          db 0Dh, 0Ah, '$'            
	tmp db 200,?,200 dup('$')
	inNum dw 0h
	inBase dw 0h
	finBase dw 0h
	finNum dw 0h
	isNegative dw 0h
.code
;;;;;;;;;;;;;;;;;; 
display macro string
    lea dx, string
    mov ah, 09h
    int 21h
endm 
;;;;;;;;;;;;;;;;;
input macro string
    lea dx, string
    mov ah, 0Ah
    int 21h
endm
;;;;;;;;;;;;;;;;;;;;;;;;;
main:
    mov ax, @data
    mov ds, ax  
        
    display entrInBsStr
    
    input tmp
    xor ax, ax     
    mov al,tmp[1]
    cmp al,0
    je empty     
    
    push ax
    push 10
    lea di, tmp+2
    call atoi
    jo overflow
    cmp dx, 0xFFFFh 
    je illChar 
    cmp dx, 0xEEEEh
    je illNum 
    cmp dx, 1h
    je illBase
    mov inBase, ax  ;<<<<
    push inBase
    call checkBase 
    cmp dx, 0h
    je illBase
    
    display entrInNumStr
    
    input tmp
    xor ax, ax     
    mov al,tmp[1]
    cmp al,0
    je empty     
    
    push ax
    push inBase
    lea di, tmp+2
    call atoi
    jo overflow
    cmp dx, 0xFFFFh 
    je illChar
    cmp dx, 0xEEEEh 
    je illNum
    mov inNum, ax
    cmp dx, 1h
    jne signConfirmed
    inc isNegative
    
signConfirmed:
    display entrNewBsStr
    
    input tmp
    xor ax, ax     
    mov al,tmp[1]
    cmp al,0
    je empty     
    
    push ax
    push 10
    lea di, tmp+2
    call atoi
    jo overflow
    cmp dx, 0xFFFFh 
    je illChar
    cmp dx, 0xEEEEh
    je illNum 
    cmp dx, 1h
    je illBase
    mov finBase, ax  ;<<<<
    push finBase
    call checkBase 
    cmp dx, 0h
    je illBase
    
    mov ax, inBase
    cmp ax, finBase
    je simBases
      
    push inNum
    push finBase
    lea di, tmp+2    
    call translate     
    
    display trnslStr
    push isNegative
    push finBase 
    call printInRevOrder
    
    jmp end
illChar:
    display illStr
    jmp error
illBase:
    display wrongBsStr
    jmp error
illNum:
    display wrongNumStr
    jmp error
overflow:
    display overStr
    jmp error
simBases:
    display simBssStr
    jmp end 
empty:
    display emptyStr
    jmp end    
error:
    display errStr     
end:
    mov ax, 4c00h
    int 21h
    
;;;;;;;;;;;;;;;;
atoi proc near
;stack contains: base 
;puts sign in dx
    push bp
    mov bp, sp
    mov bx, [bp+4]
    
    mov cx, ax   ;amount 
    xor dx, dx
    sign dw 0h
    tmpVal dw 0h 
    mov sign, dx  ;to clear sign field
    mov tmpVal, dx  ;to clear sign field
;sign check
    mov dl, [di]
    mov ax, dx
    cmp ax, '+'
    je signConf
    cmp ax, '-'
    jne start
    inc sign
signConf:
    inc di
    dec cx
start:    
    xor ax, ax
    xor dx, dx
next:
    mul bx    
    jo finish1    
    
    mov dl, [di] 
    mov tmpVal, ax
    mov ax, dx 
    
lowCheck:    
    cmp al, 'f'
    ja  charLocated
    cmp al, 'a'
    jb highCheck
    sub dl, 57h
    jmp checksPassed
    
highCheck:
    cmp al, 'F'
    ja  charLocated
    cmp al, 'A'
    jb numCheck
    sub dl, 37h
    jmp checksPassed
     
numCheck:
    cmp al, '9'
    ja  charLocated
    cmp al, '0'
    jb charLocated
    sub dl, 30h 
 
checksPassed:
    cmp bl, dl
    jbe wrongBase
            
possOvflwCheck:
    mov ax, tmpVal
    cmp ax, 0xFFF1h
    jbe noOverflow
    add ax, dx
    cmp ax, 3h
    ja noOverflow 
;costyil to catch overflow flag
    mov ax, tmpVal
    mul bx
    jo finish1
    
noOverflow:    
    mov ax, tmpVal
    add ax, dx
    jo finish1 
    inc di
    loop next
     
    mov dx, sign
    jmp finish1
wrongBase:
    mov dx, 0xEEEEh
    jmp finish1
charLocated:
    mov dx, 0xFFFFh
finish1:
    pop bp
    ret
atoi endp
;;;;;;;;;;;;;;;;   
checkBase proc near
;stack contains: base for checking
    push bp
    mov bp, sp
    mov bx, [bp+4]        
    
    mov ax, 2
    cmp bx, ax
    jl wrong2
    mov ax, 16
    cmp bx, ax
    ja wrong2
    mov dx, 0x1h
    jmp finish2
wrong2:
    xor dx, dx
finish2:
    pop bp
    ret
checkBase endp 
;;;;;;;;;;;;;;;;
translate proc near
; stack contains: new base, initial number
    push bp
    mov bp, sp
    mov bx, [bp+4]  ;base
    mov ax, [bp+6]  ;number
    
    xor cx, cx
    dec di
again:
    inc di        
    xor dx, dx
    div bx
    mov [di], dl 
    inc cx
    cmp ax, 0
    ja again
    
    pop bp
    ret
translate endp
;;;;;;;;;;;;;;;;
printInRevOrder proc near 
;stack contains: base, sign
    push bp
    mov bp, sp
    mov bx, [bp+4]
    mov ax, [bp+6]
    cmp ax, 0h
    je nexta
    mov dx, '-'
    inc di
    inc cx
    jmp lowerThan9
nexta:
    mov dl, [di]
    add dx, 30h
    cmp dx, 39h
    jle lowerThan9
    add dx,7
lowerThan9:
    mov ah, 2
    int 21h
     
    dec di
    loop nexta  
    
    pop bp
    ret
printInRevOrder endp
;;;;;;;;;;;;;;;;;;;;;;
end main 
