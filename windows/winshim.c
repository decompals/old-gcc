/* Old BSD string functions GCC 2.x expects, for a MinGW (Windows) host */
#include <string.h>
char *index(const char *s, int c) { return strchr(s, c); }
char *rindex(const char *s, int c) { return strrchr(s, c); }
int bcmp(const void *a, const void *b, size_t n) { return memcmp(a, b, n); }
void bcopy(const void *src, void *dst, size_t n) { memmove(dst, src, n); }
void bzero(void *s, size_t n) { memset(s, 0, n); }

/* Unix line endings on stdout (the assembler input) and no CR/LF translation on stdin, as on Linux */
#include <fcntl.h>
#include <io.h>
#include <stdio.h>
__attribute__((constructor)) static void binary_stdio(void)
{
    _setmode(_fileno(stdin), _O_BINARY);
    _setmode(_fileno(stdout), _O_BINARY);
}

/* Old GCC's own assert.h calls __eprintf, which libgcc no longer has */
#include <stdlib.h>
void __eprintf(const char *string, const char *expression, unsigned int line, const char *filename)
{
    fprintf(stderr, string, expression, line, filename);
    fflush(stderr);
    abort();
}
