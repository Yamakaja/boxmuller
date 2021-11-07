# Boxmuller

A gaussian random number generator based on the Box-Muller transform.

### Project Structure

* `reference/`: Originally a bit-accurate reference implementation of the boxmuller GRNG core. Note: The VHDL implementation has diverged from this reference, and comes with lots of optimizations that are not covered here. Nonetheless, this project should give you a good idea of what's going on.
* `verification/`: Used to verify simulation VCDs of a boxmuller core
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
set source_dir "/home/$user/fpga/vhdl/boxmuller"
# Vivado project location
set project_location "/home/$user/fpga/vivado/boxmuller"
```

Open the Vivado quickstart screen and source the tcl script.

```
source $boxmuller/vivado/create_project.tcl
```

The project can now be simulated, synthesized and implemented. Currently only behavioural simulation is tested.

## Verifying simulation results

```
cd $boxmuller/verification
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
main/verify_trace $vivado_project_dir/boxmuller.sim/sim_1/behav/xsim/dump.vcd | sort -rn | head
```

The first column is the interesting one - it is the absolute difference beetween the hardware result and a 64-bit floating point calculation.

The maximum error over the entire duration of the simulation will be the first line, and if everything went to plan, it should be less than 2^-10:

```
 0.00067 x_0=( 2.17743 |  2.17676) x_1=( 0.20456 |  0.20410) t=  2020690000 r_i_u_0=0x000013c5e6ea2661 r_i_u_1=0x0000000000003c2f r_i_u_2=0x000000003b5efd17

```

## Results / Utilization

Because the core is highly pipelined and data dependencies are rather linear, clock rates of 666 MHz and beyond can be realized on a modern Zynq UltraScale+ -1E (speed grade).

A utilization report for 16 output values, implemented on a XCZU28DR: (These numbers include the required uniform random number generators at the input)

```
1. CLB Logic
------------

+----------------------------+------+-------+-----------+-------+
|          Site Type         | Used | Fixed | Available | Util% |
+----------------------------+------+-------+-----------+-------+
| CLB LUTs                   | 6058 |     0 |    425280 |  1.42 |
|   LUT as Logic             | 5570 |     0 |    425280 |  1.31 |
|   LUT as Memory            |  488 |     0 |    213600 |  0.23 |
|     LUT as Distributed RAM |    0 |     0 |           |       |
|     LUT as Shift Register  |  488 |     0 |           |       |
| CLB Registers              | 8106 |     0 |    850560 |  0.95 |
|   Register as Flip Flop    | 8106 |     0 |    850560 |  0.95 |
|   Register as Latch        |    0 |     0 |    850560 |  0.00 |
| CARRY8                     |  176 |     0 |     53160 |  0.33 |
| F7 Muxes                   |    0 |     0 |    212640 |  0.00 |
| F8 Muxes                   |    0 |     0 |    106320 |  0.00 |
| F9 Muxes                   |    0 |     0 |     53160 |  0.00 |
+----------------------------+------+-------+-----------+-------+


3. BLOCKRAM
-----------

+-------------------+------+-------+-----------+-------+
|     Site Type     | Used | Fixed | Available | Util% |
+-------------------+------+-------+-----------+-------+
| Block RAM Tile    |   20 |     0 |      1080 |  1.85 |
|   RAMB36/FIFO*    |   16 |     0 |      1080 |  1.48 |
|     RAMB36E2 only |   16 |       |           |       |
|   RAMB18          |    8 |     0 |      2160 |  0.37 |
|     RAMB18E2 only |    8 |       |           |       |
| URAM              |    0 |     0 |        80 |  0.00 |
+-------------------+------+-------+-----------+-------+
* Note: Each Block RAM Tile only has one FIFO logic available and therefore can accommodate only one FIFO36E2 or one FIFO18E2. However, if a FIFO18E2 occupies a Block RAM Tile, that tile can still accommodate a RAMB18E2


4. ARITHMETIC
-------------

+----------------+------+-------+-----------+-------+
|    Site Type   | Used | Fixed | Available | Util% |
+----------------+------+-------+-----------+-------+
| DSPs           |   88 |     0 |      4272 |  2.06 |
|   DSP48E2 only |   88 |       |           |       |
+----------------+------+-------+-----------+-------+

```


