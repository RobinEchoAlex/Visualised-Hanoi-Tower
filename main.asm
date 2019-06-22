; ref http://devdocs.inightmare.org/tutorials/x86-assembly-graphics-part-i-mode-13h.html
.286
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
    DISP DB 0AH , 0DH , ' MOVE ONE FROM '
SRC DB ?
    DB ' TO '
DST DB ? 
    DB 0AH , 0DH , '$'                            
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
    MOV PLATE_NUM,4            ;TODO can be customised
    call init_plate   
    
    MOV AX,PLATE_NUM
    MOV SI,word ptr 'A'
    MOV BX,word ptr 'B'
    MOV DI,word ptr 'C'
    PUSH AX
    PUSH SI
    PUSH BX
    PUSH DI
    CALL HANOI_CON

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
    MOV CX,9
    MOV DX,PLATE_NUM    ;loop counter
    MOV SI,10
    MOV DI,35  
ip_loop1: 
    MOV BX,pillarA+2    ;calculate X
    SUB BX,DI 
    SUB DI,3
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
    MOV BX,15            ;calculate height
    MOV pillarA[SI],BX
    ADD SI,2         
    MOV BX,CX            ;assemble colour
    MOV BL,PALATTE[BX]
    MOV BH,0
    MOV pillarA[SI],BX  
    ADD SI,2 
    INC pillarA
    call DRAW_PLATE
    DEC CX
    DEC DX
    JNZ ip_loop1          
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

ERASE_PLATE PROC NEAR
    PUSHA
    MOV SI,0
    CMP active_pillar,0          ;locate which pillar
    JZ ep_deviation    
    ADd SI,100                   ;point to B pillar
    CMP active_pillar,1
    JZ ep_deviation
    ADD SI,100                   ;point to C pillar
ep_deviation:
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
oe_loop:
    MOV DX,pillarA[SI+4]       ;DX = half width of box 
    SHL DX,1                      
ie_loop:           
    MOV BX,0          
    MOV es:[di],BX   ;colour of the box
    INC DI
    DEC DX
    JNZ ie_loop
    POP DI
    ADD DI,320
    PUSH DI
    LOOP oe_loop
    POP DI 
    POPA
    RET
ERASE_PLATE ENDP
    
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
  
HANOI_CON PROC NEAR
    PUSH BP
    MOV BP,SP
    MOV AX,10[BP]
    MOV SI,8[BP]
    MOV BX,4[BP]
    MOV DI,6[BP]
    CMP AL,1
    JZ move_one
    DEC AX
    PUSH AX
    PUSH SI
    PUSH BX
    PUSH DI
    CALL HANOI_CON ;set parameters and call hanoi to move n-1 plates
    
    MOV SI,8[BP]
    MOV DI,4[BP]
    PUSH SI
    PUSH DI
    CALL MOVE_PLATE
    
    MOV AX,10[BP]
    MOV SI,6[BP]
    MOV BX,8[BP]
    MOV DI,4[BP]
    DEC AX
    PUSH AX
    PUSH SI
    PUSH BX
    PUSH DI
    CALL HANOI_CON
    JMP exit_hanoi
move_one:
    MOV SI,8[BP]
    MOV DI,4[BP]
    PUSH SI
    PUSH DI
    CALL MOVE_PLATE
exit_hanoi:
    POP BP 
    RET 8
HANOI_CON ENDP

MOVE_PLATE PROC NEAR
    PUSH BP
    MOV BP,SP
    PUSHA
    MOV AX,6[BP]
    MOV SRC,AL
    SUB AL,41H      ;'ABC' to 012  
    MOV active_pillar,AX
    CALL ERASE_PLATE
    
    MOV SI,0
    CMP active_pillar,0          ;locate which pillar
    JZ mp_move1    
    ADD SI,100                   ;point to B pillar
    CMP active_pillar,1
    JZ mp_move1
    ADD SI,100                   ;point to C pillar
    
mp_move1:    
    MOV AX,pillarA[SI]
    DEC pillarA[SI]         ;number of the plate in the pillar--
    MOV BX,10
    MUL BL                  ;deviation is the number of plates(AX) * the bytes every plate take & head info(10)
    ADD SI,AX               ;SI point to the start byte of the plate to move
    
    MOV AX,4[BP]
    MOV DST,AL
    SUB AL,41H
    MOV active_pillar,AX 
    
    MOV DI,0
    CMP active_pillar,0          ;locate which pillar
    JZ mp_move2    
    ADD DI,100                   ;point to B pillar
    CMP active_pillar,1
    JZ mp_move2
    ADD DI,100                   ;point to C pillar
    
mp_move2:
    INC pillarA[DI]         ;number of plate in the pillar++ 
    MOV CX,pillarA[DI+2]    ;CX= X coor of target pillar  
    MOV DX,pillarA[DI]      ;DX  = number of plate, for use in calculating Y
    MOV AX,pillarA[DI]
    MOV BX,10
    MUL BL                  ;deviation is the number of plates(AX) * the bytes every plate take & head info(10)
    ADD DI,AX               ;DI point to the start byte of the plate to placed
    
    MOV AX,pillarA[SI+4]    ;move the length
    MOV pillarA[DI+4],AX
    SUB CX,AX   
    MOV AX,CX               ;AX = X of the plate
    MOV pillarA[DI],AX      ;x of the plate is set
    
    MOV BX,15
    MOV AX,DX               ;AX= number of plate
    MOV DX,0
    MUL BL
    MOV CX,AX               ;CX = AX = 15*number of plate
    MOV AX,180              
    SUB AX,CX               ;Y = 180 - 15*number of plate
    MOV pillarA[DI+2],AX
    
    MOV AX,BOX_HEIGHT
    MOV pillarA[DI+6],AX
    
    MOV AX,pillarA[SI+8]
    MOV pillarA[DI+8],AX    ;colour
    
    CALL DRAW_PLATE
    ;MOV AH,9
;    LEA DX,DISP
;    INT 21H         


    MOV CX,65535
delay:
    LOOP delay 
    MOV CX,65535
delay2:
	LOOP delay2
    
    POPA
    POP BP
    RET 4
MOVE_PLATE ENDP

code ends
end main


