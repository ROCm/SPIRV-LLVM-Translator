; RUN: llvm-as < %s -o %t.bc
; RUN: amd-llvm-spirv --spirv-debug-info-version=nonsemantic-shader-200 %t.bc -o %t.spv
; RUN: amd-llvm-spirv -r %t.spv -o - | llvm-dis -o - | FileCheck %s

; REQUIRES: diop-diexpressions

;; Verify that we can convert various DIOps back and forth from SPIRV.

; CHECK: %struct.OnlyInExpr = type { ptr addrspace(5) }
; CHECK: !DIExpression(DIOpArg(0, %struct.OnlyInExpr), DIOpConvert(i32))
; CHECK: !DIExpression(DIOpArg(0, ptr addrspace(5)), DIOpConvert(i32), DIOpConstant(i32 10), DIOpAnd())
; CHECK: !DIExpression(DIOpArg(0, ptr addrspace(5)), DIOpFragment(11, 12))
; CHECK: !DIExpression(DIOpArg(0, ptr addrspace(5)), DIOpConstant(i64 13), DIOpBitOffset(i32))
; CHECK: !DIExpression(DIOpArg(0, ptr addrspace(5)), DIOpPushLane(i64), DIOpByteOffset(i64))
; CHECK: !DIExpression(DIOpArg(0, i8), DIOpSExt(i64))
; CHECK: !DIExpression(DIOpArg(0, i32), DIOpConstant(i32 15), DIOpComposite(2, i64))
; CHECK: !DIExpression(DW_OP_LLVM_poisoned)
; CHECK: !DIExpression(DW_OP_LLVM_poisoned)
; CHECK: !DIExpression(DW_OP_LLVM_poisoned)
; CHECK: !DIExpression(DW_OP_LLVM_poisoned)
; CHECK: !DIExpression(DW_OP_LLVM_poisoned)

target triple = "spirv64-amd-amdhsa"

%struct.OnlyInExpr = type { ptr }

define hidden spir_kernel void @_Z6kernelv() addrspace(4) !dbg !11 !max_work_group_size !17 {
  %1 = alloca i32, align 4
  %2 = addrspacecast ptr %1 to ptr addrspace(4)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, %struct.OnlyInExpr), DIOpConvert(i32)), !18)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpConvert(i32), DIOpConstant(i32 10), DIOpAnd()), !18)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpFragment(11, 12)), !18)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpConstant(i64 13), DIOpBitOffset(i32)), !18)
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpPushLane(i64), DIOpByteOffset(i64)), !18)
    #dbg_declare(i8 -1, !15, !DIExpression(DIOpArg(0, i8), DIOpSExt(i64)), !18)
    #dbg_declare(i32 14, !15, !DIExpression(DIOpArg(0, i32), DIOpConstant(i32 15), DIOpComposite(2, i64)), !18)
    #dbg_declare(i32 14, !15, !DIExpression(DW_OP_LLVM_poisoned), !18)
    ; Next four should be poisoned after converting to addrspace(5) since they are invalid.
    #dbg_declare(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpReinterpret(i64), DIOpConvert(i32)), !18)
    #dbg_value(ptr %1, !15, !DIExpression(DIOpArg(0, ptr), DIOpReinterpret(i64), DIOpConvert(i32)), !18)
    #dbg_value(ptr %1, !15, !DIExpression(DIOpArg(0, i64), DIOpConvert(i32)), !18)
    #dbg_value(!DIArgList(i32 1, i32 2), !15, !DIExpression(DIOpArg(0, i32), DIOpArg(1, i32), DIOpAdd()), !18)
  store i32 43, ptr addrspace(4) %2, align 4, !dbg !18
  ret void, !dbg !18
}

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3, !4, !5, !6, !7, !8}
!opencl.ocl.version = !{!9}
!llvm.ident = !{!10}

!0 = distinct !DICompileUnit(language: DW_LANG_C_plus_plus_14, file: !1, producer: "clang version 21.0.0git", isOptimized: false, runtimeVersion: 0, emissionKind: FullDebug, splitDebugInlining: false, nameTableKind: None)
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
