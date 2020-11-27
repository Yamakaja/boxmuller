#include <stdio.h>
#include <stdint.h>

#include "xoroshiro128plus.h"
#include "fxpnt.h"

int main(void) {
    xoroshiro128plus_t xoro;
    xoroshiro128plus_init(&xoro, 0xcafebabe8badbeef);

    printf("Seeds: (0x%016lx, 0x%016lx)\n", xoro.s[1], xoro.s[0]);

    for (int i = 0; i < 10; i++)
        printf("0x%016lx\n", xoroshiro128plus_next(&xoro));
    
    fxpnt_cfg_t cfg = fxpnt_cfg(8, 16);
    
    return 0;
}
