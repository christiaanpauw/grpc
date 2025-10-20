# 0) Ensure ARM brew environment is active for *this* shell
eval "$(/opt/homebrew/bin/brew shellenv)"

# 1) Put ARM brew first; de-prioritize Intel path for this session
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/bin:/usr/bin:${PATH}"
# If /usr/local/bin is still earlier in PATH, push it to the end:
export PATH="${PATH//\/usr\/local\/bin:/}"
export PATH="${PATH%:/usr/local/bin}:${PATH#:}"

# 2) Use ARM pkg-config and expose ARM .pc files
brew install pkg-config grpc protobuf
export PKG_CONFIG_PATH="/opt/homebrew/lib/pkgconfig:/opt/homebrew/share/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"

# 3) Flush any command hashing and confirm the right binaries
hash -r
which -a pkg-config
file "$(which pkg-config)"               # should be /opt/homebrew/bin/pkg-config ... arm64
pkg-config --variable pc_path pkg-config

# 4) Confirm protoc and grpc plugin exist (from ARM brew)
which protoc
file "$(which protoc)"                   # expect /opt/homebrew/bin/protoc ... arm64
which grpc_cpp_plugin
file "$(which grpc_cpp_plugin)"          # expect /opt/homebrew/bin/grpc_cpp_plugin ... arm64

# 5) Check gRPC flags now resolve to /opt/homebrew (no /usr/local)
pkg-config --modversion grpc
pkg-config --cflags grpc
pkg-config --libs grpc
pkg-config --modversion grpc++
pkg-config --cflags grpc++
pkg-config --libs grpc++

# 6) Optional: verify library architecture
ls -1 /opt/homebrew/lib | grep -E '^libgrpc(\..*)?dylib$' || true
lipo -info /opt/homebrew/lib/libgrpc.dylib 2>/dev/null || true

