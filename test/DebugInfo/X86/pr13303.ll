; RUN: llvm-as < %s -o %t.bc
; RUN: amd-llvm-spirv %t.bc -o %t.spv
; RUN: amd-llvm-spirv -r %t.spv -o - | llvm-dis -o %t.ll
; RUN: llc %t.ll -o %t -filetype=obj -mtriple=x86_64-unknown-linux-gnu
; RUN: llvm-dwarfdump -debug-line %t | FileCheck %s

; RUN: amd-llvm-spirv %t.bc -o %t.spv --spirv-debug-info-version=nonsemantic-shader-100
; RUN: amd-llvm-spirv -r %t.spv -o - | llvm-dis -o %t.ll
; RUN: llc %t.ll -o %t -filetype=obj -mtriple=x86_64-unknown-linux-gnu
; RUN: llvm-dwarfdump -debug-line %t | FileCheck %s

; RUN: amd-llvm-spirv %t.bc -o %t.spv --spirv-debug-info-version=nonsemantic-shader-200
; RUN: amd-llvm-spirv -r %t.spv -o - | llvm-dis -o %t.ll
; RUN: llc %t.ll -o %t -filetype=obj -mtriple=x86_64-unknown-linux-gnu
; RUN: llvm-dwarfdump -debug-line %t | FileCheck %s

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir64-unknown-unknown"
; PR13303

; Check that the prologue ends with is_stmt here.
; CHECK: 0x0000000000000000 {{.*}} is_stmt

define i32 @main() nounwind uwtable !dbg !5 {
entry:
  %retval = alloca i32, align 4
  store i32 0, ptr %retval
  ret i32 0, !dbg !10
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!13}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, producer: "clang version 3.2 (trunk 160143)", isOptimized: false, emissionKind: FullDebug, file: !12, enums: !1, retainedTypes: !1, globals: !1, imports:  !1)
!1 = !{}
!5 = distinct !DISubprogram(name: "main", line: 1, isLocal: false, isDefinition: true, virtualIndex: 6, isOptimized: false, unit: !0, scopeLine: 1, file: !12, scope: !6, type: !7, retainedNodes: !1)
!6 = !DIFile(filename: "PR13303.c", directory: "/home/probinson")
!7 = !DISubroutineType(types: !8)
!8 = !{!9}
!9 = !DIBasicType(tag: DW_TAG_base_type, name: "int", size: 32, align: 32, encoding: DW_ATE_signed)
!10 = !DILocation(line: 1, column: 14, scope: !11)
!11 = distinct !DILexicalBlock(line: 1, column: 12, file: !12, scope: !5)
!12 = !DIFile(filename: "PR13303.c", directory: "/home/probinson")
!13 = !{i32 1, !"Debug Info Version", i32 3}
