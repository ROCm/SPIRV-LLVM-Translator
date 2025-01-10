set(LLVM_LINK_COMPONENTS
  SPIRVAMDLib
  Analysis
  BitReader
  BitWriter
  Core
  Passes
  Support
  TargetParser
  TransformUtils
)

if(SPIRV_BACKEND_FOUND)
  list(APPEND LLVM_LINK_COMPONENTS "SPIRVCodeGen")
endif()

add_llvm_tool(amd-llvm-spirv
  llvm-spirv.cpp
  # llvm_setup_rpath messes with the rpath making llvm-spirv not executable from the build directory
  NO_INSTALL_RPATH
)

setup_host_tool(amd-llvm-spirv LLVM_SPIRV amd-llvm-spirv_exe amd-llvm-spirv_target)

if (LLVM_SPIRV_BUILD_EXTERNAL OR LLVM_LINK_LLVM_DYLIB)
  target_link_libraries(amd-llvm-spirv PRIVATE LLVMSPIRVAMDLib)
endif()

target_include_directories(amd-llvm-spirv
  PRIVATE
    ${LLVM_INCLUDE_DIRS}
    ${LLVM_SPIRV_INCLUDE_DIRS}
)

if(SPIRV_TOOLS_FOUND AND LLVM_SPIRV_ENABLE_LIBSPIRV_DIS)
  target_compile_definitions(llvm-spirv PRIVATE LLVM_SPIRV_HAVE_SPIRV_TOOLS=1)
  target_include_directories(llvm-spirv PRIVATE ${SPIRV_TOOLS_INCLUDE_DIRS})
  target_link_libraries(llvm-spirv PRIVATE ${SPIRV_TOOLS_LDFLAGS})
endif()
