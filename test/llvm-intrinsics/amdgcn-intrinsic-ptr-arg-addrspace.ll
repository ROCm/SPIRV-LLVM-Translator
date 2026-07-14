; Test that non-overloaded AMDGCN intrinsics taking pointer *parameters* with a
; specific address space are correctly round-tripped through SPIR-V. The writer
; recovers the canonical parameter address space from LLVM's intrinsic
; declaration (rather than a hardcoded per-name list), so the flat/generic
; pointer parameter of is.shared / is.private must be preserved.

; RUN: llvm-spirv -spirv-allow-unknown-intrinsics=llvm.amdgcn %s -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s

target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "spirv64-amd-amdhsa"

; CHECK-DAG: declare i1 @llvm.amdgcn.is.shared(ptr)
; CHECK-DAG: declare i1 @llvm.amdgcn.is.private(ptr)

define void @test_amdgcn_ptr_arg_intrinsics(ptr addrspace(4) %generic, ptr addrspace(1) %out) {
entry:
  %flat = addrspacecast ptr addrspace(4) %generic to ptr
; CHECK: call i1 @llvm.amdgcn.is.shared(ptr %{{[0-9a-zA-Z._]+}})
  %shared = call i1 @llvm.amdgcn.is.shared(ptr %flat)
; CHECK: call i1 @llvm.amdgcn.is.private(ptr %{{[0-9a-zA-Z._]+}})
  %private = call i1 @llvm.amdgcn.is.private(ptr %flat)
  %r = or i1 %shared, %private
  %z = zext i1 %r to i32
  store i32 %z, ptr addrspace(1) %out
  ret void
}

declare i1 @llvm.amdgcn.is.shared(ptr)
declare i1 @llvm.amdgcn.is.private(ptr)
