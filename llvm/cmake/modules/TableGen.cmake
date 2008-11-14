# LLVM_TARGET_DEFINITIONS must contain the name of the .td file to process.
# Extra parameters for `tblgen' may come after `ofn' parameter.
# Adds the name of the generated file to TABLEGEN_OUTPUT.

macro(tablegen ofn)
  file(GLOB all_tds "*.td")
  add_custom_command(OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${ofn}
    COMMAND ${LLVM_TABLEGEN} ${ARGN} -I ${CMAKE_CURRENT_SOURCE_DIR} -I ${LLVM_MAIN_SRC_DIR}/lib/Target -I ${LLVM_MAIN_INCLUDE_DIR} ${CMAKE_CURRENT_SOURCE_DIR}/${LLVM_TARGET_DEFINITIONS} -o ${ofn}
    DEPENDS tblgen ${all_tds}
    COMMENT "Building ${ofn}..."
    )
  set(TABLEGEN_OUTPUT ${TABLEGEN_OUTPUT} ${CMAKE_CURRENT_BINARY_DIR}/${ofn})
endmacro(tablegen)
