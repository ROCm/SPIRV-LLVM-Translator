; RUN: llvm-as %s -o %t.bc
; RUN: amd-llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: amd-llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

; CHECK: 119734787 {{[0-9]*}} {{[0-9]*}} {{[0-9]*}} 0
; CHECK: Capability Addresses
; CHECK: Capability Linkage
; CHECK: Capability Kernel
; CHECK: ExtInstImport 1 "OpenCL.std"
; CHECK: MemoryModel 2 2
; CHECK: Source 0 0
