; RUN: llvm-as %s -o %t.bc
; RUN: amd-llvm-spirv -preserve-ocl-kernel-arg-type-metadata-through-string %t.bc -o - -spirv-text | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: amd-llvm-spirv %t.bc -o - -spirv-text | FileCheck %s --check-prefix=CHECK-SPIRV-NEGATIVE
; RUN: amd-llvm-spirv -preserve-ocl-kernel-arg-type-metadata-through-string %t.bc -o %t.spv
; RUN: amd-llvm-spirv -r -preserve-ocl-kernel-arg-type-metadata-through-string %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM-WORKAROUND
; RUN: amd-llvm-spirv %t.bc -o %t.spv
; RUN: amd-llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM-WORKAROUND-NEGATIVE

; ModuleID = 'test.cl'
source_filename = "test.cl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spir64-unknown-unknown."

; CHECK-SPIRV: String 18 "kernel_arg_type_qual.test.volatile,const,,"
; CHECK-SPIRV: Name [[ARG:1[0-9]+]] "g"
; CHECK-SPIRV: Decorate [[ARG]] Volatile
; CHECK-SPIRV-NEGATIVE-NOT: String 12 "kernel_arg_type_qual.test.volatile,const,,"

; CHECK-LLVM-WORKAROUND: !kernel_arg_type_qual ![[QUAL:[0-9]+]]
; CHECK-LLVM-WORKAROUND: ![[QUAL]] = !{!"volatile", !"const", !""}
; CHECK-LLVM-WORKAROUND-NEGATIVE: !kernel_arg_type_qual

; Function Attrs: convergent noinline norecurse nounwind optnone
define dso_local spir_kernel void @test(ptr addrspace(1) %g, ptr addrspace(1) %c, ptr addrspace(1) %asd) #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !5 !kernel_arg_type_qual !6 {
entry:
  ret void
}

attributes #1 = { convergent noinline norecurse nounwind optnone }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 0}
!2 = !{!"clang version 13.0.0"}
!3 = !{i32 1, i32 1}
!4 = !{!"none", !"none"}
!5 = !{!"float*", !"float*"}
!6 = !{!"volatile", !"const", !""}
