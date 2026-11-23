; RUN: llvm-as %s -o %t.bc
; RUN: llvm-spirv %t.bc -o %t.spv
; RUN: llvm-spirv --spirv-target-env=CL2.0 --spirv-target-triple=amdgcn-amd-amdhsa -r %t.spv -o %t.rev.bc
; RUN: llvm-spirv --spirv-target-env=CL2.0 --spirv-target-triple=amdgcn-amd-amdhsa --spirv-amdgcn-offload-arch=gfx90a -r %t.spv -o %t.rev.gfx90a.bc
; RUN: llvm-spirv --spirv-target-env=CL2.0 --spirv-target-triple=amdgcn-amd-amdhsa --spirv-amdgcn-offload-arch=gfx942 -r %t.spv -o %t.rev.gfx942.bc
; RUN: llvm-spirv --spirv-target-env=CL2.0 --spirv-target-triple=amdgcn-amd-amdhsa --spirv-amdgcn-offload-arch=gfx1100 -r %t.spv -o %t.rev.gfx1100.bc
; RUN: llvm-dis < %t.rev.bc | FileCheck %s
; RUN: llvm-dis < %t.rev.gfx90a.bc | FileCheck --check-prefix=GFX90A %s
; RUN: llvm-dis < %t.rev.gfx942.bc | FileCheck --check-prefix=GFX942 %s
; RUN: llvm-dis < %t.rev.gfx1100.bc | FileCheck --check-prefix=GFX1100 %s
; RUN: spirv-val %t.spv
target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n32:64-S32-G1-P4-A0"
target triple = "spirv64-amd-amdhsa"

define spir_func noundef range(i32 128, 257) i32 @_Z4pickv() local_unnamed_addr addrspace(4) {
entry:
  %0 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !18)
  br i1 %0, label %return, label %if.else

if.else:
  %1 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !19)
  br i1 %1, label %return, label %if.else2

if.else2:
  %2 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !20)
  %. = select i1 %2, i32 128, i32 256
  br label %return

return:
  %retval.0 = phi i32 [ 256, %if.else ], [ 256, %entry ], [ %., %if.else2 ]
; CHECK: ret i32 256
; GFX90A: ret i32 256
; GFX942: ret i32 256
; GFX1100: ret i32 128
  ret i32 %retval.0
}

declare i1 @llvm.spv.named.boolean.spec.constant(i32 immarg, i1 immarg, metadata) addrspace(4)

define spir_kernel void @_Z1kPi(ptr addrspace(1) noundef %out.coerce) local_unnamed_addr addrspace(4) {
entry:
  %0 = ptrtoint ptr addrspace(1) %out.coerce to i64
  %1 = inttoptr i64 %0 to ptr addrspace(4)
  %call = call spir_func noundef addrspace(4) i32 @_Z4pickv()
  store i32 %call, ptr addrspace(4) %1, align 4
  ret void
}

!18 = !{!"is.gfx942"}
!19 = !{!"is.gfx90a"}
!20 = !{!"is.gfx1100"}
