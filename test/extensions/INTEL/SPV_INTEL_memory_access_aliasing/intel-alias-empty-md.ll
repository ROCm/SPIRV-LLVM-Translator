; Check that the translator doesn't fail on a translation of empty aliasing
; metadata

; RUN: llvm-as %s -o %t.bc
; RUN: amd-llvm-spirv %t.bc --spirv-ext=+SPV_INTEL_memory_access_aliasing -o %t.spv
; RUN: amd-llvm-spirv %t.spv -to-text -o %t.spt
; RUN: FileCheck < %t.spt %s --check-prefix=CHECK-SPIRV

; CHECK-SPIRV-NOT: Capability MemoryAccessAliasingINTEL
; CHECK-SPIRV-NOT: Extension "SPV_INTEL_memory_access_aliasing"
; CHECK-SPIRV-NOT: AliasDomainDeclINTEL
; CHECK-SPIRV-NOT: AliasScopeDeclINTEL
; CHECK-SPIRV-NOT: AliasScopeListDeclINTEL

; ModuleID = 'optimized_intel_restrict.bc'
source_filename = "intel_restrict.cpp"
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"

define dso_local spir_kernel void @_ZTSZ4mainE15kernel_restrict(ptr addrspace(1) noalias %_arg_, ptr addrspace(1) noalias %_arg_1, ptr addrspace(1) noalias %_arg_3) local_unnamed_addr {
entry:
  %0 = addrspacecast ptr addrspace(1) %_arg_ to ptr addrspace(4)
  %1 = addrspacecast ptr addrspace(1) %_arg_1 to ptr addrspace(4)
  %2 = addrspacecast ptr addrspace(1) %_arg_3 to ptr addrspace(4)
  %3 = load i32, ptr addrspace(4) %0, align 4, !alias.scope !4
  %4 = load i32, ptr addrspace(4) %1, align 4, !alias.scope !4
  %add.i = add nsw i32 %4, %3
  store i32 %add.i, ptr addrspace(4) %2, align 4, !noalias !4
  ret void
}

!llvm.module.flags = !{!0}
!opencl.spir.version = !{!1}
!spirv.Source = !{!2}
!llvm.ident = !{!3}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 1, i32 2}
!2 = !{i32 4, i32 100000}
!3 = !{!"clang version 13.0.0"}
!4 = !{}
