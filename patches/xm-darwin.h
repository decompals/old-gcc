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

#include "tm.h"
