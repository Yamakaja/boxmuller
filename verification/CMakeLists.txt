cmake_minimum_required(VERSION 3.10)

# set the project name
project(boxmuller-verification)

set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE Debug)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")

add_subdirectory(main)
add_subdirectory(lib)

