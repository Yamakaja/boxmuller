# Boxmueller

A gaussian random number generator based on the Box-Mueller transform. 

### Project Structure

* `reference/`: Originally a bit-accurate reference implementation of the boxmueller GRNG core. Note: The VHDL implementation has diverged from this reference, and comes with lots of optimizations that are not covered here. Nonetheless, this project should give you a good idea of what's going on.
* `verification/`: Used to verify simulation VCDs of a boxmueller core
* `src/`: All VHDL source files
* `vivado/`: Vivado TCL scripts to configure the project
* `docs/`: Run `doxygen` to generate code documentation. This directory is not tracked by git

## Building the core

Note: This project was created using version 2020.1 - compatibility with older versions has not yet been verified.

Configure `vivado/create_project.tcl` to suit your needs:

```
# ADJUST THESE VALUES:
#
# Root of this git repository
set source_dir "/home/$user/fpga/vhdl/boxmueller"
# Vivado project location
set project_location "/home/$user/fpga/vivado/boxmueller"
```

Open the Vivado quickstart screen and source the tcl script.

```
source $boxmueller/vivado/create_project.tcl
```

The project can now be simulated, synthesized and implemented. Currently only behavioural simulation is tested.

## Verifying simulation results

```
cd $boxmueller/verification
# Create a build directory
mkdir build
cd build
cmake ..
make
```

Start the simulation and save the results:

Vivado TCL console:

```
launch_simulation
restart
open_vcd
log_vcd [get_objects /testbench/bm/r_i_* /testbench/t_x_*]
run 5 ms
close_vcd
```

In the verification build directory:
```
main/verify_trace $vivado_project_dir/boxmueller.sim/sim_1/behav/xsim/dump.vcd | sort -rn | head
```

The first column is the interesting one - it is the absolute difference beetween the hardware result and a 64-bit floating point calculation.

The maximum error over the entire duration of the simulation will be the first line, and if everything went to plan, it should be less than 2^-10:

```
 0.00067 x_0=( 2.17743 |  2.17676) x_1=( 0.20456 |  0.20410) t=  2020690000 r_i_u_0=0x000013c5e6ea2661 r_i_u_1=0x0000000000003c2f r_i_u_2=0x000000003b5efd17

```
