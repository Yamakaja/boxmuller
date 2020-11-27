add_library(boxmueller xoroshiro128plus.c fxpnt.c)
target_include_directories(boxmueller PUBLIC include)

