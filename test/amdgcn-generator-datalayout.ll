; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o - | llvm-dis | FileCheck %s --check-prefixes=CHECK,GENERIC

; RUN: llvm-spirv -r %t.spv --spirv-amdgcn-offload-arch=gfx900 -o - | llvm-dis | FileCheck %s --check-prefixes=CHECK,GFX900
; RUN: llvm-spirv -r %t.spv --spirv-amdgcn-offload-arch=gfx942 -o - | llvm-dis | FileCheck %s --check-prefixes=CHECK,GFX942
; RUN: llvm-spirv -r %t.spv --spirv-amdgcn-offload-arch=gfx1030 -o - | llvm-dis | FileCheck %s --check-prefixes=CHECK,GFX1030

; AMD-generated SPIR-V must recover LLVM's current AMDGPU data layout.
; CHECK: target datalayout = "e-m:e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128:128:48-p9:192:256:256:32-p10:32:32-p11:32:32-p12:32:32-p13:32:32-p14:32:32-p15:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
; GENERIC: target triple = "amdgpu-amd-amdhsa"

; GFX900: target triple = "amdgpu9.00-amd-amdhsa"
; GFX942: target triple = "amdgpu9.42-amd-amdhsa"
; GFX1030: target triple = "amdgpu10.30-amd-amdhsa"

target triple = "spir64-amd-amdhsa"

define spir_kernel void @kernel() {
  ret void
}
