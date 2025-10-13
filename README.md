# grpc

An **R** library for [**GRPC**](https://grpc.io/) a high-performance, open-source universal RPC framework.

## Installation - Debian

### Pre-requisites

The R package links against the upstream gRPC C core libraries.  On
recent Ubuntu releases the required toolchain can be installed from the
distribution packages without building gRPC manually:

```shell
sudo apt-get update
sudo apt-get install -y \
  build-essential autoconf libtool pkg-config cmake \
  libgflags-dev libgtest-dev clang libc++-dev \
  libgrpc++-dev libgrpc-dev protobuf-compiler-grpc
```

The package also depends on `gpr`, the gRPC support runtime.  Recent
versions of the upstream `grpc` package no longer link this library
automatically on some platforms (notably macOS), which results in
runtime errors such as:

```
Error: package or namespace load failed for ‘grpc’ in dyn.load(...):
 unable to load shared object '.../grpc/libs/grpc.so':
  dlopen(.../grpc.so, 0x0006): symbol not found in flat namespace '_gpr_convert_clock_type'
```

The build system now links `libgpr` explicitly, so the symbol is
resolved when the package is loaded.  When using other operating
systems ensure that gRPC and the accompanying support libraries are
available through `pkg-config`.

### Optional: build gRPC from source

If distribution packages are unavailable, the following steps mirror
the upstream instructions for building gRPC manually:

```shell
export GRPC_INSTALL_DIR=$HOME/.local
mkdir -p $GRPC_INSTALL_DIR
export PATH="$GRPC_INSTALL_DIR/bin:$PATH"

sudo apt install -y cmake

LATEST_VER=$(curl -L "https://api.github.com/repos/grpc/grpc/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
git clone --recurse-submodules -b $LATEST_VER https://github.com/grpc/grpc grpc_base

cd grpc_base
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      ../..
make -j4
sudo make install
popd

mkdir -p third_party/abseil-cpp/cmake/build
pushd third_party/abseil-cpp/cmake/build
cmake -DCMAKE_INSTALL_PREFIX=$GRPC_INSTALL_DIR \
      -DCMAKE_POSITION_INDEPENDENT_CODE=TRUE \
      ../..
make -j4
sudo make install
popd
```

## Installation - macOS

The package also builds cleanly on macOS when Homebrew's gRPC formulae
are available. The `readmeMac.md` document contains a detailed
walkthrough; the summary below highlights the recommended steps.

1. From the repository root run the diagnostic helper to ensure that
   `pkg-config` can locate the gRPC headers and libraries:

   ```sh
   Rscript inst/tools/grpc_diagnostics.R
   ```

   Review the **Header inspection** section of the report – at least one
   of `grpc/grpc_security.h` or `grpc/credentials.h` should expose
   `grpc_insecure_credentials_create`.

2. If the helper cannot locate gRPC, update your environment so that
   `pkg-config` resolves Homebrew's installation prefix. On Apple Silicon
   machines this usually means:

   ```sh
   export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
   export PATH="/opt/homebrew/bin:$PATH"
   ```

   Intel machines using the default prefix should switch `/opt/homebrew`
   for `/usr/local`.

3. Install the package once the diagnostics succeed:

   ```sh
   R CMD INSTALL --install-tests .
   ```

You can rerun the diagnostics inside R with `grpc::grpc_diagnostics()`
if you need to capture the output for an issue report.

# Original

[![Build Status](https://travis-ci.org/nfultz/grpc.svg)](https://travis-ci.org/nfultz/grpc)

Easily create [gRPC](https://github.com/grpc/grpc) clients and servers from protobuf descriptions to build distributed services. 

Copyright 2015 Google Inc, 2017 Neal Fultz


## Dependencies

  * grpc
  * protobuf
  * RProtoBuf

See `install` for my installation notes...


## Examples

There are runnable examples in the `demo/` folder.

### Hello, World!

To start a HelloWorld server:

    R -e 'demo("helloserver", "grpc")'

Or with much more detailed logging:
  
    R -e 'library(futile.logger); flog.threshold(TRACE); demo("helloserver", "grpc")'

To run a client against a running HelloWorld server:
  
    R -e 'demo("helloclient", "grpc")'

Both are cross compatible with the Node, Python and C++ Greeter examples provided by the grpc library.

### Running package self-checks

After installing the system dependencies and building the package you can
confirm that the shared library links correctly by running:

```shell
R -q -e 'library(grpc); grpc_version()'
```

This will print the detected gRPC runtime version and ensures that the
`_gpr_convert_clock_type` symbol is resolved.

### Health check

This server implements the above service along with the standard [GRPC Health Checking Protocol](https://github.com/grpc/grpc/blob/master/doc/health-checking.md):

    R -e 'demo("health-check-server", "grpc")'

The client runs a health-check then calls the Hello, World! method once:

    R -e 'demo("health-check-client", "grpc")'

Please check the sources of the server to see how to bundle services defined in multiple `proto` files.

### Live scoring

There's a simple trained on the `iris` dataset and making that available for scoring via a gRPC service:

    R -e 'demo("iris-server", "grpc")'

An example client to this service from R:

    R -e 'demo("iris-client", "grpc")'

## Todo

  * Streaming services
  * Authentication and Encryption
  * Error handling
  * Docs
  
## Contributing
