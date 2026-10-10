; RUN: llvm-as %s -o %t.input.bc
; RUN: llvm-spirv %t.input.bc --spirv-ext=+SPV_INTEL_function_pointers -o %t.spv
; RUN: spirv-val %t.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.spv -o %t.bc
; RUN: llvm-dis %t.bc -o - | FileCheck %s

; RUN: llvm-spirv %t.input.bc --spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers -o %t.untyped.spv
; RUN: spirv-val %t.untyped.spv
; RUN: llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.untyped.spv -o %t.untyped.bc
; RUN: llvm-dis %t.untyped.bc -o - | FileCheck %s

; TODO: Validate backend output once its callback initializer type matches the
; global's data type (CodeSectionINTEL function pointer versus Generic pointer).
; RUN: %if spirv-backend %{ llc -mtriple=spirv64-amd-amdhsa -O0 -filetype=obj --spirv-ext=+SPV_INTEL_function_pointers %s -o %t.llc.spv %}
; RUN: %if spirv-backend %{ llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.llc.spv -o %t.llc.bc %}
; RUN: %if spirv-backend %{ llvm-dis %t.llc.bc -o - | FileCheck %s %}

; RUN: %if spirv-backend %{ llc -mtriple=spirv64-amd-amdhsa -O0 -filetype=obj --spirv-ext=+SPV_INTEL_function_pointers,+SPV_KHR_untyped_pointers %s -o %t.llc.untyped.spv %}
; RUN: %if spirv-backend %{ llvm-spirv -r --spirv-target-triple=amdgpu9.42-amd-amdhsa %t.llc.untyped.spv -o %t.llc.untyped.bc %}
; RUN: %if spirv-backend %{ llvm-dis %t.llc.untyped.bc -o - | FileCheck %s %}
;
; A device-global callback holds a flat function pointer, not a private pointer.
; CHECK: @callback_ptr = addrspace(1) global ptr @callback
; CHECK-NOT: addrspacecast (ptr @callback to ptr addrspace(5))
; CHECK: define i32 @callback(i32
; CHECK: define amdgpu_kernel void @kernel(
; CHECK: load ptr, ptr addrspace(1) @callback_ptr
; CHECK: call i32

target datalayout = "e-i64:64-n32:64-G1-P4"
target triple = "spirv64-amd-amdhsa"

@callback_ptr = addrspace(1) global ptr addrspace(4) @callback

define spir_func i32 @callback(i32 %value) addrspace(4) {
  ret i32 %value
}

define spir_kernel void @kernel(ptr addrspace(1) %output) addrspace(4) {
  %fn = load ptr addrspace(4), ptr addrspace(1) @callback_ptr
  %value = call spir_func addrspace(4) i32 %fn(i32 42)
  store i32 %value, ptr addrspace(1) %output
  ret void
}
