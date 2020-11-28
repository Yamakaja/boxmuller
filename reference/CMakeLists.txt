cmake_minimum_required(VERSION 3.10)

# set the project name
project(boxmueller)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")

list(APPEND CMAKE_CTEST_ARGUMENTS "--output-on-failure")

add_subdirectory(lib)
add_subdirectory(main)

enable_testing()
add_subdirectory(test)

