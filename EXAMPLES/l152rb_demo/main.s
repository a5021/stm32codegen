	.cpu cortex-m3
	.arch armv7-m
	.fpu softvfp
	.eabi_attribute 20, 1
	.eabi_attribute 21, 1
	.eabi_attribute 23, 3
	.eabi_attribute 24, 1
	.eabi_attribute 25, 1
	.eabi_attribute 26, 1
	.eabi_attribute 30, 2
	.eabi_attribute 34, 1
	.eabi_attribute 18, 4
	.file	"main.c"
	.text
	.section	.text._close,"ax",%progbits
	.align	1
	.p2align 2,,3
	.global	_close
	.syntax unified
	.thumb
	.thumb_func
	.type	_close, %function
_close:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r0, #-1
	bx	lr
	.size	_close, .-_close
	.section	.text._lseek,"ax",%progbits
	.align	1
	.p2align 2,,3
	.global	_lseek
	.syntax unified
	.thumb
	.thumb_func
	.type	_lseek, %function
_lseek:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r0, #-1
	bx	lr
	.size	_lseek, .-_lseek
	.section	.text._read,"ax",%progbits
	.align	1
	.p2align 2,,3
	.global	_read
	.syntax unified
	.thumb
	.thumb_func
	.type	_read, %function
_read:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r0, #-1
	bx	lr
	.size	_read, .-_read
	.section	.text._write,"ax",%progbits
	.align	1
	.p2align 2,,3
	.global	_write
	.syntax unified
	.thumb
	.thumb_func
	.type	_write, %function
_write:
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	@ link register save eliminated.
	mov	r0, #-1
	bx	lr
	.size	_write, .-_write
	.section	.text.startup.main,"ax",%progbits
	.align	1
	.p2align 2,,3
	.global	main
	.syntax unified
	.thumb
	.thumb_func
	.type	main, %function
main:
	@ Volatile: function does not return.
	@ args = 0, pretend = 0, frame = 0
	@ frame_needed = 0, uses_anonymous_args = 0
	ldr	r2, .L21
	push	{lr}
	ldr	r3, [r2, #28]
	orr	r3, r3, #2
	str	r3, [r2, #28]
	.syntax unified
@ 271 "./inc/cmsis_gcc.h" 1
	dsb 0xF
@ 0 "" 2
	.thumb
	.syntax unified
	ldr	r3, [r2]
	orr	r3, r3, #1
	str	r3, [r2]
.L7:
	ldr	r3, [r2]
	lsls	r0, r3, #30
	bpl	.L7
	ldr	r3, [r2, #8]
	orr	r3, r3, #1
	str	r3, [r2, #8]
	.syntax unified
@ 271 "./inc/cmsis_gcc.h" 1
	dsb 0xF
@ 0 "" 2
	.thumb
	.syntax unified
	ldr	r2, .L21
.L8:
	ldr	r3, [r2, #8]
	and	r3, r3, #12
	cmp	r3, #4
	bne	.L8
	.syntax unified
@ 271 "./inc/cmsis_gcc.h" 1
	dsb 0xF
@ 0 "" 2
@ 271 "./inc/cmsis_gcc.h" 1
	dsb 0xF
@ 0 "" 2
	.thumb
	.syntax unified
	mov	r0, #-536813568
	mvn	r5, #40960
	movw	r1, #1999
	mov	ip, #1
	mov	r4, #12582912
	ldr	lr, .L21+4
	ldr	r3, [r2, #28]
	str	r5, [lr]
	str	r1, [r0, #20]
	ldr	r2, [r0, #20]
	ldr	r3, .L21+8
	str	r2, [r0, #24]
	ldr	r2, [r3]
	str	ip, [r0, #16]
	adds	r2, r2, ip
.L12:
	ldr	r1, [r0, #16]
	ubfx	r3, r2, #9, #1
	adds	r3, r3, #6
	tst	r1, #65536
	lsl	r3, ip, r3
	beq	.L12
	lsls	r1, r2, #23
	ite	pl
	lslpl	r3, r3, #16
	strmi	r4, [lr, #24]
	str	r3, [lr, #24]
	adds	r2, r2, #1
	b	.L12
.L22:
	.align	2
.L21:
	.word	1073887232
	.word	1073873920
	.word	system_uptime
	.size	main, .-main
	.global	system_uptime
	.section	.bss.system_uptime,"aw",%nobits
	.align	3
	.type	system_uptime, %object
	.size	system_uptime, 8
system_uptime:
	.space	8
	.ident	"GCC: (Arm GNU Toolchain 15.2.Rel1 (Build arm-15.86)) 15.2.1 20251203"
