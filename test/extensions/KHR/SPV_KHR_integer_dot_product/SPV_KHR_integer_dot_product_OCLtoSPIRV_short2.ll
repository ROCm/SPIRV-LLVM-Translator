; RUN: llvm-as < %s -o %t.bc
; RUN: amd-llvm-spirv -s %t.bc -o %t.regularized.bc
; RUN: amd-llvm-spirv %t.bc --spirv-ext=+SPV_KHR_integer_dot_product -o %t-spirv.spv
; RUN: spirv-val %t-spirv.spv
; RUN: llvm-dis %t.regularized.bc -o - | FileCheck %s --check-prefix=CHECK-LLVM
; RUN: amd-llvm-spirv %t.bc -spirv-text --spirv-ext=+SPV_KHR_integer_dot_product -o - | FileCheck %s --check-prefix=CHECK-SPIRV

;CHECK-LLVM: call spir_func i32 @_Z15__spirv_SDotKHR
;CHECK-LLVM: call spir_func i32 @_Z16__spirv_SUDotKHR
;CHECK-LLVM: call spir_func i32 @_Z16__spirv_SUDotKHR
;CHECK-LLVM: call spir_func i32 @_Z15__spirv_UDotKHR

;CHECK-LLVM: call spir_func i32 @_Z21__spirv_SDotAccSatKHR
;CHECK-LLVM: call spir_func i32 @_Z22__spirv_SUDotAccSatKHR
;CHECK-LLVM: call spir_func i32 @_Z22__spirv_SUDotAccSatKHR
;CHECK-LLVM: call spir_func i32 @_Z21__spirv_UDotAccSatKHR

;CHECK-SPIRV: SDotKHR
;CHECK-SPIRV: SUDotKHR
;CHECK-SPIRV: SUDotKHR
;CHECK-SPIRV: UDotKHR

;CHECK-SPIRV: SDotAccSatKHR
;CHECK-SPIRV: SUDotAccSatKHR
;CHECK-SPIRV: SUDotAccSatKHR
;CHECK-SPIRV: UDotAccSatKHR

target datalayout = "e-p:32:32-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spir"

; Function Attrs: convergent norecurse nounwind
define spir_kernel void @test1(<2 x i16> %ia, <2 x i16> %ua, <2 x i16> %ib, <2 x i16> %ub, <2 x i16> %ires, <2 x i16> %ures) local_unnamed_addr #0 !kernel_arg_addr_space !3 !kernel_arg_access_qual !4 !kernel_arg_type !5 !kernel_arg_base_type !6 !kernel_arg_type_qual !7 {
entry:
  %call = tail call spir_func i32 @_Z3dotDv2_sS_(<2 x i16> %ia, <2 x i16> %ib) #2
  %call1 = tail call spir_func i32 @_Z3dotDv2_sDv2_t(<2 x i16> %ia, <2 x i16> %ub) #2
  %call2 = tail call spir_func i32 @_Z3dotDv2_tDv2_s(<2 x i16> %ua, <2 x i16> %ib) #2
  %call3 = tail call spir_func i32 @_Z3dotDv2_tS_(<2 x i16> %ua, <2 x i16> %ub) #2
  %call4 = tail call spir_func i32 @_Z11dot_acc_satDv2_sS_i(<2 x i16> %ia, <2 x i16> %ib, i32 %call2) #2
  %call5 = tail call spir_func i32 @_Z11dot_acc_satDv2_sDv2_ti(<2 x i16> %ia, <2 x i16> %ub, i32 %call4) #2
  %call6 = tail call spir_func i32 @_Z11dot_acc_satDv2_tDv2_si(<2 x i16> %ua, <2 x i16> %ib, i32 %call5) #2
  %call7 = tail call spir_func i32 @_Z11dot_acc_satDv2_tS_j(<2 x i16> %ua, <2 x i16> %ub, i32 %call3) #2
  ret void
}

; Function Attrs: convergent
declare spir_func i32 @_Z3dotDv2_sS_(<2 x i16>, <2 x i16>) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z3dotDv2_sDv2_t(<2 x i16>, <2 x i16>) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z3dotDv2_tDv2_s(<2 x i16>, <2 x i16>) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z3dotDv2_tS_(<2 x i16>, <2 x i16>) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z11dot_acc_satDv2_sS_i(<2 x i16>, <2 x i16>, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z11dot_acc_satDv2_sDv2_ti(<2 x i16>, <2 x i16>, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z11dot_acc_satDv2_tDv2_si(<2 x i16>, <2 x i16>, i32) local_unnamed_addr #1

; Function Attrs: convergent
declare spir_func i32 @_Z11dot_acc_satDv2_tS_j(<2 x i16>, <2 x i16>, i32) local_unnamed_addr #1

attributes #0 = { convergent norecurse nounwind "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pocharer"="none" "less-precise-fpmad"="false" "min-legal-vector-width"="128" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "uniform-work-group-size"="false" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #1 = { convergent "correctly-rounded-divide-sqrt-fp-math"="false" "disable-tail-calls"="false" "frame-pocharer"="none" "less-precise-fpmad"="false" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }
attributes #2 = { convergent nounwind }

!llvm.module.flags = !{!0}
!opencl.ocl.version = !{!1}
!opencl.spir.version = !{!1}
!llvm.ident = !{!2}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 2, i32 0}
!2 = !{!"clang version 11.0.0 (https://github.com/c199914007/llvm.git 8b94769313ca84cb9370b60ed008501ff692cb71)"}
!3 = !{i32 0, i32 0, i32 0, i32 0, i32 0, i32 0}
!4 = !{!"none", !"none", !"none", !"none", !"none", !"none"}
!5 = !{!"short4", !"ushort4", !"short4", !"ushort4", !"short4", !"ushort4"}
!6 = !{!"short __attribute__((ext_vector_type(4)))", !"ushort __attribute__((ext_vector_type(4)))", !"short __attribute__((ext_vector_type(4)))", !"ushort __attribute__((ext_vector_type(4)))", !"short __attribute__((ext_vector_type(4)))", !"ushort __attribute__((ext_vector_type(4)))"}
!7 = !{!"", !"", !"", !"", !"", !""}
