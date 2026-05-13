/* Host machine description for GCC running on macOS (Darwin).
   Works for both x86_64 and aarch64 (Apple Silicon).

   macOS uses the LP64 model: int is 32-bit, long and pointers are 64-bit.  */

#define HOST_BITS_PER_CHAR    8
#define HOST_BITS_PER_SHORT  16
#define HOST_BITS_PER_INT    32
#define HOST_BITS_PER_LONG   64
#define HOST_BITS_PER_LONGLONG 64

#define FALSE 0
#define TRUE  1

#define SUCCESS_EXIT_CODE 0
#define FATAL_EXIT_CODE 33

#define HAVE_VPRINTF
#define HAVE_STRERROR
#define POSIX

/* macOS provides bcopy/bcmp/bzero via <string.h>.  */
#define BSTRING

/* Force 32-bit HOST_WIDE_INT to match the Linux i386 -m32 reference build.
   Without this override, machmode.h derives HOST_WIDE_INT from `long`
   (64-bit on darwin LP64), which changes cc1's internal integer-constant
   arithmetic (constant folding, RTL constants, shift/sign-extend) vs the
   reference Linux build. The result is non-bit-identical machine code for
   the same input C — verified against rood-reverse where this caused 8
   PRGs to fail `make check`.

   cc1 remains a 64-bit Mach-O binary; only the target-constant width is
   constrained, mirroring what the i386-host Linux cc1 does.  */
#define HOST_BITS_PER_WIDE_INT 32
#define HOST_WIDE_INT int

#include "tm.h"
