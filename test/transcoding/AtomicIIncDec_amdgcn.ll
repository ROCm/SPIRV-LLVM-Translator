; Check that round trip on AMDGCN reads back OpAtomicIIncrement/IDecrement
; as atomicrmw add/sub 1.

; RUN: llvm-spirv %s -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r --spirv-target-env=CL2.0 --spirv-target-triple=amdgcn-amd-amdhsa %t.spv -o - | llvm-dis | FileCheck %s

; CHECK-SPIRV: AtomicIIncrement
; CHECK-SPIRV: AtomicIDecrement

; CHECK-LABEL: define {{.*}} @k(
; CHECK: atomicrmw add ptr {{.*}}, i32 1 syncscope("agent") seq_cst
; CHECK: atomicrmw sub ptr {{.*}}, i32 1 syncscope("agent") seq_cst

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir64-unknown-unknown"

; Scope 1 = Device; semantics 528 = SequentiallyConsistent | CrossWorkgroupMemory.
define spir_kernel void @k(ptr addrspace(1) %p) {
  %inc = call spir_func i32 @_Z24__spirv_AtomicIIncrementPU3AS1iii(ptr addrspace(1) %p, i32 1, i32 528)
  %dec = call spir_func i32 @_Z24__spirv_AtomicIDecrementPU3AS1iii(ptr addrspace(1) %p, i32 1, i32 528)
  ret void
}

declare spir_func i32 @_Z24__spirv_AtomicIIncrementPU3AS1iii(ptr addrspace(1), i32, i32)
declare spir_func i32 @_Z24__spirv_AtomicIDecrementPU3AS1iii(ptr addrspace(1), i32, i32)
