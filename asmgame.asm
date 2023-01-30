[BITS 16]
[ORG 0x7C00]

;macros
;definitions
%define YELLOW 0x0E
%define BLACK 0x00

%define RECTANGLE_WIDTH 0x40
%define RECTANGLE_WIDTH_HALF 0x20
%define RECTANGLE_WIDTH_PLUS 0x51
%define RECTANGLE_HEIGHT 0x10
%define RECTANGLE_HEIGHT_PLUS 0x15


;functions
%macro CLS 0
	xor di,di
	mov al, 0x0F
	mov cx, 0xFA00 ;framebuffer size
	repe stosb 
%endmacro 

%macro DRAW_RECTANGLE 0
	xor dx, dx
	.ball_draw_loop_rect:
	push dx
		mov word ax, 320
		mov word bx, [draw_y]
		add word bx, dx

		mul bx
		add word ax, [draw_x]
		mov di, ax
		mov al, YELLOW
		mov cx, RECTANGLE_WIDTH 
		repe stosb
	pop dx

	inc dx 


	
	cmp dx, RECTANGLE_HEIGHT
	jl .ball_draw_loop_rect
%endmacro

%macro DRAW_WALL_RECTANGLE 0

	xor dx, dx

	
	.wall_draw_loop_rect:
	push dx
		mov word ax, 320
		mov word bx, [draw_y]
		add word bx, dx
		mul bx
		add word ax, [draw_x]
		mov di, ax
		mov al, [draw_x]
		mov cx, RECTANGLE_WIDTH
		
		repe stosb
	pop dx
	inc dx
	cmp dx, RECTANGLE_HEIGHT
	jl .wall_draw_loop_rect
%endmacro

%macro DRAW_BALL 0
	xor dx, dx
	.ball_draw_loop_ball:
	push dx
		mov word ax, 320

		mov word bx, [ball_y]
		add word bx, dx
		mul bx
		add word ax, [ball_x]
		mov di, ax
		mov al, BLACK
		
		mov cx, 0x02
		repe stosb
	pop dx
	inc dx 

	cmp dx, 0x02
	jl .ball_draw_loop_ball
%endmacro

%macro BALL_COLLISION 0
	mov ax, [ball_dx]
	mov bx, [ball_dy]
	mov cx, [ball_x]
	cmp cx, 0
	
	cmovl ax, [one]
	cmp cx, 320
	cmovg ax, [neg_one]
	mov cx, [ball_y]
	cmp cx, 0
	cmovl bx, [one]
	cmp cx, 200
	cmovg cx, [zero]

	mov [ball_y], cx
	mov [ball_dx], ax
	mov [ball_dy], bx
%endmacro

%macro BALL_PLAYER_COLLISION 0
	mov cx, [ball_dx]
	mov ax, [ball_y]
	mov bx, [player_y]
	add ax, 0x02
	cmp ax, bx 
	jl .continue_ball_player_collision
	
	mov ax, [ball_x]
	mov bx, [player_x]
	cmp ax, bx
	jl .continue_ball_player_collision
	add bx, RECTANGLE_WIDTH
	cmp ax, bx
	jg .continue_ball_player_collision
	
	sub bx, RECTANGLE_WIDTH_HALF

	
	sub ax, bx
	jl .branch

	shr ax, 2

	jmp .branch_continue
	.branch:

	mov ax, -1

	.branch_continue:
	
	cmovz ax, [one]
	mov [ball_dx], ax
	mov word [ball_dy], word -1


	.continue_ball_player_collision:
%endmacro

%macro BALL_RECT_COLLISION 0
	mov cx, [ball_dx]
	mov dx, [ball_dy]
	mov ax, [ball_x]
	mov bx, [draw_x]

	cmp ax, bx

	cmove cx, [neg_one]
	jl .continue_ball_rect_collision
	add bx, RECTANGLE_WIDTH
	cmp ax, bx
	cmove cx, [one]
	jg .continue_ball_rect_collision
	mov ax, [ball_y]
	mov bx, [draw_y]
	cmp ax, bx 
	cmove dx, [neg_one]
	jl .continue_ball_rect_collision
	add bx, RECTANGLE_HEIGHT
	cmp ax, bx 
	cmove dx, [one]
	
	jg .continue_ball_rect_collision
	mov [ball_dx], cx
	mov [ball_dy], dx

	.continue_ball_rect_collision:
%endmacro


%macro WAIT_FOR_RTC 0
	;synchronizing game to real time clock (18.2 ticks per sec)
	.sync:
		xor ah,ah
		sti
		int 0x1a ;returns the current tick count in dx
		cli
		cmp word [timer_current], dx
	je .sync ;reloop until new tick
		mov word [timer_current], dx ;save new tick value
%endmacro

start:
cli
xor ax, ax
mov ds, ax; setting data segment to zero
mov ss, ax; setting up stack segment
mov sp, 0x7C00 ;setting up stackpointer (just before the loaded bootsector)
mov ax, 0xA000 ;beginning of the framebuffer
mov es, ax; setting the extra segment for pixel drawing purposes

;setting 320x200 256 colors graphics mode
mov ax, 0x0013
sti
int 0x10 
cli

main_gameloop:
	CLS 

	in al, 0x60 ;reading current keyboard input

	cmp al, 0x1F ;Key S
	je .player1_input_w
	.player1_input_w_continue:

	cmp al, 0x20 ;Key D
	je .player1_input_s
	.player1_input_s_continue:

	jmp .continue

	.player1_input_w:
	


	mov ax, [player_x]
	sub ax, 4
	mov [player_x], ax

	jmp .continue

	.player1_input_s:
	


	mov ax, [player_x]
	add ax, 4

	mov [player_x], ax
	

	.continue:
	mov dx, [player_x]
	mov [draw_x], dx
	mov dx, [player_y]


	mov [draw_y], dx

	
	DRAW_RECTANGLE

	BALL_COLLISION

	BALL_PLAYER_COLLISION
	
	mov word [draw_x], 10

	mov word [draw_y], 10 

	xor ax, ax

	.scan:
	
	BALL_RECT_COLLISION
	DRAW_WALL_RECTANGLE
	

	.scan_continue:
	
	mov ax, [draw_y]
	add ax, RECTANGLE_HEIGHT_PLUS
	mov [draw_y], ax 
	cmp ax, 0x5E
	jl .scan

	mov word [draw_y], 10

	mov ax, [draw_x]
	add ax, RECTANGLE_WIDTH_PLUS 
	mov [draw_x], ax 
	cmp ax, 0x14E
	jl .scan

	mov ax, [ball_x]
	add ax, [ball_dx]
	mov [ball_x], ax
	mov ax, [ball_y]
	add ax, [ball_dy]


	mov [ball_y], ax
	DRAW_BALL
	WAIT_FOR_RTC

jmp main_gameloop




.data:
tick dw 0
player_x dw 100
player_y dw 180

wall_x dw 0
wall_y dw 0

draw_x dw 0
draw_y dw 0


ball_x dw 160

ball_y dw 100
ball_dx dw 1
ball_dy dw 1
zero dw 0
one dw 1
neg_one dw -1

timer_current dw 0

MARK dq 0xFFFFFFFF

%assign sizeOfProgram $ - $$
%warning Size of the program: sizeOfProgram bytes

;padding to fill up the bootsector
times 510 - ($-$$) db 0

;bootsector marker
dw 0xAA55
