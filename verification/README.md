# Numerical model & Trace verification

This subproject implements a floating point model of the box-muller transformation, and processes vcds to compare the results with the hardware simulation.

### Overview

* `lib`: vcd processing code
* `main`: Contains all the business logic around box-muller. Links against `lib`

### Building

Make sure you have all dependencies installed - required are:

* A compiler (If you're on debian, install `build-essential`; on Arch `base-devel`).
* cmake

Then create a build directory and populate it using cmake:

```
$ mkdir -p build
$ cd build
$ cmake ..
```

Now, you may invoke the newly generated Makefile to build:

```
$ make
```

The main binary can be found at `main/verify_trace` in the build directory.

### Usage

For usage information run:

```
$ build/main/verify_trace
```

