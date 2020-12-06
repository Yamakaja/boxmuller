add_library(boxmueller xoroshiro128plus.c fxpnt.c fxpnt_piecewise_poly.c)
target_include_directories(boxmueller PUBLIC include)

