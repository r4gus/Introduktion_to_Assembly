.equ STDIN, 0x0
.equ STDOUT, 0x1
.equ STDERR, 0x2

.equ EXIT, 0x1
.equ READ, 0x3
.equ WRITE, 0x4
.equ OPEN, 0x5
.equ CLOSE, 0x6

.equ EXECVE, 0xb


.section .data
hello:	.asciz "Hello, ARM!"
str:	.byte 0,0,0,0,0,0,0,0,0,0,0,0,0

.section .text
.global _start

_start:
	ldr r0, =hello
	bl strlen
	mov r2, r0
	add r2, r2, #0x1
	ldr r0, =str
	ldr r1, =hello
	bl strncpy
	bl puts

	eor r0, r0
	mov r7, #EXIT
	svc 0

@ >>>>>>>>>>>>>>>>>>>>>>>>>> STRING FUNCTIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<

@ unsigned strlen(char* str)
@
@ Calculte the length of the string in bytes.
@
@ Arguments: 	1. Address of NULL terminated string
@ Returns: 	the length of the string (number of bytes up to but not including '\0')
.global strlen
strlen:
	push {lr}
	base 	.req r0
	acc	.req r1
	char	.req r2

	eor acc, acc			@ acc := 0
	
	strlen_count_loop:
		ldrb char, [base],#0x1
		cmp char, #0x0
		beq strlen_count_break	@ if char = '\0': break
		add acc, #0x1		@ acc += 1
		b strlen_count_loop
	strlen_count_break:

	mov r0, acc			@ return acc

	.unreq base
	.unreq acc
	.unreq char
	pop {pc}


@ char* strncpy(char* dest, char* src, unsigned n)
@ 
@ Copy the first n characters from src to dest.
@
@ Arguments:	1. Pointer to destination string
@		2. Pointer to source string
@		3. number of bytes to copy
@ Returns:	pointer to the destination string
.global strncpy
strncpy:
	push {r4, lr}
	dst .req r0
	src .req r1
	n   .req r2
	i   .req r3
	buf .req r4

	eor i, i		@ i := 0
	sub n, n, #0x1		@ n := n - 1
	
	@ copy byte wise
	strncpy_cpy_loop:
		cmp i, n
		bge strncpy_cpy_break

		ldrb buf, [src, i]	
		strb buf, [dst, i]

		add i, i, #0x1
		b strncpy_cpy_loop
	strncpy_cpy_break:
	
	eor i, i
	strb i, [dst, n]	@ dst[n] := '\0'

	.unreq dst
	.unreq src
	.unreq n
	.unreq i
	.unreq buf
	pop {r4, pc}



@ >>>>>>>>>>>>>>>>>>>>>>>>>> IO FUNCTIONS <<<<<<<<<<<<<<<<<<<<<<<<<<<<

@ void puts(char *str) 
@
@ Print the given string to standard out.
@
@ Arguments: 	1. Address of NULL terminated string
@ Returns: 	void	
.global puts
puts:
	push {r4, r5, r6, r8, lr}
	mov r8, sp
	saved_sp .req r8

	mov r4, r0
	bl strlen
	mov r5, r0

	src .req r4
	len .req r5

	@ allocate memory for the string
	@sub sp, sp, len, lsl #0x2		@ sp := sp - (strlen(str)*4)
	add len, #0x2
	sub sp, sp, len
	mov r6, sp
	buf .req r6

	@ copy the string on the stack
	mov r0, buf
	mov r1, src
	mov r2, len
	add r2, r2, #0x1
	bl strncpy

	@ append '\n' and '\0'
	mov r0, len
	mov r1, #0xa
	strb r1, [buf, r0]			@ buf[len] := '\n'
	add r0, r0, #0x1
	eor r1, r1
	strb r1, [buf, r0]			@ buf[len+1] := '\0'

	@ write to stdout
	mov r0, #STDOUT
	mov r1, buf
	mov r2, len
	add r2, r2, #0x1
	mov r7, #WRITE
	svc 0
	
	mov sp, saved_sp
	.unreq src
	.unreq len
	.unreq buf
	.unreq saved_sp

	pop {r4, r5, r6, r8, pc}









