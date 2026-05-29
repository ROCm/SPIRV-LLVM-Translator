; Ensure that a typed pointer passed by reference is converted to an untyped pointer prior usage.

; RUN: llvm-spirv %s -spirv-text -o %t.spt --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -o %t.spv --spirv-ext=+SPV_KHR_untyped_pointers
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

; CHECK-SPIRV: Name [[#XKER:]] "x"
; CHECK-SPIRV-DAG: Name [[#XFN:]] "x"
; CHECK-SPIRV: Decorate [[#XKER]] FuncParamAttr 2
; CHECK-SPIRV: Decorate [[#XFN]] FuncParamAttr 2

; CHECK-LLVM: @ker(ptr addrspace(4) byref(%struct.SS) %x)
; CHECK-LLVM: @fn(ptr addrspace(5) byref(%struct.SS) %x)

target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "spirv64-amd-amdhsa"

%struct.S = type { i32 }
%struct.SS = type { [7 x %struct.S] }

define spir_kernel void @ker(ptr addrspace(2) noundef byref(%struct.SS) %x) {
entry:
  ret void
}

define spir_func void @fn(ptr noundef byref(%struct.SS) %x) {
entry:
  ret void
}
