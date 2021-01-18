# This script can be used to create the boxmueller vivado project

set user $::env(USER)

# ADJUST THESE VALUES:
#
# Root of this git repository
set source_dir "/home/$user/fpga/vhdl/boxmueller"
# Vivado project location
set project_location "/home/$user/fpga/vivado/boxmueller"

# Create project
create_project boxmueller $project_location -part xczu28dr-ffvg1517-2-e
set_property board_part xilinx.com:zcu111:part0:1.2 [current_project]
set_property target_language VHDL [current_project]

# Add design files
set source_files {}
lappend source_files $source_dir/src/shifter.vhd
lappend source_files $source_dir/src/lzd.vhd
lappend source_files $source_dir/src/boxmueller.vhd
lappend source_files $source_dir/src/grng_16.vhd
lappend source_files $source_dir/src/pp_fcn_rom_pkg.vhd
lappend source_files $source_dir/src/bm_axis_gen.vhd
lappend source_files $source_dir/src/pp_fcn.vhd
lappend source_files $source_dir/src/sb_des.vhd
lappend source_files $source_dir/src/top.vhd
lappend source_files $source_dir/src/xoroshiro128plus.vhd
lappend source_files $source_dir/src/output_remapper.vhd
add_files -norecurse $source_files
update_compile_order -fileset sources_1

# Add testbench
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse $source_dir/src/testbench.vhd
set_property used_in_simulation false [get_files  $source_dir/src/top.vhd]
update_compile_order -fileset sim_1

# Add clock constraint
add_files -fileset constrs_1 -norecurse $source_dir/vivado/bm_clock.xdc

# Add multiplier IP
create_ip -name mult_gen -vendor xilinx.com -library ip -version 12.0 -module_name mult_23_23_24
set_property -dict [list CONFIG.Component_Name {mult_23_23_24} CONFIG.PortAWidth {23} CONFIG.PortBWidth {23} CONFIG.Multiplier_Construction {Use_Mults} CONFIG.Use_Custom_Output_Width {true} CONFIG.OutputWidthHigh {45} CONFIG.OutputWidthLow {22} CONFIG.PipeStages {4} CONFIG.ClockEnable {true}] [get_ips mult_23_23_24]
generate_target {instantiation_template} [get_files $project_location/boxmueller.srcs/sources_1/ip/mult_23_23_24/mult_23_23_24.xci]
update_compile_order -fileset sources_1
generate_target all [get_files  $project_location/boxmueller.srcs/sources_1/ip/mult_23_23_24/mult_23_23_24.xci]
catch { config_ip_cache -export [get_ips -all mult_23_23_24] }
export_ip_user_files -of_objects [get_files $project_location/boxmueller.srcs/sources_1/ip/mult_23_23_24/mult_23_23_24.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] $project_location/boxmueller.srcs/sources_1/ip/mult_23_23_24/mult_23_23_24.xci]
launch_runs mult_23_23_24_synth_1 -jobs 4
export_simulation -of_objects [get_files $project_location/boxmueller.srcs/sources_1/ip/mult_23_23_24/mult_23_23_24.xci] -directory $project_location/boxmueller.ip_user_files/sim_scripts -ip_user_files_dir $project_location/boxmueller.ip_user_files -ipstatic_source_dir $project_location/boxmueller.ip_user_files/ipstatic -lib_map_path [list {modelsim=$project_location/boxmueller.cache/compile_simlib/modelsim} {questa=$project_location/boxmueller.cache/compile_simlib/questa} {ies=$project_location/boxmueller.cache/compile_simlib/ies} {xcelium=$project_location/boxmueller.cache/compile_simlib/xcelium} {vcs=$project_location/boxmueller.cache/compile_simlib/vcs} {riviera=$project_location/boxmueller.cache/compile_simlib/riviera}] -use_ip_compiled_libs -force -quiet
