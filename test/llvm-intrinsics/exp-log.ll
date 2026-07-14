; Check round-trip coverage for all Exp and Log OpenCL ExtInst.

; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

target datalayout = "e-p:64:64-p1:64:64-p2:32:32-p3:32:32-p4:64:64-p5:32:32-p6:32:32-p7:160:256:256:32-p8:128:128-p9:192:256:256:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-v2048:2048-n32:64-S32-A5-G1-ni:7:8:9"
target triple = "spirv64-amd-amdhsa"

; CHECK-SPIRV: ExtInstImport [[#ExtInstSetId:]] "OpenCL.std"
; CHECK-SPIRV: TypeFloat [[#TypeFloat:]] 32

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] exp [[#]]
; CHECK-LLVM: call float @llvm.exp.f32(
define spir_func float @TestExp(float %x) {
entry:
  %r = tail call float @llvm.exp.f32(float %x)
  ret float %r
}

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] exp2 [[#]]
; CHECK-LLVM: call float @llvm.exp2.f32(
define spir_func float @TestExp2(float %x) {
entry:
  %r = tail call float @llvm.exp2.f32(float %x)
  ret float %r
}

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] exp10 [[#]]
; CHECK-LLVM: call float @llvm.exp10.f32(
define spir_func float @TestExp10(float %x) {
entry:
  %r = tail call float @llvm.exp10.f32(float %x)
  ret float %r
}

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] log [[#]]
; CHECK-LLVM: call float @llvm.log.f32(
define spir_func float @TestLog(float %x) {
entry:
  %r = tail call float @llvm.log.f32(float %x)
  ret float %r
}

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] log2 [[#]]
; CHECK-LLVM: call float @llvm.log2.f32(
define spir_func float @TestLog2(float %x) {
entry:
  %r = tail call float @llvm.log2.f32(float %x)
  ret float %r
}

; CHECK-SPIRV: ExtInst [[#TypeFloat]] [[#]] [[#ExtInstSetId]] log10 [[#]]
; CHECK-LLVM: call float @llvm.log10.f32(
define spir_func float @TestLog10(float %x) {
entry:
  %r = tail call float @llvm.log10.f32(float %x)
  ret float %r
}

declare float @llvm.exp.f32(float)
declare float @llvm.exp2.f32(float)
declare float @llvm.exp10.f32(float)
declare float @llvm.log.f32(float)
declare float @llvm.log2.f32(float)
declare float @llvm.log10.f32(float)
