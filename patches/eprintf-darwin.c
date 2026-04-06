/* Stub for __eprintf, removed from macOS SDKs after 10.14.
   Required by gcc-2.7.2-cdk's exception-handling code.  */
#include <stdio.h>
#include <stdlib.h>

/* weak: if another object (e.g. tree.o in cdk) also defines __eprintf,
   that strong definition takes precedence and no duplicate-symbol error occurs. */
__attribute__((weak)) void
__eprintf (const char *fmt, const char *file, unsigned line, const char *expr)
{
  fprintf (stderr, fmt, file, line, expr);
  abort ();
}
