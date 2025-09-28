# grpc installation on macOS

This document captures the steps needed to build the `grpc` R package on macOS and highlights a few platform-specific checks you can run if the build fails.

## Why the build currently fails

The `grpc` package links against the C gRPC API and expects the symbol `grpc_insecure_credentials_create()` to be available in the header `grpc/grpc_security.h`. Starting with gRPC **1.64.0** the upstream project removed this helper. Homebrew currently distributes gRPC **1.75.0**, which no longer exposes the symbol and causes compilation to fail with errors similar to:

```
client.cpp:60:7: error: use of undeclared identifier 'grpc_insecure_credentials_create'
```

The package still compiles on Linux environments that ship gRPC ≤ 1.63.0, which is why the build succeeds on Ubuntu but not on modern macOS machines.

## Quick diagnostic checklist

1. Clone this repository and run the diagnostic helper before attempting to install the package:

   ```sh
   Rscript inst/tools/grpc_diagnostics.R
   ```

   The script collects system information, `pkg-config` output, and inspects the gRPC headers that Homebrew installed. Pay close attention to the final section titled **Header inspection**. If the line `Symbol 'grpc_insecure_credentials_create' available: FALSE` appears, the installed gRPC distribution is too new for the current package sources.

2. (Optional) After the package is installed you can rerun the same checks inside R:

   ```r
   grpc::grpc_diagnostics()
   ```

## Installing a compatible gRPC toolchain

To build the package on macOS today you need a gRPC release **no newer than 1.63.0**. There are two common approaches:

### Using Homebrew with a pinned formula

Homebrew no longer ships older gRPC releases, but you can temporarily install a versioned formula maintained by the community. For example, the [gRPC tap provided by `osx-cross`](https://github.com/osx-cross/homebrew-grpc) still exposes 1.63.0:

```sh
brew tap osx-cross/grpc
brew install grpc@1.63
```

After the installation completes, make sure `pkg-config` can see the older release:

```sh
export PKG_CONFIG_PATH="/opt/homebrew/opt/grpc@1.63/lib/pkgconfig:$PKG_CONFIG_PATH"
export PATH="/opt/homebrew/opt/grpc@1.63/bin:$PATH"
```

You can verify that `pkg-config --modversion grpc` now returns `1.63.0`.

### Building gRPC from source

If you prefer to avoid third-party taps, build gRPC 1.63.0 from source:

```sh
export GRPC_VERSION=1.63.0
curl -L https://github.com/grpc/grpc/archive/refs/tags/v${GRPC_VERSION}.tar.gz | tar -xz
cd grpc-${GRPC_VERSION}
mkdir -p cmake/build
pushd cmake/build
cmake -DgRPC_INSTALL=ON \
      -DgRPC_BUILD_TESTS=OFF \
      -DCMAKE_INSTALL_PREFIX=$HOME/.local/grpc-${GRPC_VERSION} \
      ../..
make -j$(sysctl -n hw.ncpu)
make install
popd
```

Update your environment so that `pkg-config` finds the locally built release:

```sh
export PKG_CONFIG_PATH="$HOME/.local/grpc-${GRPC_VERSION}/lib/pkgconfig:$PKG_CONFIG_PATH"
export PATH="$HOME/.local/grpc-${GRPC_VERSION}/bin:$PATH"
```

## Installing the R package

Once the diagnostics report confirms that the symbol is present, install the R package from the repository root:

```sh
R CMD INSTALL --install-tests .
```

## Sharing diagnostic output

If you still encounter issues after pinning gRPC, attach the full output from `inst/tools/grpc_diagnostics.R` when filing an issue. The log captures all of the information that helps maintainers reproduce macOS-specific problems quickly.
