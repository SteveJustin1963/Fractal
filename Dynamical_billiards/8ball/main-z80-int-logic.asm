;--------------------------------------------------------
; 8-Ball Game for ASM80.com
; Targeted for Z80 SBC with 8x8 LED Matrix
;--------------------------------------------------------

; I/O Port Definitions
PORT_ROW:  EQU 01H
PORT_COL:  EQU 02H
PORT_KBD:  EQU 03H

; Constants
SCALE:     EQU 16
MAX_COORD: EQU 112 ; 7 * 16

    ORG 0000H
    JP START

    ORG 0100H       ; Standard start for many Z80 monitors
START:
    LD SP,0FFFFH    ; Initialize Stack
    CALL INIT_RAM   ; Set up variables

;--------------------------------------------------------
; Main Game Loop
;--------------------------------------------------------
LOOP:
    IN A,(PORT_KBD) ; Read Keyboard
    OR A            ; Check if zero
    JR Z,PHYSICS    ; No key pressed, skip to physics
    
    LD C,A          ; Save key in C
    
    ; Cardinal movement (4, 6, 8, 2)
    CP '4'
    JR NZ,K6
    LD HL,(CUE_X)
    DEC HL
    LD (CUE_X),HL
K6:
    LD A,C
    CP '6'
    JR NZ,K8
    LD HL,(CUE_X)
    INC HL
    LD (CUE_X),HL
K8:
    LD A,C
    CP '8'
    JR NZ,K2
    LD HL,(CUE_Y)
    DEC HL
    LD (CUE_Y),HL
K2:
    LD A,C
    CP '2'
    JR NZ,K5
    LD HL,(CUE_Y)
    INC HL
    LD (CUE_Y),HL
K5:
    LD A,C
    CP '5'          ; SHOOT!
    JR NZ,PHYSICS
    CALL FIRE_BALL

;--------------------------------------------------------
; Physics Section
;--------------------------------------------------------
PHYSICS:
    LD A,(CUE_DX)
    LD B,A
    LD A,(CUE_DY)
    OR B
    JR Z,RENDER     ; If not moving, just draw

    ; Move X
    LD HL,(CUE_X)
    LD A,(CUE_DX)
    CALL SIGN_EXTEND
    ADD HL,DE
    LD (CUE_X),HL

    ; Move Y
    LD HL,(CUE_Y)
    LD A,(CUE_DY)
    CALL SIGN_EXTEND
    ADD HL,DE
    LD (CUE_Y),HL

    ; Simple Friction (reduce velocity)
    CALL APPLY_FRICTION

;--------------------------------------------------------
; Render Section (Multiplexing)
;--------------------------------------------------------
RENDER:
    ; Handle X (Columns)
    LD HL,(CUE_X)
    CALL GET_COORD  ; Returns 0-7 in A
    CALL BIT_MASK   ; Returns bit pattern (1,2,4...) in A
    OUT (PORT_COL),A

    ; Handle Y (Rows)
    LD HL,(CUE_Y)
    CALL GET_COORD
    CALL BIT_MASK
    OUT (PORT_ROW),A

    ; Small Delay
    LD DE,0200H
WAIT:
    DEC DE
    LD A,D
    OR E
    JR NZ,WAIT
    
    JP LOOP

;--------------------------------------------------------
; Subroutines
;--------------------------------------------------------

FIRE_BALL:
    ; Sets DX and DY based on current angle
    LD A,(ANGLE_IDX)
    LD E,A
    LD D,0
    LD HL,COS_LUT
    ADD HL,DE
    LD A,(HL)
    LD (CUE_DX),A
    LD HL,SIN_LUT
    ADD HL,DE
    LD A,(HL)
    LD (CUE_DY),A
    RET

GET_COORD:
    ; Divides HL by 16 (SCALE) to get 0-7
    LD B,4
DIV4:
    SRL H
    RR L
    DJNZ DIV4
    LD A,L
    AND 07H
    RET

BIT_MASK:
    ; Converts index 0-7 into bit position
    LD B,A
    INC B
    LD A,0
    SCF             ; Set Carry Flag
MASK_L:
    RLA             ; Rotate Carry into A
    DJNZ MASK_L
    RET

SIGN_EXTEND:
    ; Extends 8-bit A into 16-bit DE
    LD E,A
    RLA
    SBC A,A
    LD D,A
    RET

APPLY_FRICTION:
    ; Every few frames, move DX/DY closer to zero
    ; (Simplified for Z80 speed)
    LD HL,CUE_DX
    LD A,(HL)
    CP 0
    JR Z,FRIC_Y
    JP P,POS_X
    INC (HL)
    JR FRIC_Y
POS_X:
    DEC (HL)
FRIC_Y:
    LD HL,CUE_DY
    LD A,(HL)
    CP 0
    RET Z
    JP P,POS_Y
    INC (HL)
    RET
POS_Y:
    DEC (HL)
    RET

INIT_RAM:
    ; ASM80 variables initialized to zero usually, 
    ; but we set defaults here.
    LD HL,32
    LD (CUE_X),HL
    LD HL,64
    LD (CUE_Y),HL
    XOR A
    LD (CUE_DX),A
    LD (CUE_DY),A
    LD (ANGLE_IDX),A
    RET

;--------------------------------------------------------
; Data Tables (ROM)
;--------------------------------------------------------
COS_LUT: DB 8, 6, 0, -6, -8, -6, 0, 6
SIN_LUT: DB 0, 6, 8, 6, 0, -6, -8, -6

;--------------------------------------------------------
; Variable Storage (RAM)
;--------------------------------------------------------
    ORG 8000H       ; Putting variables in RAM
CUE_X:     DW 0
CUE_Y:     DW 0
CUE_DX:    DB 0
CUE_DY:    DB 0
ANGLE_IDX: DB 0

    END

