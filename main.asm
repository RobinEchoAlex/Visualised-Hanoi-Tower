.286
data segment     
    PLATE_NUM DW 0
    pillarA dw 0,60,180,'A',0,45 dup(0)
    pillarB dw 0,160,180,'B',0,45 dup(0)
    pillarC dw 0,260,180,'C',0,45 dup(0)  
    BOX_HEIGHT EQU 15
    PILLAR_Y EQU 30
    PILLAR_COLOUR EQU 15
    PALATTE DB 2,0Dh,2Bh,2Dh,35h,40h,49h,51h,5Ah,68h
    active_pillar dw 0          ;use to pass parameter to DRAW_PLATE and ERASE_PLATE
                                ;0 for A, 1 for B, 2 for C     
    move_info_str DB 0AH , 0DH , ' MOVE 1 PLATE FROM '	;the string to print in the screen, since length is required in int 10h/ah 13h so end character '$' is not required 
src DB ?
    DB ' TO '
dst DB ? 							  
    disp_str_length dw ($-move_info_str)
    plate_half_width dw 0		;use to compare, if the drawing pointer reaches half-width of the plate, draw a white pillar instead of erasing  
    hint_str db 'Enter the number of plates, between 3-9:',
    			0AH,0DH,
    			"press any other key indicates 4 plates",
    			0Ah,0DH,0Ah,0Dh,'$'  
    delay_time dw 15             ;time to sleep, measured by system clock ticks  
    speed_down_str db "speed decreased!"
    speed_down_str_length dw ($-speed_down_str)
    speed_up_str db "speed increased!"
    speed_up_str_length dw ($-speed_up_str)
    speed_hint_str db "press [ to slow down, ] to speed up"
    speed_hint_str_length dw ( $-speed_hint_str)
    total_move_num dw 0,1,3,7,15,31,63,127,255,511,1023,2047 ;moves to complete, corresponding to num of plates                      
	current_move dw 0
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
    call set_vga 
    call draw_base
    call draw_pillar
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

    mov ax, 4c00h 
    int 21h    
MAIN ENDP 

INIT PROC NEAR
	PUSHA
	LEA DX,hint_STR
	MOV AH,9
	INT 21H
	MOV AH,1	;read user's choice
	INT 21H
	MOV AH,0
	SUB AL,30H
	CMP AL,0
	JB default_5
	CMP AL,9
	JA default_5
	MOV PLATE_num,AX
	JMP in_exit
default_5:
	MOV PLATE_num,5
in_exit:	
	POPA
	RET
INIT ENDP

SET_VGA PROC NEAR
	PUSH AX
	MOV AH,9 
    MOV AH,00H
    MOV AL,13H
    INT 10H
    POP AX
    RET
SET_VGA ENDP

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
    mov ax, 0A000h          ; the offset to video memory
    mov es, ax              ; load it to ES through AX, becouse immediate operation is not allowed on ES
    MOV DX,0
    MOV BX,pillarA[SI+2]    ;start row
    MOV AX,320
    MUL BX  
    MOV DI,AX               ;start row's address
    ADD DI,pillarA[SI]      ;add start column
    PUSH DI                 ;save the start address
    MOV CX,BOX_HEIGHT       ;CX = height of box
o_loop:
    MOV DX,pillarA[SI+4]    ;DX = half width of box 
    SHL DX,1                      
i_loop:           
    MOV BX,pillarA[SI+8]           
    MOV es:[di],BX          ;colour of the box
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
    mov plate_half_width,DX  
    SHL DX,1                     
ie_loop:    
	CMP plate_half_width,DX
	JNZ black
	MOV BX,PILLAR_COLOUR
	JMP colour_setting_finished
black:       
    MOV BX,0
colour_setting_finished:          
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
    MOV AX,[BP+10]
    MOV SI,[BP+8]
    MOV DI,[BP+6]
    MOV BX,[BP+4]
    CMP AL,1
    JE move_one		;plate_num=1 , end
    DEC AX
    PUSH AX
    PUSH SI
    PUSH BX
    PUSH DI
    CALL HANOI_CON ;set parameters and call hanoi to move n-1 plates
    
    MOV SI,[BP+8]
    MOV DI,[BP+4]
    PUSH SI
    PUSH DI
    CALL MOVE_PLATE    ;mov the last one
    
    MOV AX,[BP+10]
    MOV BX,[BP+8]
    MOV SI,[BP+6]
    MOV DI,[BP+4]
    DEC AX              ;n-1 plates
    PUSH AX
    PUSH SI
    PUSH BX
    PUSH DI
    CALL HANOI_CON       
    JMP exit_hanoi
move_one:
    MOV SI,[BP+8]
    MOV DI,[BP+4]
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
    SUB AL,41H                  ;'ABC' to 012  
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
    DEC pillarA[SI]              ;number of the plate in the pillar--
    MOV BX,10
    MUL BL                       ;deviation is the number of plates(AX) * the bytes every plate take & head info(10)
    ADD SI,AX                    ;SI point to the start byte of the plate to move
    
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
    call print_info_string
    INC  current_move
    call draw_progress_bar

    call delay
    
    POPA
    POP BP
    RET 4
MOVE_PLATE ENDP 

PRINT_INFO_STRING PROC NEAR
    PUSHA
    MOV AH,13h
    MOV AL,0
    MOV BH,0
    MOV BL,0100b		;red
    MOV CX,Disp_str_length
    MOV DL,1
    MOV DH,1
    PUSH DS
    POP ES
    LEA BP,move_info_str
    INT 10H
    POPA
    RET
PRINT_INFO_STRING ENDP  

DELAY PROC NEAR
    PUSHA      
    
    call speed_adj
    
    MOV AH,00H
    INT 1Ah
    
    MOV BX,DX    ;bx = lower byte of clock when enter
    MOV SI,CX    ;SI = higher byte of clock when enter
    ADD BX,delay_time    ;AX:BX = time to exit the delay, 14 times above the current clock
    INC SI       
    
delay_loop:
    MOV AH,00H
    INT 1Ah
    CMP SI,CX
    JE  exit
    CMP DX,BX
    JA  exit
    JMP delay_loop
exit:
    POPA
    RET
DELAY ENDP

SPEED_ADJ PROC NEAR
    PUSHA
    MOV AH,1
    INT 16H
    CMP AL,'['
    JZ sp_slow
    CMP AL,']'
    JZ sp_fast
    JMP sp_unchange

sp_slow:
    ADD delay_time,5
    MOV CX,speed_down_str_length 
    LEA bp,speed_down_str  
    JMP sp_change

sp_fast:
    SUB delay_time,5
    MOV CX,speed_up_str_length
    LEA bp,speed_up_str
    JMP sp_change
    
sp_change:
	MOV AL,0
    MOV BH,0
    MOV BL,1101b	;light magenta  
    MOV DL,1
    MOV DH,24
    PUSH DS
    POP ES 
    MOV AH,13H
    INT 10H
    MOV AH,0CH
    MOV AL,00H		;flush keyboard buffer
    INT 21H
    JMP sp_exit
    
    
sp_unchange:
	MOV CX,speed_hint_str_length
    LEA bp,speed_hint_str 
    MOV AL,0
    MOV BH,0
    MOV BL,1100b
    MOV DL,1
    MOV DH,23
    PUSH DS
    POP ES
    MOV AH,13H
    INT 10H

sp_exit:   
    POPA
    RET
SPEED_ADJ ENDP

;the number of pixels to print = current_move / total_move * pixel_num (320)   
;by applying exchange law, print = current_move * 320 / total_move 
;for convenience, the remainder is ignored
DRAW_PROGRESS_BAR PROC NEAR       
	PUSHA                         
    
    MOV AX,current_move
    MOV DX,0
    MOV BX,320 
    MUL BX
    MOV SI,plate_num
    SHL SI,1                      ;total num of moves is stored as word, so the pointer = plate_num *2
    MOV BX,total_move_num[SI]   ;retrieve total num of moves for current plate num
    DIV BX
    ;now AX stores the width of progress bar 
    MOV SI,AX				;SI stores width for outer loop recover
    MOV BX,0A000H
    MOV ES,bX  

treat_9:					;if plate num = 9, the first move is 0.6%, which is regarded as 0 in loop counter, causing FFFF loop problem
    CMP plate_num,9
    JNE normal
    CMP current_move,1
    JNE normal
    MOV SI,1
    
normal:
    MOV DI,0                ;start row's address
    PUSH DI                 ;save the start address
    MOV CX,5                ;CX = height of bar
m_o_loop:    
	MOV AX,SI                             
m_i_loop:           
    MOV BX,10               ;lime colour          
    MOV es:[di],BX          ;colour of the box
    INC DI
    DEC AX
    JNZ m_i_loop
    POP DI
    ADD DI,320
    PUSH DI
    LOOP m_o_loop
    POP DI
	POPA
	RET
DRAW_PROGRESS_BAR ENDP
 

code ends
end main











