#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <stdbool.h>
#include <errno.h>
#include <string.h>

#include "vcd.h"

int main(int argc, char *argv[]) {
    if (argc == 1) {
        fprintf(stderr, "%s: Missing input file\n", argv[0]);
        fprintf(stderr, "Usage: %s <DUMP.VCD>\n", argv[0]);
        return EXIT_FAILURE;
    }

    vcd_t *vcd = vcd_open(argv[1]);
    if (vcd == NULL) {
        perror("Failed to open input file");
        return EXIT_FAILURE;
    }

    vcd_parse_header(vcd);

    puts("Signals:");
    for (int i = 0; i < vcd->signal_count; i++)
        printf(" * %s, width=%d, symbol=%c\n", vcd->signals[i].name, vcd->signals[i].width, vcd->signals[i].symbol);

    while (vcd_has_next(vcd)) {
        vcd_next(vcd);

        printf("t = %012ld ", vcd->time);
        for (int i = 0; i < vcd->signal_count; i++) {
            if (vcd->signals[i].valid)
                printf("%s=0x%016lx ", vcd->signals[i].name, vcd->signals[i].data);
            else
                printf("%s=0xXXXXXXXXXXXXXXXX\n", vcd->signals[i].name);
        }
        puts("");
    }
    

    vcd_close(vcd);
    
    return EXIT_SUCCESS;
}
