#include <stdio.h>
#include <string.h>

typedef struct {
    const char *prefix;
} Greeter;

static void greet(const Greeter *g, const char *name) {
    printf("%s, %s!\n", g->prefix, name);
}

int main(void) {
    Greeter g = {.prefix = "Hello from C"};
    const char *names[] = {"Ada", "Grace", "Linus"};

    for (size_t i = 0; i < sizeof(names) / sizeof(names[0]); i++) {
        greet(&g, names[i]);
    }

    // Uncomment for diagnostics test:
    // printf("%d\n", "oops");

    return 0;
}
