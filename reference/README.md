# Fixed Point Box-Muller Reference Implementation

This codebase aims to supply a bit-correct reference implementation of the
xoroshiro128plus and box-muller VHDL ip cores in the parent project.

### Overview

The project is split into three relevant directories:

* `lib`: Contains utilities like the xoroshiro128plus URNG, a `fxpnt_t` that allows for easier handling of fixed point arithmetic, and more.
* `test`: This directory is dedicated to unit tests that (attempt to) veryify correct behaviour of the components in `lib`. Links against `lib`.
* `main`: Contains all the business logic around box-muller. Also links against `lib`.

### Building

Make sure you have all dependencies installed - required are:

* A compiler (If you're on debian, install `build-essential`; on Arch `base-devel`).
* cmake
* libcheck: (Any semi-recent version should do)

Then create a build directory and populate it using cmake:

```
$ mkdir -p build
$ cd build
$ cmake ..
```

Now, you may invoke the newly generated Makefile to build, and possibly run some tests:

```
$ make
$ make test
```

The main binary can be found at `main/main` in the build directory.

### Starting the simulation

*Note: The seed is currently fixed in code -> Running multiple instances in parallel will yield identical results!*

Usage: `main <OUTPUT_FILE> <ITERATIONS>`

* The results will be written as a binary stream of IEEE-754 double-precision floating point values
* Each iteration produces a block of 1024 output values, i.e. to produce 1 Mi samples, run the simulation with 1024 iterations.

To evaluate the results, the output file can easily be parsed using e.g. numpy:

```
import numpy as np
import matplotlib.pyplot as plt
from scipy import stats

results = np.fromfile("/tmp/output.dat", dtype=np.float64)
x = np.linspace(-6, 6, 1024)

plt.plot(x, stats.norm.pdf(x))
plt.hist(results, density=True, bins=128)
# plt.yscale("log") # To get a better picture of the tails
plt.show()
```
