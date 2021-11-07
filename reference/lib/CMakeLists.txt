add_library(boxmuller xoroshiro128plus.c fxpnt.c fxpnt_piecewise_poly.c)
target_include_directories(boxmuller PUBLIC include)

