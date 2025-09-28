# grpc installation on macOS

This document captures the steps needed to build the `grpc` R package on macOS and highlights a few platform-specific checks you can run if the build fails.

## Background

Recent gRPC releases reorganised the public C headers. The helpers for creating insecure credentials – `grpc_insecure_credentials_create()` and `grpc_insecure_server_credentials_create()` – now live in `grpc/credentials.h` instead of `grpc/grpc_security.h`. Older versions of this package expected the declarations in the original header, which resulted in compiler errors such as:

```
client.cpp:60:7: error: use of undeclared identifier 'grpc_insecure_credentials_create'
```

The package now conditionally includes both headers so that it builds against Homebrew's up-to-date formulae. The diagnostic scripts below remain useful to confirm that your include paths expose the required declarations.

## Quick diagnostic checklist

1. Clone this repository and run the diagnostic helper before attempting to install the package:

   ```sh
   Rscript inst/tools/grpc_diagnostics.R
   ```

   The script collects system information, `pkg-config` output, and inspects the gRPC headers that Homebrew installed. Pay close attention to the final section titled **Header inspection**. The helper now probes both `grpc/grpc_security.h` and `grpc/credentials.h`; at least one of them should report `has grpc_insecure_credentials_create: TRUE`.

2. (Optional) After the package is installed you can rerun the same checks inside R:

   ```r
   grpc::grpc_diagnostics()
   ```

## Ensuring `pkg-config` can discover gRPC

If the diagnostics indicate that neither header exposes `grpc_insecure_credentials_create`, double-check that `pkg-config` resolves Homebrew's installation prefix. For Apple silicon machines the default prefix is `/opt/homebrew`:

```sh
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:$PKG_CONFIG_PATH"
export PATH="/opt/homebrew/bin:$PATH"
```

Adjust the paths if you are using an Intel machine (`/usr/local`) or a custom installation prefix. After updating the environment you can verify the configuration with `pkg-config --modversion grpc`.

## Installing the R package

Once the diagnostics report confirms that the symbol is present in one of the inspected headers, install the R package from the repository root:

```sh
R CMD INSTALL --install-tests .
```

## Sharing diagnostic output

If you still encounter issues after configuring your environment, attach the full output from `inst/tools/grpc_diagnostics.R` when filing an issue. The log captures all of the information that helps maintainers reproduce macOS-specific problems quickly.
