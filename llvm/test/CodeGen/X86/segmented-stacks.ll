; RUN: llc < %s -mcpu=generic -mtriple=i686-linux -verify-machineinstrs | FileCheck %s -check-prefix=X32-Linux
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-linux  -verify-machineinstrs | FileCheck %s -check-prefix=X64-Linux
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-linux -code-model=large -verify-machineinstrs | FileCheck %s -check-prefix=X64-Linux-Large
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-linux-gnux32 -verify-machineinstrs | FileCheck %s -check-prefix=X32ABI
; RUN: llc < %s -mcpu=generic -mtriple=i686-darwin -verify-machineinstrs | FileCheck %s -check-prefix=X32-Darwin
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-darwin -verify-machineinstrs | FileCheck %s -check-prefix=X64-Darwin
; RUN: llc < %s -mcpu=generic -mtriple=i686-mingw32 -verify-machineinstrs | FileCheck %s -check-prefix=X32-MinGW
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-freebsd -verify-machineinstrs | FileCheck %s -check-prefix=X64-FreeBSD
; RUN: llc < %s -mcpu=generic -mtriple=i686-dragonfly -verify-machineinstrs | FileCheck %s -check-prefix=X32-DFlyBSD
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-dragonfly -verify-machineinstrs | FileCheck %s -check-prefix=X64-DFlyBSD
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-mingw32 -verify-machineinstrs | FileCheck %s -check-prefix=X64-MinGW

; We used to crash with filetype=obj
; RUN: llc < %s -mcpu=generic -mtriple=i686-linux -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-linux -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-linux-gnux32 -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=i686-darwin -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-darwin -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=i686-mingw32 -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-freebsd -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=i686-dragonfly -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-dragonfly -filetype=obj -o /dev/null
; RUN: llc < %s -mcpu=generic -mtriple=x86_64-mingw32 -filetype=obj -o /dev/null

; RUN: not llc < %s -mcpu=generic -mtriple=x86_64-solaris 2> %t.log
; RUN: FileCheck %s -input-file=%t.log -check-prefix=X64-Solaris
; RUN: not llc < %s -mcpu=generic -mtriple=i686-freebsd 2> %t.log
; RUN: FileCheck %s -input-file=%t.log -check-prefix=X32-FreeBSD

; X64-Solaris: Segmented stacks not supported on this platform
; X32-FreeBSD: Segmented stacks not supported on FreeBSD i386

; Just to prevent the alloca from being optimized away
declare void @dummy_use(i32*, i32)

define void @test_basic() #0 {
        %mem = alloca i32, i32 10
        call void @dummy_use (i32* %mem, i32 10)
	ret void

; X32-Linux-LABEL:       test_basic:

; X32-Linux:       cmpl %gs:48, %esp
; X32-Linux-NEXT:  jbe	.LBB0_1

; X32-Linux:       pushl $0
; X32-Linux-NEXT:  pushl $44
; X32-Linux-NEXT:  calll __morestack
; X32-Linux-NEXT:  ret

; X64-Linux-LABEL:       test_basic:

; X64-Linux:       cmpq %fs:112, %rsp
; X64-Linux-NEXT:  jbe	.LBB0_1

; X64-Linux:       movabsq $40, %r10
; X64-Linux-NEXT:  movabsq $0, %r11
; X64-Linux-NEXT:  callq __morestack
; X64-Linux-NEXT:  ret

; X64-Linux-Large-LABEL:       test_basic:

; X64-Linux-Large:       cmpq %fs:112, %rsp
; X64-Linux-Large-NEXT:  jbe	.LBB0_1

; X64-Linux-Large:       movabsq $40, %r10
; X64-Linux-Large-NEXT:  movabsq $0, %r11
; X64-Linux-Large-NEXT:  callq *__morestack_addr(%rip)
; X64-Linux-Large-NEXT:  ret

; X32ABI-LABEL:       test_basic:

; X32ABI:       cmpl %fs:64, %esp
; X32ABI-NEXT:  jbe	.LBB0_1

; X32ABI:       movl $40, %r10d
; X32ABI-NEXT:  movl $0, %r11d
; X32ABI-NEXT:  callq __morestack
; X32ABI-NEXT:  ret

; X32-Darwin-LABEL:      test_basic:

; X32-Darwin:      movl $432, %ecx
; X32-Darwin-NEXT: cmpl %gs:(%ecx), %esp
; X32-Darwin-NEXT: jbe	LBB0_1

; X32-Darwin:      pushl $0
; X32-Darwin-NEXT: pushl $60
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

; X64-Darwin-LABEL:      test_basic:

; X64-Darwin:      cmpq %gs:816, %rsp
; X64-Darwin-NEXT: jbe	LBB0_1

; X64-Darwin:      movabsq $40, %r10
; X64-Darwin-NEXT: movabsq $0, %r11
; X64-Darwin-NEXT: callq ___morestack
; X64-Darwin-NEXT: ret

; X32-MinGW-LABEL:       test_basic:

; X32-MinGW:       cmpl %fs:20, %esp
; X32-MinGW-NEXT:  jbe      LBB0_1

; X32-MinGW:       pushl $0
; X32-MinGW-NEXT:  pushl $40
; X32-MinGW-NEXT:  calll ___morestack
; X32-MinGW-NEXT:  ret

; X64-MinGW-LABEL:       test_basic:

; X64-MinGW:       cmpq %gs:40, %rsp
; X64-MinGW-NEXT:  jbe      .LBB0_1

; X64-MinGW:       movabsq $72, %r10
; X64-MinGW-NEXT:  movabsq $32, %r11
; X64-MinGW-NEXT:  callq __morestack
; X64-MinGW-NEXT:  retq

; X64-FreeBSD-LABEL:       test_basic:

; X64-FreeBSD:       cmpq %fs:24, %rsp
; X64-FreeBSD-NEXT:  jbe      .LBB0_1

; X64-FreeBSD:       movabsq $40, %r10
; X64-FreeBSD-NEXT:  movabsq $0, %r11
; X64-FreeBSD-NEXT:  callq __morestack
; X64-FreeBSD-NEXT:  ret

; X32-DFlyBSD-LABEL:       test_basic:

; X32-DFlyBSD:       cmpl %fs:16, %esp
; X32-DFlyBSD-NEXT:  jbe      .LBB0_1

; X32-DFlyBSD:       pushl $0
; X32-DFlyBSD-NEXT:  pushl $40
; X32-DFlyBSD-NEXT:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD-LABEL:       test_basic:

; X64-DFlyBSD:       cmpq %fs:32, %rsp
; X64-DFlyBSD-NEXT:  jbe      .LBB0_1

; X64-DFlyBSD:       movabsq $40, %r10
; X64-DFlyBSD-NEXT:  movabsq $0, %r11
; X64-DFlyBSD-NEXT:  callq __morestack
; X64-DFlyBSD-NEXT:  ret

}

define i32 @test_nested(i32 * nest %closure, i32 %other) #0 {
       %addend = load i32 , i32 * %closure
       %result = add i32 %other, %addend
       %mem = alloca i32, i32 10
       call void @dummy_use (i32* %mem, i32 10)
       ret i32 %result

; X32-Linux:       cmpl %gs:48, %esp
; X32-Linux-NEXT:  jbe	.LBB1_1

; X32-Linux:       pushl $4
; X32-Linux-NEXT:  pushl $44
; X32-Linux-NEXT:  calll __morestack
; X32-Linux-NEXT:  ret

; X64-Linux:       cmpq %fs:112, %rsp
; X64-Linux-NEXT:  jbe	.LBB1_1

; X64-Linux:       movq %r10, %rax
; X64-Linux-NEXT:  movabsq $56, %r10
; X64-Linux-NEXT:  movabsq $0, %r11
; X64-Linux-NEXT:  callq __morestack
; X64-Linux-NEXT:  ret
; X64-Linux-NEXT:  movq %rax, %r10

; X32ABI:       cmpl %fs:64, %esp
; X32ABI-NEXT:  jbe	.LBB1_1

; X32ABI:       movl %r10d, %eax
; X32ABI-NEXT:  movl $56, %r10d
; X32ABI-NEXT:  movl $0, %r11d
; X32ABI-NEXT:  callq __morestack
; X32ABI-NEXT:  ret
; X32ABI-NEXT:  movq %rax, %r10

; X32-Darwin:      movl $432, %edx
; X32-Darwin-NEXT: cmpl %gs:(%edx), %esp
; X32-Darwin-NEXT: jbe	LBB1_1

; X32-Darwin:      pushl $4
; X32-Darwin-NEXT: pushl $60
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

; X64-Darwin:      cmpq %gs:816, %rsp
; X64-Darwin-NEXT: jbe	LBB1_1

; X64-Darwin:      movq %r10, %rax
; X64-Darwin-NEXT: movabsq $56, %r10
; X64-Darwin-NEXT: movabsq $0, %r11
; X64-Darwin-NEXT: callq ___morestack
; X64-Darwin-NEXT: ret
; X64-Darwin-NEXT: movq %rax, %r10

; X32-MinGW:       cmpl %fs:20, %esp
; X32-MinGW-NEXT:  jbe      LBB1_1

; X32-MinGW:       pushl $4
; X32-MinGW-NEXT:  pushl $44
; X32-MinGW-NEXT:  calll ___morestack
; X32-MinGW-NEXT:  ret

; X64-MinGW-LABEL: test_nested:
; X64-MinGW:       cmpq %gs:40, %rsp
; X64-MinGW-NEXT:  jbe      .LBB1_1

; X64-MinGW:       movq %r10, %rax
; X64-MinGW-NEXT:  movabsq $88, %r10
; X64-MinGW-NEXT:  movabsq $32, %r11
; X64-MinGW-NEXT:  callq __morestack
; X64-MinGW-NEXT:  retq
; X64-MinGW-NEXT:  movq %rax, %r10

; X64-FreeBSD:       cmpq %fs:24, %rsp
; X64-FreeBSD-NEXT:  jbe      .LBB1_1

; X64-FreeBSD:       movq %r10, %rax
; X64-FreeBSD-NEXT:  movabsq $56, %r10
; X64-FreeBSD-NEXT:  movabsq $0, %r11
; X64-FreeBSD-NEXT:  callq __morestack
; X64-FreeBSD-NEXT:  ret
; X64-FreeBSD-NEXT:  movq %rax, %r10

; X32-DFlyBSD:       cmpl %fs:16, %esp
; X32-DFlyBSD-NEXT:  jbe      .LBB1_1

; X32-DFlyBSD:       pushl $4
; X32-DFlyBSD-NEXT:  pushl $44
; X32-DFlyBSD-NEXT:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD:       cmpq %fs:32, %rsp
; X64-DFlyBSD-NEXT:  jbe      .LBB1_1

; X64-DFlyBSD:       movq %r10, %rax
; X64-DFlyBSD-NEXT:  movabsq $56, %r10
; X64-DFlyBSD-NEXT:  movabsq $0, %r11
; X64-DFlyBSD-NEXT:  callq __morestack
; X64-DFlyBSD-NEXT:  ret
; X64-DFlyBSD-NEXT:  movq %rax, %r10

}

define void @test_large() #0 {
        %mem = alloca i32, i32 10000
        call void @dummy_use (i32* %mem, i32 3)
        ret void

; X32-Linux-LABEL:       test_large:

; X32-Linux:       leal -40012(%esp), %ecx
; X32-Linux-NEXT:  cmpl %gs:48, %ecx
; X32-Linux-NEXT:  jbe	.LBB2_1

; X32-Linux:       pushl $0
; X32-Linux-NEXT:  pushl $40012
; X32-Linux-NEXT:  calll __morestack
; X32-Linux-NEXT:  ret

; X64-Linux:       leaq -40008(%rsp), %r11
; X64-Linux-NEXT:  cmpq %fs:112, %r11
; X64-Linux-NEXT:  jbe	.LBB2_1

; X64-Linux:       movabsq $40008, %r10
; X64-Linux-NEXT:  movabsq $0, %r11
; X64-Linux-NEXT:  callq __morestack
; X64-Linux-NEXT:  ret

; X32ABI:       leal -40008(%rsp), %r11d
; X32ABI-NEXT:  cmpl %fs:64, %r11d
; X32ABI-NEXT:  jbe	.LBB2_1

; X32ABI:       movl $40008, %r10d
; X32ABI-NEXT:  movl $0, %r11d
; X32ABI-NEXT:  callq __morestack
; X32ABI-NEXT:  ret

; X32-Darwin:      leal -40012(%esp), %ecx
; X32-Darwin-NEXT: movl $432, %eax
; X32-Darwin-NEXT: cmpl %gs:(%eax), %ecx
; X32-Darwin-NEXT: jbe	LBB2_1

; X32-Darwin:      pushl $0
; X32-Darwin-NEXT: pushl $40012
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

; X64-Darwin:      leaq -40008(%rsp), %r11
; X64-Darwin-NEXT: cmpq %gs:816, %r11
; X64-Darwin-NEXT: jbe      LBB2_1

; X64-Darwin:      movabsq $40008, %r10
; X64-Darwin-NEXT: movabsq $0, %r11
; X64-Darwin-NEXT: callq ___morestack
; X64-Darwin-NEXT: ret

; X32-MinGW:       leal -40000(%esp), %ecx
; X32-MinGW-NEXT:  cmpl %fs:20, %ecx
; X32-MinGW-NEXT:  jbe      LBB2_1

; X32-MinGW:       pushl $0
; X32-MinGW-NEXT:  pushl $40000
; X32-MinGW-NEXT:  calll ___morestack
; X32-MinGW-NEXT:  ret

; X64-MinGW-LABEL: test_large:
; X64-MinGW:       leaq -40040(%rsp), %r11
; X64-MinGW-NEXT:  cmpq %gs:40, %r11
; X64-MinGW-NEXT:  jbe      .LBB2_1

; X64-MinGW:       movabsq $40040, %r10
; X64-MinGW-NEXT:  movabsq $32, %r11
; X64-MinGW-NEXT:  callq __morestack
; X64-MinGW-NEXT:  retq

; X64-FreeBSD:       leaq -40008(%rsp), %r11
; X64-FreeBSD-NEXT:  cmpq %fs:24, %r11
; X64-FreeBSD-NEXT:  jbe      .LBB2_1

; X64-FreeBSD:       movabsq $40008, %r10
; X64-FreeBSD-NEXT:  movabsq $0, %r11
; X64-FreeBSD-NEXT:  callq __morestack
; X64-FreeBSD-NEXT:  ret

; X32-DFlyBSD:       leal -40000(%esp), %ecx
; X32-DFlyBSD-NEXT:  cmpl %fs:16, %ecx
; X32-DFlyBSD-NEXT:  jbe      .LBB2_1

; X32-DFlyBSD:       pushl $0
; X32-DFlyBSD-NEXT:  pushl $40000
; X32-DFlyBSD-NEXT:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD:       leaq -40008(%rsp), %r11
; X64-DFlyBSD-NEXT:  cmpq %fs:32, %r11
; X64-DFlyBSD-NEXT:  jbe      .LBB2_1

; X64-DFlyBSD:       movabsq $40008, %r10
; X64-DFlyBSD-NEXT:  movabsq $0, %r11
; X64-DFlyBSD-NEXT:  callq __morestack
; X64-DFlyBSD-NEXT:  ret

}

define fastcc void @test_fastcc() #0 {
        %mem = alloca i32, i32 10
        call void @dummy_use (i32* %mem, i32 10)
        ret void

; X32-Linux-LABEL:       test_fastcc:

; X32-Linux:       cmpl %gs:48, %esp
; X32-Linux-NEXT:  jbe	.LBB3_1

; X32-Linux:       pushl $0
; X32-Linux-NEXT:  pushl $44
; X32-Linux-NEXT:  calll __morestack
; X32-Linux-NEXT:  ret

; X64-Linux-LABEL:       test_fastcc:

; X64-Linux:       cmpq %fs:112, %rsp
; X64-Linux-NEXT:  jbe	.LBB3_1

; X64-Linux:       movabsq $40, %r10
; X64-Linux-NEXT:  movabsq $0, %r11
; X64-Linux-NEXT:  callq __morestack
; X64-Linux-NEXT:  ret

; X32ABI-LABEL:       test_fastcc:

; X32ABI:       cmpl %fs:64, %esp
; X32ABI-NEXT:  jbe	.LBB3_1

; X32ABI:       movl $40, %r10d
; X32ABI-NEXT:  movl $0, %r11d
; X32ABI-NEXT:  callq __morestack
; X32ABI-NEXT:  ret

; X32-Darwin-LABEL:      test_fastcc:

; X32-Darwin:      movl $432, %eax
; X32-Darwin-NEXT: cmpl %gs:(%eax), %esp
; X32-Darwin-NEXT: jbe	LBB3_1

; X32-Darwin:      pushl $0
; X32-Darwin-NEXT: pushl $60
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

; X64-Darwin-LABEL:      test_fastcc:

; X64-Darwin:      cmpq %gs:816, %rsp
; X64-Darwin-NEXT: jbe	LBB3_1

; X64-Darwin:      movabsq $40, %r10
; X64-Darwin-NEXT: movabsq $0, %r11
; X64-Darwin-NEXT: callq ___morestack
; X64-Darwin-NEXT: ret

; X32-MinGW-LABEL:       test_fastcc:

; X32-MinGW:       cmpl %fs:20, %esp
; X32-MinGW-NEXT:  jbe      LBB3_1

; X32-MinGW:       pushl $0
; X32-MinGW-NEXT:  pushl $40
; X32-MinGW-NEXT:  calll ___morestack
; X32-MinGW-NEXT:  ret

; X64-MinGW-LABEL:       test_fastcc:

; X64-MinGW:       cmpq %gs:40, %rsp
; X64-MinGW-NEXT:  jbe      .LBB3_1

; X64-MinGW:       movabsq $72, %r10
; X64-MinGW-NEXT:  movabsq $32, %r11
; X64-MinGW-NEXT:  callq __morestack
; X64-MinGW-NEXT:  retq

; X64-FreeBSD-LABEL:       test_fastcc:

; X64-FreeBSD:       cmpq %fs:24, %rsp
; X64-FreeBSD-NEXT:  jbe    .LBB3_1

; X64-FreeBSD:       movabsq $40, %r10
; X64-FreeBSD-NEXT:  movabsq $0, %r11
; X64-FreeBSD-NEXT:  callq __morestack
; X64-FreeBSD-NEXT:  ret

; X32-DFlyBSD-LABEL:       test_fastcc:

; X32-DFlyBSD:       cmpl %fs:16, %esp
; X32-DFlyBSD-NEXT:  jbe     .LBB3_1

; X32-DFlyBSD:       pushl $0
; X32-DFlyBSD-NEXT:  pushl $40
; X32-DFlyBSD-NEXT:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD-LABEL:       test_fastcc:

; X64-DFlyBSD:       cmpq %fs:32, %rsp
; X64-DFlyBSD-NEXT:  jbe      .LBB3_1

; X64-DFlyBSD:       movabsq $40, %r10
; X64-DFlyBSD-NEXT:  movabsq $0, %r11
; X64-DFlyBSD-NEXT:  callq __morestack
; X64-DFlyBSD-NEXT:  ret

}

define fastcc void @test_fastcc_large() #0 {
        %mem = alloca i32, i32 10000
        call void @dummy_use (i32* %mem, i32 3)
        ret void

; X32-Linux-LABEL:       test_fastcc_large:

; X32-Linux:       leal -40012(%esp), %eax
; X32-Linux-NEXT:  cmpl %gs:48, %eax
; X32-Linux-NEXT:  jbe	.LBB4_1

; X32-Linux:       pushl $0
; X32-Linux-NEXT:  pushl $40012
; X32-Linux-NEXT:  calll __morestack
; X32-Linux-NEXT:  ret

; X64-Linux-LABEL:       test_fastcc_large:

; X64-Linux:       leaq -40008(%rsp), %r11
; X64-Linux-NEXT:  cmpq %fs:112, %r11
; X64-Linux-NEXT:  jbe	.LBB4_1

; X64-Linux:       movabsq $40008, %r10
; X64-Linux-NEXT:  movabsq $0, %r11
; X64-Linux-NEXT:  callq __morestack
; X64-Linux-NEXT:  ret

; X32ABI-LABEL:       test_fastcc_large:

; X32ABI:       leal -40008(%rsp), %r11d
; X32ABI-NEXT:  cmpl %fs:64, %r11d
; X32ABI-NEXT:  jbe	.LBB4_1

; X32ABI:       movl $40008, %r10d
; X32ABI-NEXT:  movl $0, %r11d
; X32ABI-NEXT:  callq __morestack
; X32ABI-NEXT:  ret

; X32-Darwin-LABEL:      test_fastcc_large:

; X32-Darwin:      leal -40012(%esp), %eax
; X32-Darwin-NEXT: movl $432, %ecx
; X32-Darwin-NEXT: cmpl %gs:(%ecx), %eax
; X32-Darwin-NEXT: jbe	LBB4_1

; X32-Darwin:      pushl $0
; X32-Darwin-NEXT: pushl $40012
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

; X64-Darwin-LABEL:      test_fastcc_large:

; X64-Darwin:      leaq -40008(%rsp), %r11
; X64-Darwin-NEXT: cmpq %gs:816, %r11
; X64-Darwin-NEXT: jbe	LBB4_1

; X64-Darwin:      movabsq $40008, %r10
; X64-Darwin-NEXT: movabsq $0, %r11
; X64-Darwin-NEXT: callq ___morestack
; X64-Darwin-NEXT: ret

; X32-MinGW-LABEL:       test_fastcc_large:

; X32-MinGW:       leal -40000(%esp), %eax
; X32-MinGW-NEXT:  cmpl %fs:20, %eax
; X32-MinGW-NEXT:  jbe      LBB4_1

; X32-MinGW:       pushl $0
; X32-MinGW-NEXT:  pushl $40000
; X32-MinGW-NEXT:  calll ___morestack
; X32-MinGW-NEXT:  ret

; X64-MinGW-LABEL:       test_fastcc_large:

; X64-MinGW:       leaq -40040(%rsp), %r11
; X64-MinGW-NEXT:  cmpq %gs:40, %r11
; X64-MinGW-NEXT:  jbe      .LBB4_1

; X64-MinGW:       movabsq $40040, %r10
; X64-MinGW-NEXT:  movabsq $32, %r11
; X64-MinGW-NEXT:  callq __morestack
; X64-MinGW-NEXT:  retq

; X64-FreeBSD-LABEL:       test_fastcc_large:

; X64-FreeBSD:       leaq -40008(%rsp), %r11
; X64-FreeBSD-NEXT:  cmpq %fs:24, %r11
; X64-FreeBSD-NEXT:  jbe     .LBB4_1

; X64-FreeBSD:       movabsq $40008, %r10
; X64-FreeBSD-NEXT:  movabsq $0, %r11
; X64-FreeBSD-NEXT:  callq __morestack
; X64-FreeBSD-NEXT:  ret

; X32-DFlyBSD-LABEL:       test_fastcc_large:

; X32-DFlyBSD:       leal -40000(%esp), %eax
; X32-DFlyBSD-NEXT:  cmpl %fs:16, %eax
; X32-DFlyBSD-NEXT:  jbe      .LBB4_1

; X32-DFlyBSD:       pushl $0
; X32-DFlyBSD-NEXT:  pushl $40000
; X32-DFlyBSD-NEXT:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD-LABEL:       test_fastcc_large:

; X64-DFlyBSD:       leaq -40008(%rsp), %r11
; X64-DFlyBSD-NEXT:  cmpq %fs:32, %r11
; X64-DFlyBSD-NEXT:  jbe      .LBB4_1

; X64-DFlyBSD:       movabsq $40008, %r10
; X64-DFlyBSD-NEXT:  movabsq $0, %r11
; X64-DFlyBSD-NEXT:  callq __morestack
; X64-DFlyBSD-NEXT:  ret

}

define fastcc void @test_fastcc_large_with_ecx_arg(i32 %a) #0 {
        %mem = alloca i32, i32 10000
        call void @dummy_use (i32* %mem, i32 %a)
        ret void

; This is testing that the Mac implementation preserves ecx

; X32-Darwin-LABEL:      test_fastcc_large_with_ecx_arg:

; X32-Darwin:      leal -40012(%esp), %eax
; X32-Darwin-NEXT: pushl %ecx
; X32-Darwin-NEXT: movl $432, %ecx
; X32-Darwin-NEXT: cmpl %gs:(%ecx), %eax
; X32-Darwin-NEXT: popl %ecx
; X32-Darwin-NEXT: jbe	LBB5_1

; X32-Darwin:      pushl $0
; X32-Darwin-NEXT: pushl $40012
; X32-Darwin-NEXT: calll ___morestack
; X32-Darwin-NEXT: ret

}

define void @test_nostack() #0 {
	ret void

; X32-Linux-LABEL: test_nostack:
; X32-Linux-NOT:   calll __morestack

; X64-Linux-LABEL: test_nostack:
; X32-Linux-NOT:   callq __morestack

; X32ABI-LABEL: test_nostack:
; X32ABI-NOT:   callq __morestack

; X32-Darwin-LABEL: test_nostack:
; X32-Darwin-NOT:   calll __morestack

; X64-Darwin-LABEL: test_nostack:
; X64-Darwin-NOT:   callq __morestack

; X32-MinGW-LABEL: test_nostack:
; X32-MinGW-NOT:   calll __morestack

; X64-MinGW-LABEL: test_nostack:
; X64-MinGW-NOT:   callq __morestack

; X64-FreeBSD-LABEL: test_nostack:
; X64-FreeBSD-NOT:   callq __morestack

; X32-DFlyBSD-LABEL: test_nostack:
; X32-DFlyBSD-NOT:   calll __morestack

; X64-DFlyBSD-LABEL: test_nostack:
; X64-DFlyBSD-NOT:   callq __morestack
}

define void @test_nosplitstck() {
	ret void
}

; Test to make sure that a morestack call is generated if there is a
; sibling call, even if the function in question has no stack frame
; (PR37807).

declare i32 @callee(i32)

define i32 @test_sibling_call_empty_frame(i32 %x) #0 {
  %call = tail call i32 @callee(i32 %x) #0
  ret i32 %call

; X32-Linux-LABEL:       test_sibling_call_empty_frame:
; X32-Linux:  calll __morestack

; X64-Linux-LABEL:       test_sibling_call_empty_frame:
; X64-Linux:  callq __morestack

; X64-Linux-Large-LABEL:       test_sibling_call_empty_frame:
; X64-Linux-Large:  callq *__morestack_addr(%rip)

; X32ABI-LABEL:       test_sibling_call_empty_frame:
; X32ABI:  callq __morestack

; X32-Darwin-LABEL:      test_sibling_call_empty_frame:
; X32-Darwin: calll ___morestack

; X64-Darwin-LABEL:      test_sibling_call_empty_frame:
; X64-Darwin: callq ___morestack

; X32-MinGW-LABEL:       test_sibling_call_empty_frame:
; X32-MinGW:  calll ___morestack

; X64-MinGW-LABEL:       test_sibling_call_empty_frame:
; X64-MinGW:  callq __morestack

; X64-FreeBSD-LABEL:       test_sibling_call_empty_frame:
; X64-FreeBSD:  callq __morestack

; X32-DFlyBSD-LABEL:       test_sibling_call_empty_frame:
; X32-DFlyBSD:  calll __morestack
; X32-DFlyBSD-NEXT:  ret

; X64-DFlyBSD-LABEL:       test_sibling_call_empty_frame:
; X64-DFlyBSD:  callq __morestack

}

attributes #0 = { "split-stack" }

; X64-Linux-Large: .rodata
; X64-Linux-Large-NEXT: __morestack_addr:
; X64-Linux-Large-NEXT: .quad	__morestack

; X32-Linux: .section ".note.GNU-split-stack","",@progbits
; X32-Linux: .section ".note.GNU-no-split-stack","",@progbits

; X64-Linux: .section ".note.GNU-split-stack","",@progbits
; X64-Linux: .section ".note.GNU-no-split-stack","",@progbits

; X64-FreeBSD: .section ".note.GNU-split-stack","",@progbits
; X64-FreeBSD: .section ".note.GNU-no-split-stack","",@progbits

; X32-DFlyBSD: .section ".note.GNU-split-stack","",@progbits
; X32-DFlyBSD: .section ".note.GNU-no-split-stack","",@progbits

; X64-DFlyBSD: .section ".note.GNU-split-stack","",@progbits
; X64-DFlyBSD: .section ".note.GNU-no-split-stack","",@progbits
