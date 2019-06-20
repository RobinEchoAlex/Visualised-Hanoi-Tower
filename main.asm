; ref http://devdocs.inightmare.org/tutorials/x86-assembly-graphics-part-i-mode-13h.html
;.286
data segment
    pillarA dw 0,0,0,'A',45 dup(0)
    pillarB dw 0,0,0,'A',45 dup(0)
    pillarC dw 0,0,0,'A',45 dup(0)  
    BOX_HEIGHT EQU 2
    PILLAR_Y EQU 30
    PILLAR_COLOUR EQU 15
data ends

stack segment
    dw   1024  dup(0)
stack ends

code segment   
    assume ds:data,ss:stack,cs:code
MAIN PROC FAR                      
    
    mov ax, data
    mov ds, ax
    mov ax,stack
    mov ss,ax
    mov sp,1024
    mov ax,0
    
call init  
call draw_base
call draw_pillar
call draw_box


    mov ax, 4c00h ; exit to operating system.
    int 21h    
MAIN ENDP 

INIT PROC NEAR 
    PUSH AX 
    MOV AH,00H
    MOV AL,13H
    INT 10H
    POP AX 
    RET
INIT ENDP

DRAW_BASE PROC NEAR
    PUSHA   
    MOV AX,0A000H
    MOV ES,Ax
    MOV DX,0
    MOV SI,180
    MOV AX,320
    MUL SI
    MOV DI,AX
    ADD DI,20
    MOV AX,7
    MOV CX,80
    MOV DX,3
l1:
    MOV byte ptr es:[di],AL
    INC DI
    LOOP L1 
    ADD DI,20
    MOV CX,80
    DEC DX
    JNZ l1
    POPA
    RET
DRAW_BASE ENDP  

;print 3 pillar 
;whose x=60,160,260 respectively,
;y starts from 30 to 180
DRAW_PILLAR PROC NEAR
    PUSHA
    MOV AX,0A000H
    MOV ES,AX
    MOV DX,0
    MOV SI,PILLAR_Y
    MOV AX,320
    MUL SI
    MOV DI,AX
    MOV BX,PILLAR_COLOUR
    MOV CX,180-30
loop1:
    ADD DI,60
    MOV es:[di],BX
     ADD DI,100
    MOV es:[di],BX 
    ADD DI,100
    MOV es:[di],BX 
    ADD DI,60
    LOOP loop1  
    POPA
    RET
DRAW_PILLAR ENDP

DRAW_BOX PROC NEAR  
    PUSHA
    mov ax, 0A000h ; The offset to video memory
    mov es, ax ; We load it to ES through AX, becouse immediate operation is not allowed on ES
    MOV DX,0
    MOV SI,3    ;start row
    MOV AX,320
    MUL SI  
    MOV DI,AX   ;start row's address
    ADD DI,3    ;add start column
    PUSH DI     ;save the start address
    MOV CX,BOX_HEIGHT  ;CX = height of box
o_loop:
    MOV DX,30       ;DX = width of box
i_loop:           
    MOV BX,7           
    MOV es:[di],BX   ;colour of the box
    INC DI
    DEC DX
    JNZ i_loop
    POP DI
    ADD DI,320
    PUSH DI
    LOOP o_loop
    POP DI 
    POPA
    RET
DRAW_BOX ENDP

code ends
end
