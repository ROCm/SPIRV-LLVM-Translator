; RUN: llvm-as %s -o %t.bc
; RUN: amd-llvm-spirv %t.bc -spirv-text -o - | FileCheck %s
; RUN: amd-llvm-spirv %t.bc -o %t.spv
; RUN: spirv-val %t.spv

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024"
target triple = "spir-unknown-unknown"

; CHECK-DAG: TypeInt [[I8:[0-9]+]] 8 0
; CHECK-DAG: TypeInt [[I16:[0-9]+]] 16 0
; CHECK-DAG: TypeInt [[I32:[0-9]+]] 32 0
; CHECK-DAG: TypeInt [[I64:[0-9]+]] 64 0
; CHECK-DAG: TypePointer [[I8PTR:[0-9]+]] 5 [[I8]]
; CHECK-DAG: TypePointer [[I16PTR:[0-9]+]] 5 [[I16]]
; CHECK-DAG: TypePointer [[I16PTRPTR:[0-9]+]] 5 [[I16PTR]]
; CHECK-DAG: TypePointer [[I32PTR:[0-9]+]] 5 [[I32]]
; CHECK-DAG: TypePointer [[I32PTRPTR:[0-9]+]] 5 [[I32PTR]]
; CHECK-DAG: TypeArray [[I8PTRx2:[0-9]+]] [[I8PTR]]
; CHECK-DAG: TypePointer [[I8PTRx2PTR:[0-9]+]] 5 [[I8PTRx2]]
; CHECK-DAG: TypeArray [[I32x4:[0-9]+]] [[I32]]
; CHECK-DAG: TypeArray [[I32x3x4:[0-9]+]] [[I32x4]]
; CHECK-DAG: TypeArray [[I32x2x3x4:[0-9]+]] [[I32x3x4]]
; CHECK-DAG: TypePointer [[I32x2x3x4PTR:[0-9]+]] 5 [[I32x2x3x4]]
; CHECK: Variable [[I16PTR]] [[A:[0-9]+]] 5
; CHECK: Variable [[I32PTR]] [[B:[0-9]+]] 5
; CHECK: Variable [[I16PTRPTR]] [[C:[0-9]+]] 5 [[A]]
; CHECK: SpecConstantOp [[I8PTR]] [[AI8:[0-9]+]] 124 [[A]]
; CHECK: SpecConstantOp [[I8PTR]] [[BI8:[0-9]+]] 124 [[B]]
; CHECK: ConstantComposite [[I8PTRx2]] [[DINIT:[0-9]+]] [[AI8]] [[BI8]]
; CHECK: Variable [[I8PTRx2PTR]] [[D:[0-9]+]] 5 [[DINIT]]
; CHECK: ConstantComposite [[I32x2x3x4]] [[FINIT:[0-9]+]]
; CHECK: Variable [[I32x2x3x4PTR]] [[F:[0-9]+]] 5 [[FINIT]]
; CHECK: SpecConstantOp [[I32PTR]] [[GINIT:[0-9]+]] 70 [[F]]
; CHECK: Variable [[I32PTRPTR]] [[G:[0-9]+]] 5 [[GINIT]]

@a = addrspace(1) global i16 0
@b = external addrspace(1) global i32
@c = addrspace(1) global ptr addrspace(1) @a
@d = addrspace(1) global [2 x ptr addrspace(1)] [ptr addrspace(1) @a, ptr addrspace(1) @b]
;@e = global [1 x ptr] [ptr @foo]
@f = addrspace(1) global [2 x [3 x [4 x i32]]] [[3 x [4 x i32]] [[4 x i32] [i32 1, i32 2, i32 3, i32 4], [4 x i32] [i32 1, i32 2, i32 3, i32 4], [4 x i32] [i32 1, i32 2, i32 3, i32 4]], [3 x [4 x i32]] [[4 x i32] [i32 1, i32 2, i32 3, i32 4], [4 x i32] [i32 1, i32 2, i32 3, i32 4], [4 x i32] [i32 1, i32 2, i32 3, i32 4]]]
@g = addrspace(1) global ptr addrspace(1) getelementptr inbounds ([2 x [3 x [4 x i32]]], ptr addrspace(1) @f, i64 0, i64 1, i64 2, i64 3)

; Function Attrs: nounwind
define spir_kernel void @foo() {
entry:
  ret void
}
