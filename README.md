# Old GCC

Run `VERSION=2.7.2.2 make` to build an old version of GCC.

Alternatively use one of the prebuild binaries available from the [Releases](https://github.com/decompals/old-gcc/releases) page.

**Windows:** `VERSION=2.8.1-psx PLATFORM=windows make` cross-compiles `cc1.exe` and `cpp.exe` for Windows
(32-bit MinGW-w64, in Docker on Linux) for 2.7.2-psx, 2.7.2-cdk and 2.8.1-psx. Only the compiler
proper and the preprocessor are built, not the `gcc` driver or `cc1plus`; decomp builds that run `cc1`
directly can use them without WSL. Their output is byte-identical to the Linux builds' (checked on
every C source of a PS1 decompilation, rood-reverse: 289 files per compiler).

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

**NOTE:** All the builds target the `mipsel` architecture. GCC 2.7.0 and above can be passed `-meb` to target big endian at runtime.
