#!/usr/bin/env bash
# Build the rscp compiler and run the test suite.
#   ./build.sh          debug build + tests
#   ./build.sh release  optimized binary in target/release/rscp
set -euo pipefail
cd "$(dirname "$0")"
if [ "${1:-}" = "release" ]; then
    cargo build --release
    echo "binary: $(pwd)/target/release/rscp"
else
    cargo build
    cargo test
    echo "binary: $(pwd)/target/debug/rscp"
fi
