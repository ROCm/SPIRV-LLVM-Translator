; RUN: llvm-as < %s -o %t.bc
; RUN: amd-llvm-spirv --spirv-debug-info-version=nonsemantic-shader-200 %t.bc -o %t.spv
; RUN: amd-llvm-spirv -r %t.spv -o - | llvm-dis -o %t.ll
; RUN: llc -mcpu=gfx1030 -mtriple=amdgcn-amd-amdhsa -O0 -filetype=obj -o %t %t.ll
; RUN: llvm-dwarfdump -debug-info %t | FileCheck %s

;; Verify that we can produce valid dwarf from DIOp-based DIExpressions in a
;; simple program with a global and local variable.

; CHECK: DW_TAG_variable
; CHECK-NEXT: DW_AT_name ("global")
; CHECK-NEXT: DW_AT_type
; CHECK-NEXT: DW_AT_external
; CHECK-NEXT: DW_AT_decl_file ("t.cpp")
; CHECK-NEXT: DW_AT_decl_line (3)
; CHECK-NEXT: DW_AT_location ({{.*}} DW_OP_lit0, DW_OP_LLVM_user DW_OP_LLVM_form_aspace_address)

; CHECK: DW_TAG_variable
; CHECK-NEXT: DW_AT_location ({{.*}} DW_OP_lit5, DW_OP_LLVM_user DW_OP_LLVM_form_aspace_address)
; CHECK-NEXT: DW_AT_name ("local")
; CHECK-NEXT: DW_AT_decl_file ("t.cpp")
; CHECK-NEXT: DW_AT_decl_line (4)
; CHECK-NEXT: DW_AT_type

target triple = "spirv64-amd-amdhsa"

@global = hidden addrspace(1) externally_initialized global i32 42, align 4, !dbg !19

define hidden spir_kernel void @_Z6kernelv() addrspace(4) !dbg !11 !max_work_group_size !17 {
  %1 = alloca i32, align 4
  %2 = addrspacecast ptr %1 to ptr addrspace(4)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpDeref(i32)), !18)
  store i32 43, ptr addrspace(4) %2, align 4, !dbg !18
  store i32 44, ptr addrspace(1) @global, align 4, !dbg !18
  ret void, !dbg !18
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!opencl.ocl.version = !{!9}
!llvm.ident = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 21.0.0git", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, globals: !21, splitDebugInlining: false, nameTableKind: None)
!1 = !DIFile(filename: "t.cpp", directory: "/")
!2 = !{i32 1, !"amdhsa_code_object_version", i32 600}
!3 = !{i32 1, !"amdgpu_printf_kind", !"hostcall"}
!4 = !{i32 7, !"Dwarf Version", i32 5}
!5 = !{i32 2, !"Debug Info Version", i32 3}
!6 = !{i32 1, !"wchar_size", i32 4}
!7 = !{i32 8, !"PIC Level", i32 2}
!8 = !{i32 7, !"frame-pointer", i32 2}
!9 = !{i32 0, i32 0}
!10 = !{!"clang version 21.0.0"}
!11 = distinct !DISubprogram(name: "kernel", linkageName: "_Z6kernelv", scope: !1, file: !1, line: 3, type: !12, scopeLine: 3, flags: DIFlagPrototyped, spFlags: DISPFlagDefinition, unit: !0, retainedNodes: !14)
!12 = !DISubroutineType(cc: DW_CC_LLVM_SpirFunction, types: !13)
!13 = !{null}
!14 = !{!15}
!15 = !DILocalVariable(name: "local", scope: !11, file: !1, line: 4, type: !16)
!16 = !DIBasicType(name: "int", size: 32, encoding: DW_ATE_signed)
!17 = !{i32 1024, i32 1, i32 1}
!18 = !DILocation(line: 4, column: 6, scope: !11)
!19 = !DIGlobalVariableExpression(var: !20, expr: !DIExpression(DIOpArg(0, ptr addrspace(1)), DIOpDeref(i32)))
!20 = distinct !DIGlobalVariable(name: "global", scope: !0, file: !1, line: 3, type: !16, isLocal: false, isDefinition: true, memorySpace: DW_MSPACE_LLVM_global)
!21 = !{!19}
