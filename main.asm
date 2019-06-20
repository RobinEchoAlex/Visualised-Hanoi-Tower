; ref http://devdocs.inightmare.org/tutorials/x86-assembly-graphics-part-i-mode-13h.html
;.286
data segment     
    PLATE_NUM DW 0
    pillarA dw 0,60,180,'A',0,45 dup(0)
    pillarB dw 0,160,180,'A',0,45 dup(0)
    pillarC dw 0,260,180,'A',0,45 dup(0)  
    BOX_HEIGHT EQU 15
    PILLAR_Y EQU 30
    PILLAR_COLOUR EQU 15
    PALATTE DB 2,126,150,172,195,213,43,12,7,31 
    active_pillar dw 0          ;use to pass parameter to DRAW_PLATE and ERASE_PLATE
                                ;0 for A, 1 for B, 2 for C
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
    ;call draw_base
    ;call draw_pillar
    ;call draw_box
    MOV PLATE_NUM,9             ;TODO can be customised
    call init_plate

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

INIT_PLATE PROC NEAR
    PUSHA
    MOV active_pillar,0
    MOV CX,PLATE_NUM
    MOV SI,10
    MOV DI,35
ip_loop1:
    MOV BX,pillarA+2    ;calculate X
    SUB BX,DI 
    SUB DI,3
    ADD BX,20           ;add the left blank
    MOV pillarA[SI],BX  
    ADD SI,2
    MOV AX,10       ;calculate Y
    SUB AX,CX       ;equals to num-CX+1
    MOV BL,15
    MUL BL
    MOV BX,AX
    MOV AX,180
    SUB AX,BX
    MOV pillarA[SI],AX
    ADD SI,2
    ADD DI,3             ;calculate length
    MOV pillarA[SI],DI    
    SUB DI,3
    ADD SI,2        
    MOV BX,15           ;calcullate height
    MOV pillarA[SI],BX
    ADD SI,2         
    MOV BX,CX            ;assemble colour
    MOV BL,PALATTE[BX]
    MOV BH,0
    MOV pillarA[SI],BX  
    ADD SI,2 
    INC pillarA
    call DRAW_PLATE
    LOOP ip_loop1           
    POPA
    RET
INIT_PLATE ENDP

DRAW_PLATE PROC NEAR
    PUSHA
    MOV SI,0
    CMP active_pillar,0      ;locate which pillar
    JZ de_deviation    
    ADd SI,100                   ;point to B pillar
    CMP active_pillar,1
    JZ de_deviation
    ADD SI,100                   ;point to C pillar
de_deviation:
    MOV AX,pillarA[SI]
    MOV BX,10
    MUL BL                  ;deviation is the number of plates(AX) * the bytes every plate take & head info(10)
    ADD SI,AX
    mov ax, 0A000h ; the offset to video memory
    mov es, ax ; load it to ES through AX, becouse immediate operation is not allowed on ES
    MOV DX,0
    MOV BX,pillarA[SI+2]    ;start row
    MOV AX,320
    MUL BX  
    MOV DI,AX   ;start row's address
    ADD DI,pillarA[SI]    ;add start column
    PUSH DI     ;save the start address
    MOV CX,BOX_HEIGHT  ;CX = height of box
o_loop:
    MOV DX,pillarA[SI+4]       ;DX = half width of box 
    SHL DX,1                      
i_loop:           
    MOV BX,pillarA[SI+8]           
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
DRAW_PLATE ENDP
    
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
dp_loop1:
    ADD DI,60
    MOV es:[di],BX
    ADD DI,100
    MOV es:[di],BX 
    ADD DI,100
    MOV es:[di],BX 
    ADD DI,60
    LOOP dp_loop1  
    POPA
    RET
DRAW_PILLAR ENDP

DRAW_BOX PROC NEAR  
    PUSHA
    POPA
    RET
DRAW_BOX ENDP

code ends
end
