source ../scripts/adi_env.tcl
source $ad_hdl_dir/library/scripts/adi_ip_xilinx.tcl

adi_ip_create boxmuller
adi_ip_files boxmuller [list \
    "./src/bm_axis_gen.vhd" \
    "./src/boxmuller.vhd" \
    "./src/grng_16.vhd" \
    "./src/lzd.vhd" \
    "./src/output_remapper.vhd" \
    "./src/pp_fcn.vhd" \
    "./src/pp_fcn_rom_pkg.vhd" \
    "./src/sb_des.vhd" \
    "./src/shifter.vhd" \
    "./src/xoroshiro128plus.vhd" ]

# Override top module to be grng_16
set_property "top" "grng_16" [get_filesets sources_1]

adi_ip_properties_lite boxmuller

# adi_ip_ttcl boxmuller "boxmuller_constr.ttcl"

set_property display_name "Box-Muller GRNG" [ipx::current_core]
set_property description "Box-Muller GRNG" [ipx::current_core]

ipx::save_core [ipx::current_core]

