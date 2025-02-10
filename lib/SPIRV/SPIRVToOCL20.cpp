//===- SPIRVToOCL20.cpp - Transform SPIR-V builtins to OCL20 builtins------===//
//
//                     The LLVM/SPIRV Translator
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
// Copyright (c) 2014 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal with the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, sublicense,
// and/or sell copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following conditions:
//
// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimers.
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimers in the documentation
// and/or other materials provided with the distribution.
// Neither the names of Advanced Micro Devices, Inc., nor the names of its
// contributors may be used to endorse or promote products derived from this
// Software without specific prior written permission.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// CONTRIBUTORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS WITH
// THE SOFTWARE.
//
//===----------------------------------------------------------------------===//
//
// This file implements transform SPIR-V builtins to OCL 2.0 builtins.
//
//===----------------------------------------------------------------------===//

#include "OCLUtil.h"
#include "SPIRVToOCL.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/IR/Verifier.h"

#define DEBUG_TYPE "spvtocl20"

namespace SPIRV {

char SPIRVToOCL20Legacy::ID = 0;

bool SPIRVToOCL20Legacy::runOnModule(Module &Module) {
  return SPIRVToOCL20Base::runSPIRVToOCL(Module);
}
bool SPIRVToOCL20Base::runSPIRVToOCL(Module &Module) {
  M = &Module;
  Ctx = &M->getContext();

  // Lower builtin variables to builtin calls first.
  lowerBuiltinVariablesToCalls(M);
  translateOpaqueTypes();

  visit(*M);

  postProcessBuiltinsReturningStruct(M);
  postProcessBuiltinsWithArrayArguments(M);

  eraseUselessFunctions(&Module);

  LLVM_DEBUG(dbgs() << "After SPIRVToOCL20:\n" << *M);

  std::string Err;
  raw_string_ostream ErrorOS(Err);
  if (verifyModule(*M, &ErrorOS)) {
    LLVM_DEBUG(errs() << "Fails to verify module: " << ErrorOS.str());
  }
  return true;
}

static SyncScope::ID mapOpenCLScopeToAMDGPU(LLVMContext &Ctx, uint64_t S) {
  if (S == OCLMS_work_item)
    return SyncScope::SingleThread;
  if (S == OCLMS_work_group)
    return Ctx.getOrInsertSyncScopeID("workgroup");
  if (S == OCLMS_device)
    return Ctx.getOrInsertSyncScopeID("agent");
  if (S == OCLMS_sub_group)
    return Ctx.getOrInsertSyncScopeID("wavefront");
  return SyncScope::System;
}

static void translateSPIRVCmpXchgToLLVM(CallInst *CI, Op OC) {
  auto Ptr = CI->getOperand(0);
  auto Cmp = CI->getOperand(1);
  auto New = CI->getOperand(4);

  assert(isa<ConstantInt>(CI->getArgOperand(CI->arg_size() - 4))); // Skip New.
  assert(isa<ConstantInt>(CI->getArgOperand(CI->arg_size() - 3))); // Skip New.
  assert(isa<ConstantInt>(CI->getArgOperand(CI->arg_size() - 1)));

  auto SuccessOrder = // Offset NotAtomic and Unordered
      static_cast<AtomicOrdering>(getArgAsInt(CI, CI->arg_size() - 4) + 2);
  auto FailOrder = // Offset NotAtomic and Unordered
      static_cast<AtomicOrdering>(getArgAsInt(CI, CI->arg_size() - 3) + 2);
  SyncScope::ID S = mapOpenCLScopeToAMDGPU(CI->getContext(),
                                           getArgAsInt(CI, CI->arg_size() - 1));
  IRBuilder<> Builder(CI);
  auto CmpXchg = Builder.CreateAtomicCmpXchg(Ptr, Cmp, New, {}, SuccessOrder,
                                             FailOrder, S);
  // OpAtomicCompareExchangeWeak has been deprecated and subsequently removed
  // from SPIR-V versions newer than 1.4, and currently there's no way to encode
  // the weak bit.
  //CmpXchg->setWeak(OC == OpAtomicCompareExchangeWeak);

  CI->replaceAllUsesWith(
      Builder.CreateZExt(Builder.CreateExtractValue(CmpXchg, 0), CI->getType()));
  CI->dropAllReferences();
  CI->eraseFromParent();
}

static void translateSPIRVAtomicBuiltinToLLVMAtomicOp(CallInst *CI, Op OC) {
  if (OC == OpAtomicCompareExchange || OC == OpAtomicCompareExchangeWeak)
    return translateSPIRVCmpXchgToLLVM(CI, OC);

  static const DenseMap<Op, AtomicRMWInst::BinOp> SPIRVtoLLVM{
    {OpAtomicAnd, AtomicRMWInst::And},
    {OpAtomicExchange, AtomicRMWInst::Xchg},
    {OpAtomicFAddEXT, AtomicRMWInst::FAdd},
    {OpAtomicFMaxEXT, AtomicRMWInst::FMax},
    {OpAtomicFMinEXT, AtomicRMWInst::FMin},
    {OpAtomicIAdd, AtomicRMWInst::Add},
    {OpAtomicIDecrement, AtomicRMWInst::UDecWrap},
    {OpAtomicIIncrement, AtomicRMWInst::UIncWrap},
    {OpAtomicISub, AtomicRMWInst::Sub},
    {OpAtomicOr, AtomicRMWInst::Or},
    {OpAtomicSMax, AtomicRMWInst::Max},
    {OpAtomicSMin, AtomicRMWInst::Min},
    {OpAtomicUMax, AtomicRMWInst::UMax},
    {OpAtomicUMin, AtomicRMWInst::UMin},
    {OpAtomicXor, AtomicRMWInst::Xor}
  };

  assert(isa<ConstantInt>(CI->getArgOperand(CI->arg_size() - 1)));
  assert(isa<ConstantInt>(CI->getArgOperand(CI->arg_size() - 2)));

  auto Order = // Offset NotAtomic and Unordered
      static_cast<AtomicOrdering>(getArgAsInt(CI, CI->arg_size() - 2) + 2);
  auto S = mapOpenCLScopeToAMDGPU(CI->getContext(),
                                  getArgAsInt(CI, CI->arg_size() - 1));

  IRBuilder<> Builder(CI);
  if (OC == OpAtomicLoad) {
    auto LD = Builder.CreateLoad(CI->getType(), CI->getOperand(0));
    LD->setAtomic(Order, S);
    CI->replaceAllUsesWith(LD);
  } else if (OC == OpAtomicStore) {
    auto ST = Builder.CreateStore(CI->getOperand(1), CI->getOperand(0));
    ST->setAtomic(Order, S);
    CI->replaceAllUsesWith(ST);
  } else {
    auto RMW = Builder.CreateAtomicRMW(SPIRVtoLLVM.at(OC), CI->getOperand(0),
                                       CI->getOperand(1), {}, Order, S);
    CI->replaceAllUsesWith(RMW);
  }

  CI->dropAllReferences();
  CI->eraseFromParent();
}

static void visitCallLLVMFence(CallInst *CI) { // TODO: AMDSPV JANK, this is incorrect
  auto MS = transSPIRVMemoryScopeIntoOCLMemoryScope(CI->getArgOperand(0), CI);
  auto MO = transSPIRVMemorySemanticsIntoOCLMemoryOrder(CI->getArgOperand(1),
                                                        CI);
  assert(isa<ConstantInt>(MS));
  assert(isa<ConstantInt>(MO));

  auto O = static_cast<AtomicOrdering>(cast<ConstantInt>(MO)->getZExtValue() + 2);
  auto S = mapOpenCLScopeToAMDGPU(CI->getContext(),
                                  cast<ConstantInt>(MS)->getZExtValue());
  IRBuilder<> Builder(CI);

  CI->replaceAllUsesWith(Builder.CreateFence(O, S));

  CI->dropAllReferences();
  CI->eraseFromParent();
}

void SPIRVToOCL20Base::visitCallSPIRVMemoryBarrier(CallInst *CI) {
  if (M->getTargetTriple() == "amdgcn-amd-amdhsa")
    return visitCallLLVMFence(CI);

  Value *MemScope =
      SPIRV::transSPIRVMemoryScopeIntoOCLMemoryScope(CI->getArgOperand(0), CI);
  Value *MemFenceFlags = SPIRV::transSPIRVMemorySemanticsIntoOCLMemFenceFlags(
      CI->getArgOperand(1), CI);
  Value *MemOrder = SPIRV::transSPIRVMemorySemanticsIntoOCLMemoryOrder(
      CI->getArgOperand(1), CI);
  mutateCallInst(CI, kOCLBuiltinName::AtomicWorkItemFence)
      .setArgs({MemFenceFlags, MemOrder, MemScope});
}

void SPIRVToOCL20Base::visitCallSPIRVControlBarrier(CallInst *CI) {
  auto GetArg = [=](unsigned I) {
    return cast<ConstantInt>(CI->getArgOperand(I))->getZExtValue();
  };
  auto ExecScope = static_cast<Scope>(GetArg(0));
  Value *MemScope =
      SPIRV::transSPIRVMemoryScopeIntoOCLMemoryScope(CI->getArgOperand(1), CI);
  Value *MemFenceFlags = SPIRV::transSPIRVMemorySemanticsIntoOCLMemFenceFlags(
      CI->getArgOperand(2), CI);
  mutateCallInst(CI, ExecScope == ScopeWorkgroup
                         ? kOCLBuiltinName::WorkGroupBarrier
                         : kOCLBuiltinName::SubGroupBarrier)
      .setArgs({MemFenceFlags, MemScope});
}

void SPIRVToOCL20Base::visitCallSPIRVSplitBarrierINTEL(CallInst *CI, Op OC) {
  Value *MemScope =
      SPIRV::transSPIRVMemoryScopeIntoOCLMemoryScope(CI->getArgOperand(1), CI);
  Value *MemFenceFlags = SPIRV::transSPIRVMemorySemanticsIntoOCLMemFenceFlags(
      CI->getArgOperand(2), CI);
  mutateCallInst(CI, OCLSPIRVBuiltinMap::rmap(OC))
      .setArgs({MemFenceFlags, MemScope});
}

std::string SPIRVToOCL20Base::mapFPAtomicName(Op OC) {
  assert(isFPAtomicOpCode(OC) && "Not intended to handle other opcodes than "
                                 "AtomicF{Add/Min/Max}EXT!");
  switch (OC) {
  case OpAtomicFAddEXT:
    return "atomic_fetch_add_explicit";
  case OpAtomicFMinEXT:
    return "atomic_fetch_min_explicit";
  case OpAtomicFMaxEXT:
    return "atomic_fetch_max_explicit";
  default:
    llvm_unreachable("Unsupported opcode!");
  }
}

void SPIRVToOCL20Base::mutateAtomicName(CallInst *CI, Op OC) {
  // Map fp atomic instructions to regular OpenCL built-ins.
  mutateCallInst(CI, isFPAtomicOpCode(OC) ? mapFPAtomicName(OC)
                                          : OCLSPIRVBuiltinMap::rmap(OC));
}

void SPIRVToOCL20Base::visitCallSPIRVAtomicBuiltin(CallInst *CI, Op OC) {
  CallInst *CIG = mutateCommonAtomicArguments(CI, OC);

  if (M->getTargetTriple() == "amdgcn-amd-amdhsa")
    return translateSPIRVAtomicBuiltinToLLVMAtomicOp(CIG, OC);

  switch (OC) {
  case OpAtomicIIncrement:
  case OpAtomicIDecrement:
    visitCallSPIRVAtomicIncDec(CIG, OC);
    break;
  case OpAtomicCompareExchange:
  case OpAtomicCompareExchangeWeak:
    visitCallSPIRVAtomicCmpExchg(CIG);
    break;
  default:
    mutateAtomicName(CIG, OC);
  }
}

void SPIRVToOCL20Base::visitCallSPIRVAtomicIncDec(CallInst *CI, Op OC) {
  // Since OpenCL 2.0 doesn't have atomic_inc and atomic_dec builtins, we
  // translate these instructions to atomic_fetch_add_explicit and
  // atomic_fetch_sub_explicit OpenCL 2.0 builtins with "operand" argument = 1.
  auto Name = OCLSPIRVBuiltinMap::rmap(OC == OpAtomicIIncrement ? OpAtomicIAdd
                                                                : OpAtomicISub);
  Type *ValueTy = CI->getType();
  assert(ValueTy->isIntegerTy());
  mutateCallInst(CI, Name).insertArg(1, ConstantInt::get(ValueTy, 1));
}

CallInst *SPIRVToOCL20Base::mutateCommonAtomicArguments(CallInst *CI, Op OC) {
  std::string Name;
  // Map fp atomic instructions to regular OpenCL built-ins.
  if (isFPAtomicOpCode(OC))
    Name = mapFPAtomicName(OC);
  else
    Name = OCLSPIRVBuiltinMap::rmap(OC);

  auto Ptr = findFirstPtr(CI->args());
  auto NumOrder = getSPIRVAtomicBuiltinNumMemoryOrderArgs(OC);
  auto ScopeIdx = Ptr + 1;
  auto OrderIdx = Ptr + 2;
  auto Mutator = mutateCallInst(CI, Name);

  Mutator.mapArgs([=](IRBuilder<> &Builder, Value *PtrArg, Type *PtrArgTy) {
    if (auto *TypedPtrTy = dyn_cast<TypedPointerType>(PtrArgTy)) {
      unsigned AS = M->getTargetTriple() == "amdgcn-amd-amdhsa" ?
          mapSPIRVAddrSpaceToAMDGPU(StorageClassGeneric) : SPIRAS_Generic;
      if (TypedPtrTy->getAddressSpace() != AS) {
        Type *ElementTy = TypedPtrTy->getElementType();
        Type *FixedPtr = PointerType::get(ElementTy, AS);
        PtrArg = Builder.CreateAddrSpaceCast(PtrArg, FixedPtr,
                                             PtrArg->getName() + ".as");
        PtrArgTy = TypedPointerType::get(ElementTy, AS);
      }
    }
    return std::make_pair(PtrArg, PtrArgTy);
  });
  Mutator.mapArg(ScopeIdx, [=](Value *Arg) {
    return SPIRV::transSPIRVMemoryScopeIntoOCLMemoryScope(Arg, CI);
  });
  for (size_t I = 0; I < NumOrder; ++I) {
    Mutator.mapArg(OrderIdx + I, [=](Value *Arg) {
      return SPIRV::transSPIRVMemorySemanticsIntoOCLMemoryOrder(Arg, CI);
    });
  }
  Mutator.moveArg(Mutator.arg_size() - 1, ScopeIdx + 1);
  Mutator.moveArg(ScopeIdx, Mutator.arg_size() - 1);

  return cast<CallInst>(Mutator.getMutated());
}

void SPIRVToOCL20Base::visitCallSPIRVAtomicCmpExchg(CallInst *CI) {
  Type *MemTy = CI->getType();

  // OpAtomicCompareExchange[Weak] semantics is different from
  // atomic_compare_exchange_strong semantics as well as arguments order.
  // OCL built-ins returns boolean value and stores a new/original
  // value by pointer passed as 2nd argument (aka expected) while SPIR-V
  // instructions returns this new/original value as a resulting value.
  AllocaInst *PExpected = new AllocaInst(
      MemTy, M->getDataLayout().getAllocaAddrSpace(), "expected",
      CI->getParent()->getParent()->getEntryBlock().getFirstInsertionPt());
  PExpected->setAlignment(Align(MemTy->getScalarSizeInBits() / 8));

  // Tail call implies that the callee doesn't access alloca from the caller.
  // The newly created alloca invalidates the tail call semantics.
  CI->setTailCall(false);

  // OpAtomicCompareExchangeWeak is not "weak" at all, but instead has the same
  // semantics as OpAtomicCompareExchange.
  mutateCallInst(CI, "atomic_compare_exchange_strong_explicit")
      .mapArg(1,
              [=](IRBuilder<> &Builder, Value *Expected) {
                Builder.CreateStore(Expected, PExpected);
                unsigned AddrSpc = M->getTargetTriple() == "amdgcn-amd-amdhsa" ?
                    mapSPIRVAddrSpaceToAMDGPU(StorageClassGeneric) :
                    SPIRAS_Generic;
                Type *PtrTyAS = PointerType::get(PExpected->getType(), AddrSpc);
                Value *V = Builder.CreateAddrSpaceCast(
                    PExpected, PtrTyAS, PExpected->getName() + ".as");
                return std::make_pair(V, TypedPointerType::get(MemTy, AddrSpc));
              })
      .moveArg(4, 2)
      .changeReturnType(Type::getInt1Ty(*Ctx), [=](IRBuilder<> &Builder,
                                                   CallInst *NewCI) {
        // OCL built-ins atomic_compare_exchange_[strong|weak] return boolean
        // value. So, to obtain the same value as SPIR-V instruction is
        // returning it has to be loaded from the memory where 'expected'
        // value is stored. This memory must contain the needed value after a
        // call to OCL built-in is completed.
        return Builder.CreateLoad(MemTy, NewCI->getArgOperand(1), "original");
      });
}

void SPIRVToOCL20Base::visitCallSPIRVEnqueueKernel(CallInst *CI, Op OC) {
  bool HasVaargs = CI->arg_size() > 10;
  bool HasEvents = true;
  Value *EventRet = CI->getArgOperand(5);
  if (isa<ConstantPointerNull>(EventRet)) {
    Value *NumEvents = CI->getArgOperand(3);
    if (isa<ConstantInt>(NumEvents)) {
      ConstantInt *NE = cast<ConstantInt>(NumEvents);
      HasEvents = NE->getZExtValue() != 0;
    }
  }

  StringRef FName = "";
  if (!HasVaargs && !HasEvents)
    FName = "__enqueue_kernel_basic";
  else if (!HasVaargs && HasEvents)
    FName = "__enqueue_kernel_basic_events";
  else if (HasVaargs && !HasEvents)
    FName = "__enqueue_kernel_varargs";
  else
    FName = "__enqueue_kernel_events_varargs";

  auto Mutator = mutateCallInst(CI, FName.str());
  Mutator.mapArg(6, [=](IRBuilder<> &Builder, Value *Invoke) {
    unsigned AS = M->getTargetTriple() == "amdgcn-amd-amdhsa" ?
        mapSPIRVAddrSpaceToAMDGPU(StorageClassGeneric) : SPIRAS_Generic;
    Value *Replace = CastInst::CreatePointerBitCastOrAddrSpaceCast(
        Invoke, Builder.getPtrTy(AS), "", CI->getIterator());
    return std::make_pair(
        Replace, TypedPointerType::get(Builder.getInt8Ty(), AS));
  });

  if (!HasVaargs) {
    // Remove arguments at indices 8 (Param Size), 9 (Param Align)
    Mutator.removeArgs(8, 2);
  } else {
    // GEP to array of sizes of local arguments
    Mutator.moveArg(10, 8);
    Type *Int32Ty = Type::getInt32Ty(*Ctx);
    size_t NumLocalArgs = Mutator.arg_size() - 10;
    Mutator.insertArg(8, ConstantInt::get(Int32Ty, NumLocalArgs));

    // Mark all SPIRV-specific arguments as removed
    Mutator.removeArgs(10, Mutator.arg_size() - 10);
  }

  if (!HasEvents) {
    // Remove arguments at indices 3 (Num Events), 4 (Wait Events), 5 (Ret
    // Event).
    Mutator.removeArgs(3, 3);
  }
}

} // namespace SPIRV

INITIALIZE_PASS(SPIRVToOCL20Legacy, "spvtoocl20",
                "Translate SPIR-V builtins to OCL 2.0 builtins", false, false)

ModulePass *llvm::createSPIRVToOCL20Legacy() {
  return new SPIRVToOCL20Legacy();
}
