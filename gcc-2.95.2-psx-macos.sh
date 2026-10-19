#!/bin/bash
# Build gcc-2.95.2-psx natively on macOS (x86_64 and aarch64): see macos/build.sh
exec bash "$(dirname "$0")/macos/build.sh" 2.95.2
