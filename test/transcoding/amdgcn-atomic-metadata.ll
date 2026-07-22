; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -to-text %t.spv -o %t.spt
; RUN: FileCheck %s --input-file=%t.spt --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv -r --spirv-target-env=CL2.0 --spirv-amdgcn-offload-arch=gfx90a %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o %t.rev.ll
; RUN: FileCheck %s --input-file=%t.rev.ll --check-prefix=CHECK-LLVM

; CHECK-SPIRV-DAG: Decorate {{.*}} UserSemantic "amdgpu.no.fine.grained.memory"
; CHECK-SPIRV-DAG: Decorate {{.*}} UserSemantic "amdgpu.no.remote.memory"

; CHECK-LLVM: atomicrmw udec_wrap ptr addrspace(1) @val, i32 {{.*}} syncscope("agent") monotonic, align 4, !amdgpu.no.fine.grained.memory !{{[0-9]+}}, !amdgpu.no.remote.memory !{{[0-9]+}}

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spirv64-amd-amdhsa"

@val = dso_local addrspace(1) global i32 0, align 4

define dso_local spir_func void @test_atomic_dec(i32 noundef %limit) local_unnamed_addr {
entry:
  %0 = atomicrmw udec_wrap ptr addrspace(1) @val, i32 %limit syncscope("device") monotonic, align 4, !amdgpu.no.fine.grained.memory !0, !amdgpu.no.remote.memory !0
  ret void
}

!0 = !{}
