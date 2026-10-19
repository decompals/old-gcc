# Old GCC

Run `VERSION=2.7.2.2 make` to build an old version of GCC.

Alternatively use one of the prebuild binaries available from the [Releases](https://github.com/decompals/old-gcc/releases) page.

**Currently supported versions:**
- GCC 2.5.7
- GCC 2.6.0
- GCC 2.6.3
- GCC 2.7.0
- GCC 2.7.1
- GCC 2.7.2
- GCC 2.7.2.1
- GCC 2.7.2.2
- GCC 2.7.2.3
- GCC 2.8.0
- GCC 2.8.1
- GCC 2.91.60
- GCC 2.91.66
- GCC 2.95.22

**macOS:** `VERSION=2.8.1-psx PLATFORM=macos make` builds natively (x86_64 and arm64). Supported: 2.7.2-psx, 2.7.2-cdk, 2.8.1-psx, 2.6.0-psx, 2.6.3-psx, 2.8.0-psx, 2.91.66-psx and 2.95.2-psx. The last five share `macos/build.sh`; see the comments there and in `macos/` for the arm64 fixes (variadic arguments, `CONST_DOUBLE` copies). `BUILD_ARCH=x86_64` makes an Intel build on an Apple Silicon Mac (it runs under Rosetta).

**NOTE:** All the builds target the `mipsel` architecture. GCC 2.7.0 and above can be passed `-meb` to target big endian at runtime.
