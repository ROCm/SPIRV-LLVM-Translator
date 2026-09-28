; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o %t.bc
; RUN: opt -passes=verify %t.bc -disable-output
; RUN: llvm-dis %t.bc -o - | FileCheck %s
; RUN: llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.spv -o %t.subarch.bc
; RUN: opt -passes=verify %t.subarch.bc -disable-output
; RUN: llvm-dis %t.subarch.bc -o - | FileCheck %s

; Model backend-emitted intrinsic wrappers whose pointer parameter uses SPIR
; private address space. AMDGPU remaps it to AS5, but the intrinsic requires AS0.
target triple = "spir64-unknown-unknown"

define i1 @test(ptr addrspace(4) %generic) {
; CHECK-LABEL: define i1 @test(ptr %generic)
; CHECK: %[[PRIVATE:.*]] = addrspacecast ptr %generic to ptr addrspace(5)
; CHECK: %[[SHAREDARG:.*]] = addrspacecast ptr addrspace(5) %[[PRIVATE]] to ptr
; CHECK: %shared = call i1 @llvm.amdgcn.is.shared(ptr %[[SHAREDARG]])
; CHECK: %[[PRIVATEARG:.*]] = addrspacecast ptr addrspace(5) %[[PRIVATE]] to ptr
; CHECK: %private = call i1 @llvm.amdgcn.is.private(ptr %[[PRIVATEARG]])
  %flat = addrspacecast ptr addrspace(4) %generic to ptr
  %shared = call i1 @spirv.llvm_amdgcn_is_shared(ptr %flat)
  %private = call i1 @spirv.llvm_amdgcn_is_private(ptr %flat)
  %result = or i1 %shared, %private
  ret i1 %result
}

declare i1 @spirv.llvm_amdgcn_is_shared(ptr)
declare i1 @spirv.llvm_amdgcn_is_private(ptr)
