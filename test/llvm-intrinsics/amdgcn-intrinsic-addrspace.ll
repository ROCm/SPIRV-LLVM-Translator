; Test that non-overloaded AMDGCN intrinsics returning pointers with specific
; address spaces are correctly round-tripped through SPIR-V.
;
; SPIR-V represents all pointer types using storage classes, and the Generic
; storage class maps to addrspace(0) in LLVM. Intrinsics like
; llvm.amdgcn.implicitarg.ptr canonically return ptr addrspace(4) (Constant),
; but when round-tripped through SPIR-V, the reader reconstructs them with
; addrspace(0) unless it uses LLVM's canonical intrinsic declaration.

; RUN: llvm-spirv -spirv-allow-unknown-intrinsics=llvm.amdgcn %s -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s

target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "spirv64-amd-amdhsa"

; CHECK-DAG: declare {{.*}} ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
; CHECK-DAG: declare {{.*}} ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
; CHECK-DAG: declare {{.*}} ptr addrspace(4) @llvm.amdgcn.kernarg.segment.ptr()
; CHECK-DAG: declare {{.*}} ptr addrspace(4) @llvm.amdgcn.queue.ptr()

define void @test_amdgcn_ptr_intrinsics(ptr addrspace(1) %out) {
entry:
; CHECK: %implicitarg = call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
  %implicitarg = call ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
; CHECK: %dispatch = call ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
  %dispatch = call ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
; CHECK: %kernarg = call ptr addrspace(4) @llvm.amdgcn.kernarg.segment.ptr()
  %kernarg = call ptr addrspace(4) @llvm.amdgcn.kernarg.segment.ptr()
; CHECK: %queue = call ptr addrspace(4) @llvm.amdgcn.queue.ptr()
  %queue = call ptr addrspace(4) @llvm.amdgcn.queue.ptr()
  ret void
}

declare ptr addrspace(4) @llvm.amdgcn.implicitarg.ptr()
declare ptr addrspace(4) @llvm.amdgcn.dispatch.ptr()
declare ptr addrspace(4) @llvm.amdgcn.kernarg.segment.ptr()
declare ptr addrspace(4) @llvm.amdgcn.queue.ptr()
