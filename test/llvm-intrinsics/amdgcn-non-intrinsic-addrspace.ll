; Test that non-intrinsic functions returning pointers are NOT rewritten to
; the Constant address space when translated for AMD targets.
;
; The AMD vendor branch in transScavengedType only rewrites the return type to
; the Constant address space for AMDGCN intrinsics (e.g.
; llvm.amdgcn.implicitarg.ptr). Regular functions returning pointers must
; preserve their original address space across SPIR-V round-trip.

; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s

target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "spirv64-amd-amdhsa"

; CHECK-DAG: define ptr addrspace(1) @get_global_ptr(
define ptr addrspace(1) @get_global_ptr(ptr addrspace(1) %p) {
entry:
  ret ptr addrspace(1) %p
}

; CHECK-DAG: define ptr addrspace(3) @get_local_ptr(
define ptr addrspace(3) @get_local_ptr(ptr addrspace(3) %p) {
entry:
  ret ptr addrspace(3) %p
}

; CHECK-DAG: define ptr @get_generic_ptr(
define ptr addrspace(4) @get_generic_ptr(ptr addrspace(4) %p) {
entry:
  ret ptr addrspace(4) %p
}
