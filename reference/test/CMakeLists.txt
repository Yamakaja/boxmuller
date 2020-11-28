find_package(Check REQUIRED)

include(CheckCSourceCompiles)
include(CheckCSourceRuns)
include(CheckFunctionExists)
include(CheckIncludeFile)
include(CheckIncludeFiles)
include(CheckLibraryExists)
include(CheckSymbolExists)
include(CheckTypeSize)

add_executable(fxpnt_simple_arithmetic fxpnt_simple_arithmetic.c)
target_link_libraries(fxpnt_simple_arithmetic boxmueller check)

add_test(NAME fxpnt_simple_arithmetic COMMAND fxpnt_simple_arithmetic WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/test)
