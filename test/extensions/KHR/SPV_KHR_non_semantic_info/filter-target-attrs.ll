; RUN: llvm-spirv %s -spirv-text --spirv-preserve-auxdata -o - | FileCheck %s --check-prefix=CHECK-SPIRV
; RUN: llvm-spirv %s -o %t.spv --spirv-preserve-auxdata
; RUN: llvm-spirv -r --spirv-preserve-auxdata %t.spv -o %t.rev.bc
; RUN: llvm-dis %t.rev.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM

; Test that target-features and target-cpu function attributes are preserved
; in SPIR-V but filtered out when reading back to LLVM IR.

; CHECK-SPIRV: ExtInstImport [[#Import:]] "NonSemantic.AuxData"

; CHECK-SPIRV-DAG: String [[#TargetCPU:]] "target-cpu"
; CHECK-SPIRV-DAG: String [[#TargetCPUVal:]] "generic"
; CHECK-SPIRV-DAG: String [[#TargetFeatures:]] "target-features"
; CHECK-SPIRV-DAG: String [[#TargetFeaturesVal:]] "+avx2"
; CHECK-SPIRV-DAG: String [[#CustomAttr:]] "custom-attr"
; CHECK-SPIRV-DAG: String [[#CustomAttrVal:]] "custom-value"

; CHECK-SPIRV: Name [[#Func:]] "test_func"

; CHECK-SPIRV-DAG: ExtInst {{.*}} [[#Import]] NonSemanticAuxDataFunctionAttribute [[#Func]] [[#TargetCPU]] [[#TargetCPUVal]]
; CHECK-SPIRV-DAG: ExtInst {{.*}} [[#Import]] NonSemanticAuxDataFunctionAttribute [[#Func]] [[#TargetFeatures]] [[#TargetFeaturesVal]]
; CHECK-SPIRV-DAG: ExtInst {{.*}} [[#Import]] NonSemanticAuxDataFunctionAttribute [[#Func]] [[#CustomAttr]] [[#CustomAttrVal]]

target triple = "spir64-unknown-unknown"

; CHECK-LLVM: define spir_func void @test_func() #[[#FuncAttr:]]
define spir_func void @test_func() #0 {
entry:
  ret void
}

; CHECK-LLVM: attributes #[[#FuncAttr]] =
; CHECK-LLVM-SAME: "custom-attr"="custom-value"
; CHECK-LLVM-NOT: target-cpu
; CHECK-LLVM-NOT: target-features

attributes #0 = { "target-cpu"="generic" "target-features"="+avx2" "custom-attr"="custom-value" }
