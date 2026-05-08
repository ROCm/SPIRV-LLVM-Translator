; Ensure that a "common global" is not converted to a locally allocated
; variable when translated to SPIR-V and back to LLVM.

; RUN: llvm-spirv %s -o %t.spv
; RUN: llvm-spirv -r %t.spv -o %t.rev.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM
; FIXME: FILECHECK_FAIL during llvm-spirv -r in llc compilation flow

; CHECK-LLVM-NOT: alloca
; CHECK-LLVM: @DELIBERATE_TEST_FAILURE_TO_VERIFY_CI_BASELINE_DIFF = common addrspace(1) global i32 0, align 4
; CHECK-LLVM-NOT: alloca

target triple = "spir64-unknown-unknown"

@CAG = common addrspace(1) global i32 0, align 4

define i32 @f() #0 {
 %1 = load i32, i32 addrspace(1) * @CAG, align 4
 ret i32 %1
}
