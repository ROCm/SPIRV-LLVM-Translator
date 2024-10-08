; RUN: not amd-llvm-spirv -s %s 2>&1 | FileCheck %s
; CHECK: Invalid bitcode signature
