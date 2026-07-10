; RUN: llvm-as < %s | llvm-spirv -spirv-text -spirv-allow-unknown-intrinsics -o %t
; RUN: FileCheck < %t %s

; CHECK: Name [[#FEATURE_PREDICATE_IDS:]] "llvm.amdgcn.feature.predicate.ids"
; CHECK: Name [[#ASHR_PK_I8_I32:]] "llvm.amdgcn.ashr.pk.i8.i32"
; CHECK: Name [[#SET_FPENV_I64:]] "llvm.set.fpenv.i64"
; CHECK: Name [[#S_SLEEP_VAR:]] "llvm.amdgcn.s.sleep.var"
; CHECK: Name [[#S_WAIT_EVENT_EXPORT_READY:]] "llvm.amdgcn.s.wait.event.export.ready"
; CHECK: Name [[#S_TTRACEDATA_IMM:]] "llvm.amdgcn.s.ttracedata.imm"
; CHECK: Name [[#KERNEL:]] "kernel"
; CHECK: Decorate [[#IS_GFX950:]] SpecId 8
; CHECK: Decorate [[#IS_GFX1201:]] SpecId 3
; CHECK: Decorate [[#HAS_GFX12_INSTS:]] SpecId 7
; CHECK: Decorate [[#IS_GFX906:]] SpecId 6
; CHECK: Decorate [[#IS_GFX1010:]] SpecId 4
; CHECK: Decorate [[#IS_GFX1101:]] SpecId 5
; CHECK: Decorate [[#IS_GFX1101_1:]] SpecId 5
; CHECK: Decorate [[#IS_GFX1010_1:]] SpecId 4
; CHECK: Decorate [[#IS_GFX1201_1:]] SpecId 3
; CHECK: Decorate [[#HAS_GFX11_INSTS:]] SpecId 0
; CHECK: Decorate [[#HAS_GFX10_INSTS:]] SpecId 2
; CHECK: Decorate [[#HAS_GFX1250_INSTS:]] SpecId 1
; CHECK: Decorate [[#HAS_GFX11_INSTS_1:]] SpecId 0
; CHECK: TypeInt [[#UCHAR:]] 8
; CHECK: Constant [[#]] [[#FEATURE_PREDICATE_IDS_MAP_STRLEN:]] 137
; CHECK: TypeArray [[#FEATURE_PREDICATE_IDS_MAP_STRTY:]] [[#UCHAR]] [[#FEATURE_PREDICATE_IDS_MAP_STRLEN]]
; CHECK: TypeBool [[#BOOL:]]
; CHECK: ConstantComposite [[#FEATURE_PREDICATE_IDS_MAP_STRTY]] [[#FEATURE_PREDICATE_IDS_MAP_STRVAL:]]
; CHECK: Variable [[#]] [[#FEATURE_PREDICATE_IDS]] [[#]] [[#FEATURE_PREDICATE_IDS_MAP_STRVAL]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX950]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1201]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#HAS_GFX12_INSTS]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX906]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1010]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1101]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1101_1]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1010_1]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#IS_GFX1201_1]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#HAS_GFX11_INSTS]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#HAS_GFX10_INSTS]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#HAS_GFX1250_INSTS]]
; CHECK: SpecConstantFalse [[#BOOL]] [[#HAS_GFX11_INSTS_1]]

target datalayout = "e-i64:64-v16:16-v24:32-v32:32-v48:64-v96:128-v192:256-v256:256-v512:512-v1024:1024-n8:16:32:64"
target triple = "spirv64-amd-amdhsa"

declare void @llvm.amdgcn.s.monitor.sleep(i16 %immarg) addrspace(4)

declare void @llvm.amdgcn.s.sleep(i32 %immarg) addrspace(4)

declare i1 @llvm.spv.named.boolean.spec.constant(i32, i1, metadata) addrspace(4)

declare i16 @llvm.amdgcn.ashr.pk.i8.i32(i32, i32, i32) addrspace(4) #3

declare void @llvm.set.fpenv.i64(i64) addrspace(4) #4

declare void @llvm.amdgcn.s.sleep.var(i32) addrspace(4) #5

declare void @llvm.amdgcn.s.wait.event.export.ready() addrspace(4) #5

declare void @llvm.amdgcn.s.ttracedata.imm(i16 %immarg) addrspace(4) #6

@p = external addrspace(1) global i32
@g = external addrspace(1) constant i32

define void @kernel() addrspace(4) {
; CHECK-DAG: Function [[#]] [[#KERNEL]]
; CHECK: Label 55
; CHECK: Load 2 94 5 2 4
; CHECK: BranchConditional [[#IS_GFX950]] 56 57
; CHECK: Label 56
; CHECK: FunctionCall 36 98 [[#ASHR_PK_I8_I32]] 97 97 97
; CHECK: Branch 58
; CHECK: Label 57
; CHECK: FunctionCall 42 100 [[#SET_FPENV_I64]] 99
; CHECK: Branch 58
; CHECK: Label 58
; CHECK: BranchConditional [[#IS_GFX1201]] 60 59
; CHECK: Label 59
; CHECK: BranchConditional [[#HAS_GFX12_INSTS]] 60 61
; CHECK: Label 60
; CHECK: FunctionCall 42 103 [[#S_SLEEP_VAR]] 94
; CHECK: Branch 61
; CHECK: Label 61
; CHECK: BranchConditional [[#IS_GFX906]] 63 62
; CHECK: Label 62
; CHECK: FunctionCall 42 105 [[#S_WAIT_EVENT_EXPORT_READY]]
; CHECK: Branch 67
; CHECK: Label 63
; CHECK: BranchConditional [[#IS_GFX1010]] 65 64
; CHECK: Label 64
; CHECK: BranchConditional [[#IS_GFX1101]] 65 66
; CHECK: Label 65
; CHECK: FunctionCall 42 109 [[#S_TTRACEDATA_IMM]] 108
; CHECK: Branch 66
; CHECK: Label 66
; CHECK: Branch 67
; CHECK: Label 67
; CHECK: Branch 68
; CHECK: Label 68
; CHECK: BranchConditional [[#IS_GFX1101_1]] 69 70
; CHECK: Label 69
; CHECK: Load 2 111 4 2 4
; CHECK: IAdd 2 113 112 94
; CHECK: Store 4 113 2 4
; CHECK: Branch 70
; CHECK: Label 70
; CHECK: Branch 71
; CHECK: Label 71
; CHECK: Load 2 114 4 2 4
; CHECK: ISub 2 116 115 94
; CHECK: Store 4 116 2 4
; CHECK: Branch 72
; CHECK: Label 72
; CHECK: BranchConditional [[#IS_GFX1010_1]] 73 74
; CHECK: Label 73
; CHECK: Branch 74
; CHECK: Label 74
; CHECK: Phi 95 119 118 72 118 73
; CHECK: BranchConditional 119 71 75
; CHECK: Label 75
; CHECK: Branch 76
; CHECK: Label 76
; CHECK: BranchConditional [[#IS_GFX1201_1]] 77 79
; CHECK: Label 77
; CHECK: Branch 79
; CHECK: Label 78
; CHECK: Load 2 121 4 2 4
; CHECK: IAdd 2 123 121 122
; CHECK: Store 4 123 2 4
; CHECK: Branch 76
; CHECK: Label 79
; CHECK: BranchConditional [[#HAS_GFX11_INSTS]] 80 81
; CHECK: Label 80
; CHECK: FunctionCall 42 125 [[#S_WAIT_EVENT_EXPORT_READY]]
; CHECK: Branch 84
; CHECK: Label 81
; CHECK: BranchConditional [[#HAS_GFX10_INSTS]] 82 83
; CHECK: Label 82
; CHECK: FunctionCall 42 127 [[#S_TTRACEDATA_IMM]] 108
; CHECK: Branch 83
; CHECK: Label 83
; CHECK: Branch 84
; CHECK: Label 84
; CHECK: Branch 85
; CHECK: Label 85
; CHECK: Load 2 128 4 2 4
; CHECK: ISub 2 130 129 94
; CHECK: Store 4 130 2 4
; CHECK: Branch 86
; CHECK: Label 86
; CHECK: BranchConditional [[#HAS_GFX1250_INSTS]] 87 88
; CHECK: Label 87
; CHECK: Branch 88
; CHECK: Label 88
; CHECK: Phi 95 132 118 86 118 87
; CHECK: BranchConditional 132 85 89
; CHECK: Label 89
; CHECK: Branch 90
; CHECK: Label 90
; CHECK: BranchConditional [[#HAS_GFX11_INSTS_1]] 91 93

entry:
  %x = load i32, ptr addrspace(1) @g
  %is.gfx950. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !9)
  br i1 %is.gfx950., label %cond.true, label %cond.false
cond.true:
  %0 = call addrspace(4) i16 @llvm.amdgcn.ashr.pk.i8.i32(i32 8, i32 8, i32 8)
  br label %cond.end
cond.false:
  call addrspace(4) void @llvm.set.fpenv.i64(i64 -1)
  br label %cond.end
cond.end:
  %is.gfx1201. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !10)
  br i1 %is.gfx1201., label %if.then, label %lor.lhs.false
lor.lhs.false:
  %has.gfx12-insts. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !11)
  br i1 %has.gfx12-insts., label %if.then, label %if.end
if.then:
  call addrspace(4) void @llvm.amdgcn.s.sleep.var(i32 %x)
  br label %if.end
if.end:
  %is.gfx906. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !12)
  br i1 %is.gfx906., label %if.else, label %if.then2
if.then2:
  call addrspace(4) void @llvm.amdgcn.s.wait.event.export.ready()
  br label %if.end6
if.else:
  %is.gfx1010. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !13)
  br i1 %is.gfx1010., label %if.then4, label %lor.lhs.false3
lor.lhs.false3:
  %is.gfx1101. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !14)
  br i1 %is.gfx1101., label %if.then4, label %if.end5
if.then4:
  call addrspace(4) void @llvm.amdgcn.s.ttracedata.imm(i16 1)
  br label %if.end5
if.end5:
  br label %if.end6
if.end6:
  br label %while.cond
while.cond:
  %is.gfx1101.7 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !14)
  br i1 %is.gfx1101.7, label %while.body, label %while.end
while.body:
  %4 = load i32, ptr addrspace(1) @p
  %add = add i32 4, %x
  store i32 %add, ptr addrspace(1) @p
  br label %while.end
while.end:
  br label %do.body
do.body:
  %7 = load i32, ptr addrspace(1) @p
  %sub = sub i32 7, %x
  store i32 %sub, ptr addrspace(1) @p
  br label %do.cond
do.cond:
  %is.gfx1010.8 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !13)
  br i1 %is.gfx1010.8, label %land.rhs, label %land.end
land.rhs:
  br label %land.end
land.end:
  %c = phi i1 [ false, %do.cond ], [ false, %land.rhs ]
  br i1 %c, label %do.body, label %do.end
do.end:
  br label %for.cond
for.cond:
  %is.gfx1201.9 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !10)
  br i1 %is.gfx1201.9, label %for.body, label %for.end
for.body:
  br label %for.end
for.inc:
  %9 = load i32, ptr addrspace(1) @p
  %inc = add i32 %9, 1
  store i32 %inc, ptr addrspace(1) @p
  br label %for.cond
for.end:
  %has.gfx11-insts. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !18)
  br i1 %has.gfx11-insts., label %if.then10, label %if.else11
if.then10:
  call addrspace(4) void @llvm.amdgcn.s.wait.event.export.ready()
  br label %if.end14
if.else11:
  %has.gfx10-insts. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !19)
  br i1 %has.gfx10-insts., label %if.then12, label %if.end13
if.then12:
  call addrspace(4) void @llvm.amdgcn.s.ttracedata.imm(i16 1)
  br label %if.end13
if.end13:
  br label %if.end14
if.end14:
  br label %do.body15
do.body15:
  %12 = load i32, ptr addrspace(1) @p
  %sub16 = sub i32 12, %x
  store i32 %sub16, ptr addrspace(1) @p
  br label %do.cond17
do.cond17:
  %has.gfx1250-insts. = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !20)
  br i1 %has.gfx1250-insts., label %land.rhs9, label %land.end10
land.rhs9:
  br label %land.end10
land.end10:
  %c1 = phi i1 [ false, %do.cond17 ], [ false, %land.rhs9 ]
  br i1 %c1, label %do.body15, label %do.end18
do.end18:
  br label %for.cond19
for.cond19:
  %has.gfx11-insts.20 = call addrspace(4) i1 @llvm.spv.named.boolean.spec.constant(i32 -1, i1 false, metadata !18)
  br i1 %has.gfx11-insts.20, label %for.body21, label %for.end24
for.body21:
  br label %for.end24
for.inc22:
  %14 = load i32, ptr addrspace(1) @p
  %inc23 = add i32 14, 1
  store i32 %inc23, ptr addrspace(1) @p
  br label %for.cond19
for.end24:
  ret void
}

!spirv.Generator = !{!4}
!4 = !{i16 6, i16 65535}
!9 = !{!"is.gfx950"}
!10 = !{!"is.gfx1201"}
!11 = !{!"has.gfx12-insts"}
!12 = !{!"is.gfx906"}
!13 = !{!"is.gfx1010"}
!14 = !{!"is.gfx1101"}
!18 = !{!"has.gfx11-insts"}
!19 = !{!"has.gfx10-insts"}
!20 = !{!"has.gfx1250-insts"}
