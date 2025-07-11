// RUN: %clang_cc1 -triple spir-unknown-unknown -O1 -cl-std=CL2.0 -fdeclare-opencl-builtins -finclude-default-header -emit-llvm-bc %s -o %t.bc
// RUN: amd-llvm-spirv %t.bc -spirv-text -o - | FileCheck %s --check-prefix=CHECK-SPIRV
// RUN: amd-llvm-spirv %t.bc -o %t.spv
// RUN: spirv-val %t.spv
// RUN: amd-llvm-spirv -r %t.spv -o %t.rev.bc
// RUN: llvm-dis < %t.rev.bc | FileCheck %s --check-prefix=CHECK-LLVM

// CHECK-SPIRV-DAG: TypeBool [[bool:[0-9]+]]
// CHECK-SPIRV-DAG: TypeVector [[bool2:[0-9]+]] [[bool]] 2

// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testUGreaterThan:]] "testUGreaterThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testSGreaterThan:]] "testSGreaterThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testUGreaterThanEqual:]] "testUGreaterThanEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testSGreaterThanEqual:]] "testSGreaterThanEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testULessThan:]] "testULessThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testSLessThan:]] "testSLessThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testULessThanEqual:]] "testULessThanEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testSLessThanEqual:]] "testSLessThanEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFOrdEqual:]] "testFOrdEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFUnordNotEqual:]] "testFUnordNotEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFOrdGreaterThan:]] "testFOrdGreaterThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFOrdGreaterThanEqual:]] "testFOrdGreaterThanEqual"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFOrdLessThan:]] "testFOrdLessThan"
// CHECK-SPIRV-DAG: Name [[#__clang_ocl_kern_imp_testFOrdLessThanEqual:]] "testFOrdLessThanEqual"

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testUGreaterThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: UGreaterThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testUGreaterThan
// CHECK-LLVM: icmp ugt <2 x i32> %a, %b

kernel void testUGreaterThan(uint2 a, uint2 b, global int2 *res) {
  res[0] = a > b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testSGreaterThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: SGreaterThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testSGreaterThan
// CHECK-LLVM: icmp sgt <2 x i32> %a, %b

kernel void testSGreaterThan(int2 a, int2 b, global int2 *res) {
  res[0] = a > b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testUGreaterThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: UGreaterThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testUGreaterThanEqual
// CHECK-LLVM: icmp uge <2 x i32> %a, %b

kernel void testUGreaterThanEqual(uint2 a, uint2 b, global int2 *res) {
  res[0] = a >= b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testSGreaterThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: SGreaterThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testSGreaterThanEqual
// CHECK-LLVM: icmp sge <2 x i32> %a, %b

kernel void testSGreaterThanEqual(int2 a, int2 b, global int2 *res) {
  res[0] = a >= b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testULessThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: ULessThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testULessThan
// CHECK-LLVM: icmp ult <2 x i32> %a, %b

kernel void testULessThan(uint2 a, uint2 b, global int2 *res) {
  res[0] = a < b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testSLessThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: SLessThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testSLessThan
// CHECK-LLVM: icmp slt <2 x i32> %a, %b

kernel void testSLessThan(int2 a, int2 b, global int2 *res) {
  res[0] = a < b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testULessThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: ULessThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testULessThanEqual
// CHECK-LLVM: icmp ule <2 x i32> %a, %b

kernel void testULessThanEqual(uint2 a, uint2 b, global int2 *res) {
  res[0] = a <= b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testSLessThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: SLessThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testSLessThanEqual
// CHECK-LLVM: icmp sle <2 x i32> %a, %b

kernel void testSLessThanEqual(int2 a, int2 b, global int2 *res) {
  res[0] = a <= b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFOrdEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FOrdEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFOrdEqual
// CHECK-LLVM: fcmp oeq <2 x float> %a, %b

kernel void testFOrdEqual(float2 a, float2 b, global int2 *res) {
  res[0] = a == b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFUnordNotEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FUnordNotEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFUnordNotEqual
// CHECK-LLVM: fcmp une <2 x float> %a, %b

kernel void testFUnordNotEqual(float2 a, float2 b, global int2 *res) {
  res[0] = a != b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFOrdGreaterThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FOrdGreaterThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFOrdGreaterThan
// CHECK-LLVM: fcmp ogt <2 x float> %a, %b

kernel void testFOrdGreaterThan(float2 a, float2 b, global int2 *res) {
  res[0] = a > b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFOrdGreaterThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FOrdGreaterThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFOrdGreaterThanEqual
// CHECK-LLVM: fcmp oge <2 x float> %a, %b

kernel void testFOrdGreaterThanEqual(float2 a, float2 b, global int2 *res) {
  res[0] = a >= b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFOrdLessThan]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FOrdLessThan [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFOrdLessThan
// CHECK-LLVM: fcmp olt <2 x float> %a, %b

kernel void testFOrdLessThan(float2 a, float2 b, global int2 *res) {
  res[0] = a < b;
}

// CHECK-SPIRV: Function [[#]] [[#__clang_ocl_kern_imp_testFOrdLessThanEqual]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[A:[0-9]+]]
// CHECK-SPIRV-NEXT: FunctionParameter {{[0-9]+}} [[B:[0-9]+]]
// CHECK-SPIRV: FOrdLessThanEqual [[bool2]] {{[0-9]+}} [[A]] [[B]]
// CHECK-SPIRV: FunctionEnd

// CHECK-LLVM-LABEL: @testFOrdLessThanEqual
// CHECK-LLVM: fcmp ole <2 x float> %a, %b

kernel void testFOrdLessThanEqual(float2 a, float2 b, global int2 *res) {
  res[0] = a <= b;
}
