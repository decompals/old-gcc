typedef struct {
    unsigned int field;
} Foo;

unsigned char bar(Foo* foo) {
    return foo->field;
}
