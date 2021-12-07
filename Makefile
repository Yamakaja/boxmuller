LIBRARY_NAME = boxmuller

GENERIC_DEPS += ./src/boxmuller.vhd
GENERIC_DEPS += ./src/grng_16.vhd
GENERIC_DEPS += ./src/lzd.vhd
GENERIC_DEPS += ./src/output_remapper.vhd
GENERIC_DEPS += ./src/pp_fcn.vhd
GENERIC_DEPS += ./src/pp_fcn_rom_pkg.vhd
GENERIC_DEPS += ./src/sb_des.vhd
GENERIC_DEPS += ./src/shifter.vhd
GENERIC_DEPS += ./src/xoroshiro128plus.vhd

XILINX_DEPS += boxmuller_ip.tcl

include ../scripts/library.mk
