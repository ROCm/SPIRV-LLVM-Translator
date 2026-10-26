; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis | FileCheck %s

; An amdgcn override must recover LLVM's current AMDGPU data layout.
; CHECK: target datalayout = "e-m:e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-{{.*}}-n32:64-S32-A5-G1-ni:7:8:9{{(:[0-9]+)*}}"
; CHECK: target triple = "amdgcn-amd-amdhsa"

target triple = "spir64-amd-amdhsa"

define spir_kernel void @kernel() {
  ret void
}
