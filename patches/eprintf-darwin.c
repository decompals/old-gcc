/* Stub for __eprintf, removed from macOS SDKs after 10.14.
   Required by gcc-2.7.2-cdk's exception-handling code.  */
#include <stdio.h>
#include <stdlib.h>

void
__eprintf (const char *fmt, const char *file, unsigned line, const char *expr)
{
  fprintf (stderr, fmt, file, line, expr);
  abort ();
}
